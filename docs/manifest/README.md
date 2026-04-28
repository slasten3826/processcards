# Manifest

Это видимая карта документации репозитория.

Документы разложены по 4 каталогам:

## `docs/chaos/`

Сырьё, история, внешние источники, дизайн-предыстория.

Сюда входят:

- [LOCAL_SOURCES.md](../chaos/LOCAL_SOURCES.md)
- [LEGEND.md](../chaos/LEGEND.md)
- [upstream/processcards](../chaos/upstream/processcards/)

## `docs/table/`

Поверхность игры: что уже названо, какие зоны существуют, какой prototype scope разрешён.

Сюда входят:

- [DECK_AND_SETUP_LAW.md](../table/DECK_AND_SETUP_LAW.md)
- [CURRENT_CANON_SUMMARY.md](../table/CURRENT_CANON_SUMMARY.md)
- [BOARD_SCOPE_LAW.md](../table/BOARD_SCOPE_LAW.md)
- [CHAIN_SURFACE_LAW.md](../table/CHAIN_SURFACE_LAW.md)
- [CARD_INFORMATION_STATE_LAW.md](../table/CARD_INFORMATION_STATE_LAW.md)
- [MACHINE_PRIMITIVES_LAW.md](../table/MACHINE_PRIMITIVES_LAW.md)
- [GRAVE_LAW.md](../table/GRAVE_LAW.md)
- [OBSERVE_VS_REVEAL_LAW.md](../table/OBSERVE_VS_REVEAL_LAW.md)
- [MOVE_FIT_LAW.md](../table/MOVE_FIT_LAW.md) — current move-fit canon
- [RESOLUTION_ORDER_LAW.md](../table/RESOLUTION_ORDER_LAW.md)
- [RUNTIME_ZONE_LAW.md](../table/RUNTIME_ZONE_LAW.md)
- [TARGET_ZONE_LAW.md](../table/TARGET_ZONE_LAW.md)
- [TURN_LAW_V2.md](../table/TURN_LAW_V2.md) — current turn-law canon
- [TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md) — current turn sequence canon
- [WIN_CHECK_LAW.md](../table/WIN_CHECK_LAW.md)
- [WIN_CHECK_MIGRATION_STATUS.md](../table/WIN_CHECK_MIGRATION_STATUS.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](../table/TRUMP_EVENT_MINIMAL_LAW.md)
- [TRUMP_BRANCH_STATUS.md](../table/TRUMP_BRANCH_STATUS.md)
- [TRUMP_FLOW_LAW.md](../table/TRUMP_FLOW_LAW.md)
- [TRUMP_RESOLUTION_ORDER_LAW.md](../table/TRUMP_RESOLUTION_ORDER_LAW.md)
- [TRUMP_ZONE_LAW.md](../table/TRUMP_ZONE_LAW.md)
- [TRUMP_IDENTITY_LAW.md](../table/TRUMP_IDENTITY_LAW.md)
- [FOOL_LAW.md](../table/FOOL_LAW.md)
- [SHUFFLE_LAW.md](../table/SHUFFLE_LAW.md)
- [UNVEIL_LAW.md](../table/UNVEIL_LAW.md)
- [RESET_LAW.md](../table/RESET_LAW.md)
- [SWAP_LAW.md](../table/SWAP_LAW.md)
- [WARRANT_LAW.md](../table/WARRANT_LAW.md)
- [REPEAT_LAW.md](../table/REPEAT_LAW.md)
- [UNBOUND_LAW.md](../table/UNBOUND_LAW.md)
- [HALT_LAW.md](../table/HALT_LAW.md)
- [EJECT_LAW.md](../table/EJECT_LAW.md)
- [ORACLE_LAW.md](../table/ORACLE_LAW.md)
- [RECAST_LAW.md](../table/RECAST_LAW.md)

## `docs/crystall/`

Документы о кодовой фиксации: implementation posture, план сборки, первый crystall scope.

Сюда входят:

- [LAYERED_PROJECT_POLICY.md](../crystall/LAYERED_PROJECT_POLICY.md)
- [CODE_MIGRATION_PLAN_V2.md](../crystall/CODE_MIGRATION_PLAN_V2.md)
- [GAMEPLAY_ANIMATION_LAYER.md](../crystall/GAMEPLAY_ANIMATION_LAYER.md)
- [NEXT_GAMEPLAY_SLICE_V2.md](../crystall/NEXT_GAMEPLAY_SLICE_V2.md)

## `docs/legacy/`

Предыдущие поколения документов.

Сюда входят:

