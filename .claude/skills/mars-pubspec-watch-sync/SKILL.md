---
name: mars-pubspec-watch-sync
description: Read pubspec_watch.yaml and synchronize its `current:` fields with the actual versions in pubspec.yaml so the watch file always reflects "where I am right now". Use when the user wants to refresh the watch file after a manual bump, or asks "are my watch file and pubspec aligned?". Trigger phrases include "pubspec_watch sync", "watch dosyasını eşitle", "pubspec_watch güncelle", "where am I in the watch file", "sync watch with pubspec".
---

# Pubspec Watch Sync Skill

`pubspec_watch.yaml` projedeki kritik paketlerin "current" durumunu tutan elle bakım gerektiren bir izleme dosyasıdır. Zaman içinde `pubspec.yaml` üzerinde yapılan bump'lar bu dosyaya yansımayabilir. Bu skill iki dosya arasındaki driftleri yakalar ve `pubspec_watch.yaml`'ı **gerçeğe (pubspec.yaml)** göre günceller.

## When to invoke
- `pubspec.yaml`'da elle bir bump yapıldıktan sonra `pubspec_watch.yaml` geride kaldıysa.
- Kullanıcı "tam neredeyim?" / "watch dosyam güncel mi?" diye sorduğunda.
- Yeni paket eklendiyse ve `pubspec_watch.yaml`'a tracking eklenmesi gerekip gerekmediği kontrol edilecekse (raporlanır, yazılmaz).
- `mars-pubspec-watch-diff` skill'i çalıştırılmadan önce baseline'ı hizalamak için.

## What this skill does
1. Reads `pubspec_watch.yaml` and parses each `groups.<group>[*]` entry.
2. Reads `pubspec.yaml` (root) and extracts every `name: ^constraint` line from `dependencies:` and `dev_dependencies:`.
3. For each tracked package, compares `watch.current` to `pubspec.constraint`.
4. Prints a **dry-run diff report** to the user (does not write yet).
5. If the user confirms (or the user explicitly invoked with "apply" / "uygula"), writes the corrected `current:` values back to `pubspec_watch.yaml` and refreshes `meta.last_synced` to today's date.

**This skill never edits `pubspec.yaml`** — `pubspec.yaml` is the source of truth.

---

## Execution plan

### Phase 1 — Parse both files

1. Read `pubspec_watch.yaml` and `pubspec.yaml` in parallel.
2. From `pubspec_watch.yaml`, collect every entry into a list of tuples:
   - `group` (e.g. `firebase`)
   - `name`
   - `current` (the version string, including `^` if present)
   - `line_number` (so we can pinpoint the line to edit)
3. From `pubspec.yaml`, build a map `{ package_name: constraint_string }`.
   - Parse both `dependencies:` and `dev_dependencies:`.
   - Skip path / git deps (`uikit: { path: ... }`, `pin_code_fields: { git: ... }`).
   - For inline constraints (`name: ^x.y.z`), capture the raw value after the colon.

Implementation tip: a single `python3 -c` one-liner with PyYAML is the simplest path. Fall back to regex parsing only if PyYAML is unavailable.

### Phase 2 — Classify each tracked package

For each `(group, name, watch.current)` from the watch file:

- **aligned** — `watch.current == pubspec.constraint` (after trimming whitespace).
- **drift** — both present but differ.
- **missing-in-pubspec** — package listed in watch file but absent from pubspec.yaml. Flag as "stale tracking — consider removing".
- **untracked** — package present in pubspec.yaml direct deps but NOT in the watch file. Flag separately as "should this be tracked?" but do **not** auto-add (the watch file is curated, not exhaustive).

### Phase 3 — Render the dry-run diff

Output exactly this shape:

```markdown
# Pubspec Watch Sync — <YYYY-MM-DD>

**Source of truth:** pubspec.yaml
**Watch file:** pubspec_watch.yaml (last_synced: <existing value>)

## 🔄 Drift detected (N)

| Group | Package | watch.current | pubspec | Action |
|-------|---------|---------------|---------|--------|
| firebase | firebase_core | `^4.8.0` | `^4.9.0` | bump watch → ^4.9.0 |
| ... | ... | ... | ... | ... |

## ⚠️ Stale tracking (M) — present in watch, missing in pubspec
- `<name>` (group: `<group>`)

## ❓ Untracked candidates (K) — in pubspec.yaml but not tracked
- `<name>` (group hint: based on section comment in pubspec)

## ✅ Already aligned (L)
<show count only, or list names on a single comma-separated line if L ≤ 8>
```

Omit any section whose count is zero.

### Phase 4 — Confirm and apply

End the dry-run message with:

> Drift'leri `pubspec_watch.yaml`'a yazmamı ister misin? (Evet / Hayır)
> Stale tracking'leri silmek için ayrıca onay iste.
> Untracked olanları otomatik **eklemem**; eklenmesini istediğin paketleri tek tek söyle.

If the user confirms:
1. For each `drift` row, use the `Edit` tool to replace the `current:` line in `pubspec_watch.yaml` (use `line_number` from Phase 1 to scope the edit, and pass enough surrounding context so the edit is unique).
2. Update `meta.last_synced:` to today's date (`YYYY-MM-DD` in GMT+3 — read from `# currentDate` system context).
3. Re-read `pubspec_watch.yaml` and print a short confirmation: "Synced N packages — last_synced now <date>".

If the user declined, just stop. Do not commit, do not run `melos bootstrap`.

---

## Implementation notes

- **Do not** call `flutter pub get` / `melos bootstrap` from this skill — it is purely a yaml-edit operation. If the user wants to verify the bump compiles, they can run `melos bootstrap` themselves afterward.
- **Do not** touch `review_log` entries. That is owned by the `mars-pubspec-watch-diff` skill.
- **Do not** edit `pubspec.yaml`. Direction is always `pubspec.yaml → pubspec_watch.yaml`.
- **Preserve formatting**: keep the `^` prefix exactly as it appears in `pubspec.yaml`. If `pubspec.yaml` uses a pinned version without `^` (e.g. `freezed: 3.2.0`), mirror that exactly in the watch file.
- **Notes field**: never overwrite the `notes:` field on a package entry — only the `current:` line is in scope.
- **Idempotency**: running this skill twice in a row should report "0 drift" the second time.

## Output guarantees
- The dry-run report is printed **before** any edits are made.
- Edits to `pubspec_watch.yaml` only happen after explicit user confirmation (single "evet"/"yes"/"apply" suffices when the dry-run was just shown).
- After applying, the skill ends with a single-line summary: `Synced N packages · last_synced: <date>`.
