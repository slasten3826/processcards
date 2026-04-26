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

- [CONTEXT.md](../table/CONTEXT.md)
- [PROTOTYPE_TABLE.md](../table/PROTOTYPE_TABLE.md)
- [DECK_AND_SETUP_LAW.md](../table/DECK_AND_SETUP_LAW.md)
- [CHAIN_SURFACE_LAW.md](../table/CHAIN_SURFACE_LAW.md)
- [CARD_INFORMATION_STATE_LAW.md](../table/CARD_INFORMATION_STATE_LAW.md)
- [GRAVE_LAW.md](../table/GRAVE_LAW.md)
- [HAND_AND_PLAY_LAW.md](../table/HAND_AND_PLAY_LAW.md) — legacy replacement-model law
- [OBSERVE_VS_REVEAL_LAW.md](../table/OBSERVE_VS_REVEAL_LAW.md)
- [MOVE_FIT_LAW.md](../table/MOVE_FIT_LAW.md) — current move-fit canon
- [RESOLUTION_ORDER_LAW.md](../table/RESOLUTION_ORDER_LAW.md)
- [RUNTIME_ZONE_LAW.md](../table/RUNTIME_ZONE_LAW.md)
- [TARGET_ZONE_LAW.md](../table/TARGET_ZONE_LAW.md)
- [TURN_LAW_V2.md](../table/TURN_LAW_V2.md) — current turn-law canon
- [TURN_SEQUENCE_LAW_V2.md](../table/TURN_SEQUENCE_LAW_V2.md) — current turn sequence canon
- [TRUMP_EVENT_MINIMAL_LAW.md](../table/TRUMP_EVENT_MINIMAL_LAW.md)
- [TRUMP_BRANCH_STATUS.md](../table/TRUMP_BRANCH_STATUS.md)
- [TRUMP_ZONE_LAW.md](../table/TRUMP_ZONE_LAW.md)
- [TRUMP_IDENTITY_LAW.md](../table/TRUMP_IDENTITY_LAW.md)

## `docs/crystall/`

Документы о кодовой фиксации: implementation posture, план сборки, первый crystall scope.

Сюда входят:

- [AGENT_BRIEF.md](../crystall/AGENT_BRIEF.md)
- [IMPLEMENTATION_PLAN.md](../crystall/IMPLEMENTATION_PLAN.md)
- [PROTOTYPE_CRYSTALL.md](../crystall/PROTOTYPE_CRYSTALL.md)
- [LAYERED_PROJECT_POLICY.md](../crystall/LAYERED_PROJECT_POLICY.md)
- [START_GAME_FLOW.md](../crystall/START_GAME_FLOW.md)
- [GAMEPLAY_ANIMATION_LAYER.md](../crystall/GAMEPLAY_ANIMATION_LAYER.md)
- [NEXT_GAMEPLAY_SLICE.md](../crystall/NEXT_GAMEPLAY_SLICE.md) — legacy replacement-model slice
- [NEXT_GAMEPLAY_SLICE_V2.md](../crystall/NEXT_GAMEPLAY_SLICE_V2.md)

## `docs/manifest/`

Видимая карта и навигационные документы.

Сюда входят:

- [README.md](./README.md)
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

- [HAND_AND_PLAY_LAW.md](../table/HAND_AND_PLAY_LAW.md)
- [NEXT_GAMEPLAY_SLICE.md](../crystall/NEXT_GAMEPLAY_SLICE.md)

### Candidate-for-legacy group

Эти документы пока не объявлены legacy,
но их канон почти наверняка придётся пересобирать
после стабилизации нового turn-law:

- [OPERATOR_MODEL.md](../table/OPERATOR_MODEL.md)
- [STRONG_COMBINED_LAW.md](../table/STRONG_COMBINED_LAW.md)
- [STRONG_PAIR_TABLE.md](../table/STRONG_PAIR_TABLE.md)
- [CONNECT_LAW.md](../table/CONNECT_LAW.md)

Их still можно читать как semantic/archive layer,
но уже нельзя читать как бесспорный current execution canon
для новой ветки хода.
