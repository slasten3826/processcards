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

## `docs/crystall/`

Документы о кодовой фиксации: implementation posture, план сборки, первый crystall scope.

Сюда входят:

- [AGENT_BRIEF.md](../crystall/AGENT_BRIEF.md)
- [IMPLEMENTATION_PLAN.md](../crystall/IMPLEMENTATION_PLAN.md)
- [PROTOTYPE_CRYSTALL.md](../crystall/PROTOTYPE_CRYSTALL.md)
- [LAYERED_PROJECT_POLICY.md](../crystall/LAYERED_PROJECT_POLICY.md)
- [START_GAME_FLOW.md](../crystall/START_GAME_FLOW.md)

## `docs/manifest/`

Видимая карта и навигационные документы.

Сюда входят:

- [README.md](./README.md)
- [STYLE_CANON.md](./STYLE_CANON.md)
- [CARD_FRAME_DIRECTION.md](./CARD_FRAME_DIRECTION.md)
- [vision_assets/processcards_future_vision_v1.png](./vision_assets/processcards_future_vision_v1.png)

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
