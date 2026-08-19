---
name: mars-pubspec-watch-diff
description: For every package tracked in pubspec_watch.yaml, compare the recorded `current:` version against the latest stable release on pub.dev, fetch the changelog between those versions, and produce a markdown decision document that highlights breaking changes / important notes. The skill stops at the doc — migration is only applied after the user explicitly approves which bumps to take. Trigger phrases include "watch farkları çıkar", "pub.dev ile karşılaştır", "changelog farkları doc", "pubspec watch diff", "what changed since my versions", "review watched packages against pub.dev".
---

# Pubspec Watch Diff Skill

`pubspec_watch.yaml`'daki `current:` değerlerini pub.dev'deki güncel sürümlerle karşılaştırır. Tek başına bir **karar belgesi** üretir — paketleri otomatik güncellemez. Kullanıcı doc üzerinden onayladığı bump'lar için ayrı bir apply adımına geçilir.

> **Önkoşul:** `pubspec_watch.yaml` ile `pubspec.yaml` arasında drift olmamalı. Önce `mars-pubspec-watch-sync` çalıştırılması önerilir; aksi halde "current" yanıltıcı olur.

## When to invoke
- Haftalık / sprint sonu paket gözden geçirmesi.
- Kullanıcı "watch dosyamdaki paketler için pub.dev'de ne değişmiş?" diye sorduğunda.
- Bir paketin yeni majör sürümüne geçmeden önce breaking note özetine ihtiyaç olduğunda.
- Amaç **doc oluşturmak** — `docs/packages/diff-<date>.md` veya konuşmada özet — ve ardından kullanıcı onayıyla seçici migration.

