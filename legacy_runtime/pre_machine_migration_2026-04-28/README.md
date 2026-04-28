# Legacy Runtime Snapshot

Статус:

```text
backup snapshot
pre-machine-migration runtime
```

Этот каталог содержит копию текущего runtime-кода
до начала активной кодовой миграции
на новую machine branch.

Snapshot date:

```text
2026-04-28
```

Included files:

- `main.lua`
- `conf.lua`
- `src/glyph_layout.lua`
- `src/glyphs.lua`

Purpose:

```text
safe rollback reference
while rewriting gameplay runtime
```

This snapshot is archival.

It should not be treated
as the future active runtime branch.
