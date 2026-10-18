# umbrella-ratings

Cloudflare Worker + D1 for the 👍/👎 script ratings and the feedback form of Script Manager. One vote per Steam ID per script; pressing the other thumb switches the vote, pressing the same one removes it.

## Deploy

```
cd worker
npm i -g wrangler
wrangler login
wrangler d1 create umbrella-ratings
```

Put the printed `database_id` into `wrangler.toml`, then:

```
wrangler d1 execute umbrella-ratings --remote --file=schema.sql
wrangler deploy
```

Feedback goes to a Discord channel through a webhook (channel settings → Integrations → Webhooks → New Webhook → Copy Webhook URL). The URL is a secret, keep it out of the repository:

```
wrangler secret put DISCORD_WEBHOOK
```

While the secret is missing `POST /feedback` answers 503.

Set the printed `https://umbrella-ratings.<account>.workers.dev` as `ratings_url` in `.github/catalog.json` and push. The site and Script Manager read the address from there; while it is empty the ratings are hidden.

## API

- `GET /ratings[?user=<steamid>]` returns `{ratings: {id: {up, down}}, mine: {id: 1|-1}}` (`mine` only with `user`).
- `POST /vote` with `{script, user, vote}` where vote is `1`, `-1` or `0` returns the new `{up, down, mine}` for that script.
- `GET /feedback?user=<steamid>` returns the limits of the last hour: `{scripts: {id: {count, wait}}, used, wait}`; `wait` is seconds until the next message is allowed.
- `POST /feedback` with `{script, user, kind, text, version, manager, name}` posts the message to Discord. `kind` is `improve`, `idea`, `bug` or `other`, `text` is 10–1000 characters. One account sends 2 messages per script and messages to 5 different scripts per hour, one IP 20 messages per hour; past that the answer is 429 `{error: "script_limit" | "scripts_limit" | "ip_limit", wait}`.
