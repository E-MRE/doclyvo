# Naming Conventions — apps/web

- **Files:** `kebab-case.ts` / `kebab-case.tsx` for everything except a component's own file,
  which matches the component name in `PascalCase.tsx` (e.g. `UploadDropzone.tsx`).
- **Components:** `PascalCase`, named exports (not default exports) so imports are greppable
  and renames are safe: `export function UploadDropzone() {}`.
- **Hooks:** `useCamelCase`, one hook per file, filename `use-camel-case.ts`.
- **Server actions:** verbs, `camelCase`, colocated in the feature's `actions.ts`
  (`compressPdf`, `mergeFiles`).
- **Types/interfaces:** `PascalCase`, no `I` prefix (`CompressOptions`, not `ICompressOptions`).
- **Constants:** `SCREAMING_SNAKE_CASE` only for true constants (`MAX_FILE_SIZE_MB`); config
  objects use `camelCase` (`defaultCompressOptions`).
- **Feature folder names:** match the tool's route segment (`features/compress/` ↔
  `app/tools/compress/`).
- **No `Base`/`Abstract` prefix** on types — mirrors the Flutter-side naming rule
  (`CompressOptions`, not `BaseCompressOptions`).
