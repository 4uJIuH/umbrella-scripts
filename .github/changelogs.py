"""Changelogs for every script, so Script Manager can show the history of each one.

Scripts kept in this repository get CHANGELOG.md / CHANGELOG.en.md once, built from
their releases here; after that the files are edited by hand like any other changelog.
Scripts from another author's repository link to that author's changelog files
("changelog_url" in catalog.json); when the author keeps none, the files here are
rebuilt from the author's release notes on every run.
"""
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
GH = BASE / ".github"
CATALOG = json.loads((GH / "catalog.json").read_text(encoding="utf-8"))
REPO = CATALOG["repo"]
NL = chr(10)
VERSION = re.compile(r"\d+(?:\.\d+)+(?:[-.][0-9A-Za-z]+)*|\d+")
SKIP_SECTION = re.compile(
    r"install|установ|compatib|совместим|what to test|testing|download|скача|how to use|usage|requirements|требован",
    re.I,
)
INSTALL = re.compile(r"(?i)(put|drop|download|place|unzip|copy|поместите|положите|скачайте|закиньте|распакуйте|скопируйте)\b")
TEXT = {
    "ru": {
        "release": "Релиз v%s",
        "update": "Обновление v%s",
        "first": "Релизная версия: первая публикация скрипта.",
        "silent": "Автор не описал изменения в этой версии.",
    },
    "en": {
        "release": "Release v%s",
        "update": "Update v%s",
        "first": "Release version: the first publication of the script.",
        "silent": "The author did not describe the changes in this version.",
    },
}


def api(url):
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("api %s: HTTP %d" % (url, e.code))
        return None


def releases(repo):
    out, page = [], 1
    while True:
        data = api("https://api.github.com/repos/%s/releases?per_page=100&page=%d" % (repo, page))
        if not data:
            return out
        out += [r for r in data if not r.get("draft")]
        if len(data) < 100:
            return out
        page += 1


def source_repo(script):
    m = re.match(r"https://github\.com/([^/]+/[^/]+)", script.get("source_url") or "")
    return m.group(1) if m and m.group(1).lower() != REPO.lower() else None


def version_key(version):
    return [int(p) if p.isdigit() else -1 for p in re.split(r"[.-]", version)]


def version_of(release, prefix):
    tag = release.get("tag_name") or ""
    if prefix and tag.startswith(prefix):
        tag = tag[len(prefix):]
    for text in (tag, release.get("name") or ""):
        m = VERSION.search(text)
        if m:
            return m.group(0)
    return tag or None


def clean(line):
    line = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", line)
    line = line.replace("**", "").replace("`", "").strip()
    return re.sub(r"\s+", " ", line)


def notes(body, script):
    """Change lines of a release body: no install steps, test plans, code or the catalog boilerplate."""
    skip = {clean(script[lang]["tagline"]).lower() for lang in ("ru", "en") if script.get(lang)}
    items, fenced, skipping = [], False, False
    for raw in (body or "").replace("\r", "").split(NL):
        line = raw.strip()
        if line.startswith("```"):
            fenced = not fenced
            continue
        if fenced or not line or set(line) <= set("-=*_ "):
            continue
        head = re.match(r"#+\s*(.*)", line)
        if head:
            skipping = bool(SKIP_SECTION.search(head.group(1)))
            continue
        if skipping or "Описание и все версии" in line or "Full description and" in line:
            continue
        text = clean(re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", line))
        if not text or text.lower() in skip or VERSION.fullmatch(text.lstrip("vV")):
            continue
        if re.fullmatch(r"(?i)(features|changes|изменения|что нового|what's new)\s*:?", text):
            continue
        if INSTALL.match(text):
            continue
        items.append(text)
    return items


def render(entries, lang):
    parts = []
    for i, (version, items) in enumerate(entries):
        first = i == len(entries) - 1
        parts.append("# " + TEXT[lang]["release" if first else "update"] % version)
        parts.append("")
        lines = items or [TEXT[lang]["first" if first else "silent"]]
        parts += ["- " + line for line in lines]
        parts.append("")
    return NL.join(parts).rstrip() + NL


def write(folder, entries):
    folder.mkdir(parents=True, exist_ok=True)
    for lang, name in (("ru", "CHANGELOG.md"), ("en", "CHANGELOG.en.md")):
        (folder / name).write_text(render(entries, lang), encoding="utf-8", newline=NL)


def current_version(script):
    path = BASE / "scripts" / script["id"] / "version.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8")).get("version")
    return (script.get("initial") or {}).get("version")


def entries_from(rels, prefix, script):
    seen, entries = set(), []
    for rel in rels:
        version = version_of(rel, prefix)
        if version and version not in seen:
            seen.add(version)
            entries.append((version, notes(rel.get("body"), script)))
    current = current_version(script)
    if current and current not in seen:
        entries.append((current, []))
    entries.sort(key=lambda e: version_key(e[0]), reverse=True)
    return entries


def main():
    own = None
    made = 0
    for script in CATALOG["scripts"]:
        if script.get("changelog_url"):
            continue
        folder = BASE / "scripts" / script["id"]
        repo = source_repo(script)
        if repo:
            rels = releases(repo)
            monorepo = sum(1 for s in CATALOG["scripts"] if source_repo(s) == repo) > 1
            prefix = script["tag"] + "-v" if monorepo else ""
            rels = [r for r in rels if not prefix or (r.get("tag_name") or "").startswith(prefix)]
            entries = entries_from(rels, prefix, script)
        else:
            if (folder / "CHANGELOG.md").exists():
                continue
            if own is None:
                own = releases(REPO)
            prefix = script["tag"] + "-v"
            entries = entries_from([r for r in own if (r.get("tag_name") or "").startswith(prefix)], prefix, script)
            # releases here only carry the catalog description, never what changed
            entries = [(version, []) for version, _ in entries]
        if not entries:
            continue
        write(folder, entries)
        made += 1
    print("changelogs written: %d" % made)
    # the manager feed links every changelog, new files included
    from release_notes import write_manager_catalog
    write_manager_catalog()


if __name__ == "__main__":
    main()
