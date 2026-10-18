const CATALOG = "https://raw.githubusercontent.com/4uJIuH/umbrella-scripts/main/.github/catalog.json";
const STEAM_ID = /^\d{15,20}$/;
const RATINGS_TTL = 30;
const CATALOG_TTL = 3600;
const HOUR = 3600;
const PER_SCRIPT = 2;
const SCRIPTS_PER_HOUR = 5;
const PER_IP = 20;
const TEXT_MIN = 10;
const TEXT_MAX = 1000;
const STEAM_BASE = 76561197960265728n;
const KINDS = {
  improve: { label: "Предложение по улучшению", color: 0x4c82f7, icon: "🛠️" },
  idea: { label: "Идея", color: 0xf5b942, icon: "💡" },
  bug: { label: "Ошибка", color: 0xff5c52, icon: "🐞" },
  other: { label: "Другое", color: 0x9a9aa0, icon: "💬" },
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...CORS, ...extra },
  });
}

async function cached(ctx, url, ttl, load) {
  const key = new Request(url);
  const hit = await caches.default.match(key);
  if (hit) return hit.json();
  const value = await load();
  const res = new Response(JSON.stringify(value), {
    headers: { "Content-Type": "application/json", "Cache-Control": "public, max-age=" + ttl },
  });
  ctx.waitUntil(caches.default.put(key, res));
  return value;
}

async function scriptTitles(ctx) {
  return cached(ctx, "https://cache.local/catalog-titles", CATALOG_TTL, async () => {
    const res = await fetch(CATALOG);
    if (!res.ok) throw new Error("catalog " + res.status);
    const data = await res.json();
    const out = {};
    for (const s of data.scripts) out[s.id] = s.title || s.id;
    return out;
  });
}

async function knownScripts(ctx) {
  return new Set(Object.keys(await scriptTitles(ctx)));
}

async function totals(env, ctx) {
  return cached(ctx, "https://cache.local/ratings", RATINGS_TTL, async () => {
    const { results } = await env.DB.prepare(
      "SELECT script_id, SUM(vote = 1) AS up, SUM(vote = -1) AS down FROM votes GROUP BY script_id"
    ).all();
    const out = {};
    for (const r of results) out[r.script_id] = { up: r.up, down: r.down };
    return out;
  });
}

async function mine(env, user) {
  const { results } = await env.DB.prepare("SELECT script_id, vote FROM votes WHERE steam_id = ?").bind(user).all();
  const out = {};
  for (const r of results) out[r.script_id] = r.vote;
  return out;
}

async function handleGet(request, env, ctx) {
  const user = new URL(request.url).searchParams.get("user");
  const body = { ratings: await totals(env, ctx) };
  if (user) {
    if (!STEAM_ID.test(user)) return json({ error: "bad user" }, 400);
    body.mine = await mine(env, user);
  }
  return json(body);
}

async function handleVote(request, env, ctx) {
  let data;
  try {
    data = await request.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }
  const { script, user, vote } = data || {};
  if (typeof user !== "string" || !STEAM_ID.test(user)) return json({ error: "bad user" }, 400);
  if (![-1, 0, 1].includes(vote)) return json({ error: "bad vote" }, 400);
  if (typeof script !== "string" || !(await knownScripts(ctx)).has(script)) return json({ error: "unknown script" }, 404);

  if (vote === 0) {
    await env.DB.prepare("DELETE FROM votes WHERE steam_id = ? AND script_id = ?").bind(user, script).run();
  } else {
    await env.DB.prepare(
      "INSERT INTO votes (steam_id, script_id, vote, updated) VALUES (?1, ?2, ?3, ?4) " +
        "ON CONFLICT (steam_id, script_id) DO UPDATE SET vote = excluded.vote, updated = excluded.updated"
    ).bind(user, script, vote, Math.floor(Date.now() / 1000)).run();
  }

  const row = await env.DB.prepare(
    "SELECT SUM(vote = 1) AS up, SUM(vote = -1) AS down FROM votes WHERE script_id = ?"
  ).bind(script).first();
  await caches.default.delete(new Request("https://cache.local/ratings"));
  return json({ script, up: row.up || 0, down: row.down || 0, mine: vote });
}

// what the last hour of one account allows: 2 messages per script, at most 5 different scripts
function limits(rows, now) {
  const scripts = {};
  for (const r of rows) (scripts[r.script_id] ||= []).push(r.created);
  const out = { scripts: {}, used: 0, wait: 0 };
  let slot = Infinity;
  for (const [id, times] of Object.entries(scripts)) {
    times.sort((a, b) => a - b);
    const wait = times.length >= PER_SCRIPT ? times[times.length - PER_SCRIPT] + HOUR - now : 0;
    out.scripts[id] = { count: times.length, wait: Math.max(0, wait) };
    slot = Math.min(slot, times[times.length - 1] + HOUR - now);
  }
  out.used = Object.keys(scripts).length;
  if (out.used >= SCRIPTS_PER_HOUR) out.wait = Math.max(0, slot);
  return out;
}

function blocked(lim, script) {
  const mine = lim.scripts[script];
  if (mine && mine.wait > 0) return { error: "script_limit", wait: mine.wait };
  if (!mine && lim.used >= SCRIPTS_PER_HOUR) return { error: "scripts_limit", wait: lim.wait };
  return null;
}

