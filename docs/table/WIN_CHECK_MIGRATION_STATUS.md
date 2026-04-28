# Win Check Migration Status

Статус:

```text
canonical migration map
for the current victory/compiler rewrite
```

Этот документ нужен не как правило игры,
а как карта документной миграции
после появления [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md).

## 1. Why this exists

`WIN_CHECK_LAW` меняет не один edge case,
а сразу несколько опорных предпосылок машины:

- `manifest chain = 6`
- `hand = 6`
- `targets` = compiler zone
- directed manifest reading is part of victory
- win check happens only after full turn closure

Поэтому часть current docs больше нельзя считать fully aligned.

## 2. Status classes

This migration map uses:

- `stable canon`
- `canon but needs rewrite`
- `new branch source`
- `legacy archive`

## 3. New branch source

Primary source:

- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

Current status:

```text
working victory draft
high-impact branch
```

It is not yet final balance law,
but it is already strong enough
to force documentation migration.

## 4. Stable canon

These docs still remain current
even after the victory/compiler shift:

- [CARD_INFORMATION_STATE_LAW.md](./CARD_INFORMATION_STATE_LAW.md)
- [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)
- [DRAW_PROCEDURE_LAW.md](./DRAW_PROCEDURE_LAW.md)
- [GRAVE_LAW.md](./GRAVE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)
- [TRUMP_IDENTITY_LAW.md](./TRUMP_IDENTITY_LAW.md)
- [OPERATORS_INDEX.md](./OPERATORS_INDEX.md)
- [operators/*.md](./operators/)

Reason:

their core claims are not invalidated by 6-slot victory compilation.

## 5. Canon but needs rewrite

These docs remain important,
but are no longer sufficient in current wording:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [MOVE_FIT_LAW.md](./MOVE_FIT_LAW.md)
- [RESOLUTION_ORDER_LAW.md](./RESOLUTION_ORDER_LAW.md)
- [RUNTIME_ZONE_LAW.md](./RUNTIME_ZONE_LAW.md)
- [../crystall/NEXT_GAMEPLAY_SLICE_V2.md](../crystall/NEXT_GAMEPLAY_SLICE_V2.md)

Reason:

their core is still useful,
but they now need explicit sync with:

- 6-slot visible sentence reading
- post-resolution win check

## 6. Rewritten into current branch

These docs have already been rewritten
and are now aligned with the current victory/compiler machine:

- [DECK_AND_SETUP_LAW.md](./DECK_AND_SETUP_LAW.md)
- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [TURN_LAW_V2.md](./TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)

## 7. Legacy archive

Previous generation material is already removed
from current tree and preserved here:

- [../legacy/table/](../legacy/table/)
- [../legacy/crystall/](../legacy/crystall/)

This includes old:

- replacement-model move law
- weak/strong chassis
- old prototype skeleton docs

## 8. Recommended rewrite order

Rewrite order should be:

1. `CHAIN_SURFACE_LAW`
2. `NEXT_GAMEPLAY_SLICE_V2`
3. `MOVE_FIT_LAW`
4. `RESOLUTION_ORDER_LAW`
5. `RUNTIME_ZONE_LAW`
6. if needed, split new backbone docs

Reason:

visible surface, implementation slice, and remaining timing docs
must agree before code planning is touched again.

## 9. What should not happen

Do not:

- silently patch every file inline without migration map
- treat old `5-slot` assumptions as harmless
- mix victory compiler language into unrelated docs at random

The rewrite must stay structured.

## 10. Short formula

```text
WIN_CHECK_LAW does not replace the whole canon yet,
but it already forces a new documentation generation.
```