## Scope — what this skill does NOT do
- Does **not** scan transitive deps. Scope is exactly the packages listed in `pubspec_watch.yaml.groups.*`.
- Does **not** call `flutter pub outdated` (that is `pubspec-audit`'in işi). Kaynak: pub.dev API + changelog sayfası.
- Does **not** edit `pubspec.yaml` veya `pubspec_watch.yaml` until the user explicitly approves a bump set in Phase 5.

---

## Execution plan

### Phase 1 — Drift gate

1. Read `pubspec_watch.yaml` and `pubspec.yaml`.
2. For each tracked package, verify `watch.current` matches the constraint in `pubspec.yaml`.
3. If **any** drift exists, stop and tell the user:
   > "`pubspec_watch.yaml` ile `pubspec.yaml` arasında N drift var. Önce `/mars-pubspec-watch-sync` çalıştır, sonra tekrar dene."
   Do not proceed to pub.dev queries — they would be based on stale data.

### Phase 2 — Fetch latest from pub.dev

For every tracked package, fetch:
```
https://pub.dev/api/packages/<name>
```
This JSON endpoint returns `latest.version`. Run all fetches **in parallel batches of 8** via `WebFetch` with a prompt like:
> "Return just the value of `latest.version` from this JSON response. Output nothing else."

Build a map `{ name: latest_version }`.

For each package, compute the bump kind from `current` (strip `^` and any pre-release suffix) vs `latest`:
- Same → **aligned** (skip from main report; list at the bottom).
- Patch (same major.minor) → **patch**.
- Minor (same major) → **minor**.
- Different major → **major**.
- Latest contains pre-release tag (`-dev.`, `-beta.`, `-rc.`) → **prerelease** (note only).
- 0.x packages: treat any minor bump as effectively breaking — label `minor⚠️`.

### Phase 3 — Fetch changelog excerpts (only for non-aligned packages)

For every package classified as patch / minor / major:
```
https://pub.dev/packages/<name>/changelog
```
Fetch via `WebFetch` with prompt:
> "Extract changelog entries strictly between version `<current>` (exclusive) and `<latest>` (inclusive). Preserve markdown headings and bullets. Flag any line containing the words 'BREAKING', 'breaking change', 'deprecated', 'removed', 'renamed' with a leading 🔴. Return at most 25 lines; if longer, truncate and append `... (see full changelog at <url>)`."

Run in **parallel batches of 5**. For each excerpt, capture:
- the full markdown,
- a derived `is_breaking` boolean (true if 🔴 appears or version is a major bump).

If `WebFetch` returns nothing useful, fall back to fetching `https://pub.dev/packages/<name>` and looking for the `repository` URL, then try `<repo>/raw/main/CHANGELOG.md` once. Don't retry beyond that — note "(changelog unavailable)" in the report.

### Phase 4 — Render the decision document

Generate a single markdown doc. Default output target: **conversation only**. If the user said "save" / "kaydet" / "doc'a yaz" during invocation, also write the same content to `docs/packages/diff-<YYYY-MM-DD>.md` (create the directory if missing).

Shape:

```markdown
# Pubspec Watch Diff — <YYYY-MM-DD>

**Tracked packages:** <total>
**Outdated:** <count> (🔴 major: A · 🟡 minor: B · 🟢 patch: C · ⚪ prerelease: D)
**Project notes worth re-reading:** <list package names whose `notes:` field in pubspec_watch.yaml mentions integration concerns — e.g. BiometricGuard, ProductNetworkManager>

---

## 🔴 Major bumps — manual review required

### `<name>` — `<current>` → `<latest>`
- **Group:** `<group>`
- **Watch notes:** _<verbatim from pubspec_watch.yaml `notes:` field, if any>_
- **Breaking signals:** <one-line summary of 🔴 lines, e.g. "API rename: `ext` → `fileExtension`; wrapper class removed">

<changelog excerpt>

---

## 🟡 Minor bumps

### `<name>` — `<current>` → `<latest>`
... (same shape, omit "Breaking signals" if none)

---

## 🟢 Patch bumps
<compact one-liner per package, no full changelog — just "fix:" / "perf:" headline if extractable>

- `<name>` `<current>` → `<latest>` — <one-line summary>

---

## ⚪ Pre-release available (informational only)
<one line per package>

---

## ✅ Already on latest
<single comma-separated line of package names>

---

## Decision prompt

Hangilerini uygulayalım? Seçenekler:
- `apply patch` — sadece patch bump'ları uygula.
- `apply patch+minor` — patch ve minor bump'ları uygula (major'lar elde).
- `apply <name1>,<name2>` — belirli paketleri uygula.
- `none` — sadece doc, geçiş yok.
```

Sort within each section **alphabetically by package name**. Omit empty sections entirely.

### Phase 5 — Apply (only after explicit user approval)

The user picks one of the options from the decision prompt. Only then:

1. **Build the bump set.** Resolve the user's selection into a concrete list of `(name, current, latest)` tuples.

2. **For each package in the bump set:**
   - Update the constraint in `pubspec.yaml` (use `Edit` with enough surrounding context to make the match unique — usually `<name>: ^<current>` is unique on its own).
   - Mirror the new value in `pubspec_watch.yaml`'s `current:` field for the matching package.
   - Preserve the `^` prefix style — if `current` had `^` keep `^<latest>`; if pinned, keep pinned.

3. **Append a `review_log` entry** to the end of `pubspec_watch.yaml` for this cycle:
   ```yaml
     - week: <next sequential number — read the existing log and increment>
       date: <YYYY-MM-DD>
       findings:
         - package: <name>
           reviewed_version: <latest>
           status: installed   # or `pending` if user chose `none` but wants the row recorded
           summary: |
             <one-paragraph human summary of the changelog — pull from Phase 3 excerpt>
             <if breaking: BREAKING: <one-line note>>
             <if migration touched code: Migrated <file/class names>.>
   ```
   For bumps that were **not** taken, status is `pending` and `summary` records why it was skipped.

4. **Update `meta.last_synced:` to today's date** in `pubspec_watch.yaml`.

5. **Verify the build.** Run, in this order:
   ```bash
   melos bootstrap   # or: sh ./scripts/pub_get.sh as fallback
   flutter analyze
   ```
   If `melos` is unavailable, fall back to `sh ./scripts/pub_get.sh`.
   - If `flutter analyze` reports new errors caused by the bump (breaking API changes), **stop and tell the user**:
     > "Migration introduced N analyzer errors. Should I fix them, or revert the bump?"
     Do not silently attempt to fix breaking changes — these may require code migration the user wants to review.

6. **Final summary** to the user:
   - Bumped: `<list of name: old → new>`
   - Skipped (with reasons): `<list>`
   - Analyzer: passing / N new errors
   - Suggested follow-ups: physical-device tests for `local_auth`, `firebase_*`, etc. (only if relevant packages were bumped).

---

## Implementation notes

- **Tool budget:** ~30–60 tool calls for a full pass (pub.dev metadata + changelog per outdated package). Aggressively parallelise both the metadata and changelog fetches.
- **Caching:** If this skill was already run in the current session, reuse the `latest` map and only re-fetch packages that were applied in the meantime. Ask the user before re-running from scratch.
- **Dependency overrides:** `pubspec_watch.yaml` no longer tracks `dependency_overrides` (intentionally simplified). If the user asks why a package shows aligned despite a clear override in `pubspec.yaml`, surface the override as a footnote in the doc.
- **Major bumps with watch notes:** Always re-show the package's `notes:` verbatim in the doc — these hints (e.g. "BiometricGuard depends on this") are the whole reason the watch file exists.
- **Save-to-doc mode:** When persisting to `docs/packages/diff-<date>.md`, also append a one-line index entry to `docs/packages/INDEX.md` if that file exists; do not create `INDEX.md` if it doesn't (avoid scope creep).
- **No commits.** This skill never runs `git add` / `git commit`. The user decides when to commit the resulting changes.

## Output guarantees
- Phase 4 doc is shown **before** any file edits.
- Edits in Phase 5 only happen after the user picks one of the decision-prompt options.
- The final summary always reports analyzer status — silent success after a major bump is not acceptable.
- Empty sections in the doc are omitted (no empty headers).