- [README.md](../legacy/README.md)
- [table/](../legacy/table/)
- [crystall/](../legacy/crystall/)
- [manifest/](../legacy/manifest/)

## `docs/manifest/`

Видимая карта и навигационные документы.

Сюда входят:

- [README.md](./README.md)
- [PROCESSCARDS_IDENTITY.md](./PROCESSCARDS_IDENTITY.md)
- [STYLE_CANON.md](./STYLE_CANON.md)
- [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)
- [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)
- [GLYPH_SYSTEM_V1.md](./GLYPH_SYSTEM_V1.md)
- [TRUMP_FACE_DIRECTION_V1.md](./TRUMP_FACE_DIRECTION_V1.md)
- [CARD_FRAME_DIRECTION.md](./CARD_FRAME_DIRECTION.md)
- [GLYPH_INK_LAW.md](./GLYPH_INK_LAW.md) — legacy branch
- [CARD_FIELD_BRIGHTENING.md](./CARD_FIELD_BRIGHTENING.md) — superseded step
- [vision_assets/processcards_future_vision_v1.png](./vision_assets/processcards_future_vision_v1.png)

## Current visual canon order

Для текущего card-face layer источники истины читать в таком порядке:

1. [STYLE_CANON.md](./STYLE_CANON.md)
2. [CARD_FACE_COLOR_DIRECTION.md](./CARD_FACE_COLOR_DIRECTION.md)
3. [CARD_FIELD_DARKENING.md](./CARD_FIELD_DARKENING.md)
4. [GLYPH_SYSTEM_V1.md](./GLYPH_SYSTEM_V1.md)
5. [CARD_FRAME_DIRECTION.md](./CARD_FRAME_DIRECTION.md)

Legacy branch:

- [GLYPH_INK_LAW.md](./GLYPH_INK_LAW.md)

Historical step:

- [CARD_FIELD_BRIGHTENING.md](./CARD_FIELD_BRIGHTENING.md)

## Короткая формула

```text
chaos -> table -> crystall -> manifest
```

`chaos` поставляет сырьё.
`table` называет поверхность.
`crystall` фиксирует её в кодовой форме.
`manifest` делает структуру читаемой.

Отдельный важный закон:

```text
table = mechanics
crystall = runtime / implementation shell
manifest = concrete visible card design
```

Отдельно:

```text
manifest may also carry project identity notes
when they define how the whole game should be read
```

И ещё один важный закон документации:

```text
old docs are not deleted
old docs are marked as legacy or superseded
```

То есть история проекта сохраняется в репозитории,
а новый канон добавляется поверх неё,
а не вместо неё.

## Current move-law routing

Текущий move-law canon читать так:

### Current canon branch

- [MOVE_FIT_LAW.md](../table/MOVE_FIT_LAW.md)
- [TURN_LAW_V2.md](../table/TURN_LAW_V2.md)
- [TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md)
- [NEXT_GAMEPLAY_SLICE_V2.md](../crystall/NEXT_GAMEPLAY_SLICE_V2.md)

### Legacy replacement branch

- [HAND_AND_PLAY_LAW.md](../legacy/table/HAND_AND_PLAY_LAW.md)
- [NEXT_GAMEPLAY_SLICE.md](../legacy/crystall/NEXT_GAMEPLAY_SLICE.md)

### Legacy operator / strong branch

Эти документы уже вынесены из current tree
и сохраняются как semantic archive
предыдущей модели:

- [OPERATOR_MODEL.md](../legacy/table/OPERATOR_MODEL.md)
- [STRONG_COMBINED_LAW.md](../legacy/table/STRONG_COMBINED_LAW.md)
- [STRONG_PAIR_TABLE.md](../legacy/table/STRONG_PAIR_TABLE.md)
- [CONNECT_LAW.md](../legacy/table/CONNECT_LAW.md)

Их можно читать только как history/semantic archive,
но не как current execution canon.

## Current machine entry

Если нужен быстрый вход в актуальную машину,
читать в таком порядке:

1. [PROCESSCARDS_IDENTITY.md](./PROCESSCARDS_IDENTITY.md)
2. [CURRENT_CANON_SUMMARY.md](../table/CURRENT_CANON_SUMMARY.md)
3. [TURN_LAW_V2.md](../table/TURN_LAW_V2.md)
4. [TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md)
5. [OPERATORS_INDEX.md](../table/OPERATORS_INDEX.md)
6. [WIN_CHECK_LAW.md](../table/WIN_CHECK_LAW.md)
7. [WIN_CHECK_MIGRATION_STATUS.md](../table/WIN_CHECK_MIGRATION_STATUS.md)