async function recent(env, user, now) {
  const { results } = await env.DB.prepare("SELECT script_id, created FROM feedback WHERE steam_id = ? AND created > ?")
    .bind(user, now - HOUR).all();
  return results;
}

// the IP is only kept as a salted hash, enough to count messages from one address
async function ipHash(request) {
  const ip = request.headers.get("CF-Connecting-IP") || "";
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode("umbrella-feedback:" + ip));
  return [...new Uint8Array(digest)].slice(0, 12).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function profile(account) {
  try {
    const res = await fetch("https://api.opendota.com/api/players/" + account, { signal: AbortSignal.timeout(4000) });
    if (!res.ok) return null;
    const data = await res.json();
    return data && data.profile ? data.profile : null;
  } catch {
    return null;
  }
}

function clip(value, max) {
  return typeof value === "string" ? value.replace(/[\u0000-\u0009\u000b-\u001f]/g, "").trim().slice(0, max) : "";
}

async function handleFeedbackGet(request, env) {
  const user = new URL(request.url).searchParams.get("user");
  if (!user || !STEAM_ID.test(user)) return json({ error: "bad user" }, 400);
  const now = Math.floor(Date.now() / 1000);
  return json(limits(await recent(env, user, now), now));
}

async function handleFeedback(request, env, ctx) {
  if (!env.DISCORD_WEBHOOK) return json({ error: "disabled" }, 503);
  let data;
  try {
    data = await request.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }
  const { script, user, kind } = data || {};
  if (typeof user !== "string" || !STEAM_ID.test(user)) return json({ error: "bad user" }, 400);
  if (!KINDS[kind]) return json({ error: "bad kind" }, 400);
  const text = clip(data.text, TEXT_MAX * 2);
  const length = [...text].length;
  if (length < TEXT_MIN || length > TEXT_MAX) return json({ error: "bad text" }, 400);
  const titles = await scriptTitles(ctx);
  if (typeof script !== "string" || !titles[script]) return json({ error: "unknown script" }, 404);

  const now = Math.floor(Date.now() / 1000);
  const ip = await ipHash(request);
  const lim = limits(await recent(env, user, now), now);
  const stop = blocked(lim, script);
  if (stop) return json({ ...stop, limits: lim }, 429);
  const byIp = (await env.DB.prepare("SELECT created FROM feedback WHERE ip = ? AND created > ? ORDER BY created")
    .bind(ip, now - HOUR).all()).results;
  if (byIp.length >= PER_IP) {
    return json({ error: "ip_limit", wait: byIp[byIp.length - PER_IP].created + HOUR - now, limits: lim }, 429);
  }

  const account = (BigInt(user) - STEAM_BASE).toString();
  const prof = await profile(account);
  const name = (prof && prof.personaname) || clip(data.name, 64) || "Account " + account;
  const version = clip(data.version, 32);
  const manager = clip(data.manager, 32);
  const k = KINDS[kind];
  const links = [
    `[OpenDota](https://www.opendota.com/players/${account})`,
    `[Dotabuff](https://ru.dotabuff.com/players/${account})`,
    `[Steam](https://steamcommunity.com/profiles/${user})`,
  ].join(" · ");
  const embed = {
    author: {
      name,
      url: `https://www.opendota.com/players/${account}`,
      ...(prof && prof.avatarfull ? { icon_url: prof.avatarfull } : {}),
    },
    title: `${k.icon} ${k.label} · ${titles[script]}`,
    description: text,
    color: k.color,
    fields: [
      { name: "Тип", value: k.icon + " " + k.label, inline: true },
      { name: "Скрипт", value: titles[script] + (version ? " v" + version : ""), inline: true },
      { name: "Аккаунт", value: "`" + account + "`", inline: true },
      { name: "Время", value: `<t:${now}:F> (<t:${now}:R>)`, inline: true },
      { name: "Профиль", value: links },
    ],
    timestamp: new Date(now * 1000).toISOString(),
    ...(manager ? { footer: { text: "Script Manager v" + manager } } : {}),
  };
  const sent = await fetch(env.DISCORD_WEBHOOK + "?wait=true", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username: "Umbrella Feedback", allowed_mentions: { parse: [] }, embeds: [embed] }),
  });
  if (!sent.ok) return json({ error: "discord", status: sent.status }, 502);

  await env.DB.prepare("INSERT INTO feedback (steam_id, script_id, ip, created) VALUES (?, ?, ?, ?)")
    .bind(user, script, ip, now).run();
  return json({ ok: true, limits: limits(await recent(env, user, now), now) });
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    const path = new URL(request.url).pathname;
    try {
      if (request.method === "GET" && path === "/ratings") return await handleGet(request, env, ctx);
      if (request.method === "POST" && path === "/vote") return await handleVote(request, env, ctx);
      if (request.method === "GET" && path === "/feedback") return await handleFeedbackGet(request, env);
      if (request.method === "POST" && path === "/feedback") return await handleFeedback(request, env, ctx);
      return json({ error: "not found" }, 404);
    } catch (e) {
      return json({ error: "server" }, 500);
    }
  },
};
