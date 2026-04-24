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

## `docs/crystall/`

Документы о кодовой фиксации: implementation posture, план сборки, первый crystall scope.

Сюда входят:

- [AGENT_BRIEF.md](../crystall/AGENT_BRIEF.md)
- [IMPLEMENTATION_PLAN.md](../crystall/IMPLEMENTATION_PLAN.md)
- [PROTOTYPE_CRYSTALL.md](../crystall/PROTOTYPE_CRYSTALL.md)

## `docs/manifest/`

Видимая карта и навигационные документы.

Сюда входят:

- [README.md](./README.md)

## Короткая формула

```text
chaos -> table -> crystall -> manifest
```

`chaos` поставляет сырьё.
`table` называет поверхность.
`crystall` фиксирует её в кодовой форме.
`manifest` делает структуру читаемой.
