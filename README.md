# ProcessCards dev

Документация репозитория теперь разложена по 4 каталогам:

- [chaos](./docs/chaos/)
- [table](./docs/table/)
- [crystall](./docs/crystall/)
- [manifest](./docs/manifest/)

Быстрый вход:

1. [docs/manifest/README.md](./docs/manifest/README.md)
2. [docs/table/CONTEXT.md](./docs/table/CONTEXT.md)
3. [docs/chaos/LOCAL_SOURCES.md](./docs/chaos/LOCAL_SOURCES.md)
4. [docs/crystall/IMPLEMENTATION_PLAN.md](./docs/crystall/IMPLEMENTATION_PLAN.md)
5. [docs/crystall/LAYERED_PROJECT_POLICY.md](./docs/crystall/LAYERED_PROJECT_POLICY.md)

Рабочий закон остаётся прежним:

```text
table first
crystall second
```

И отдельный structural law теперь тоже зафиксирован:

```text
table names the game
crystall makes it runnable
manifest makes it visible
```

Документационный закон тоже фиксирован:

```text
do not delete old docs
mark them as legacy or superseded
```

Первый playable machinery layer собираем только на 100 minor-картах.
