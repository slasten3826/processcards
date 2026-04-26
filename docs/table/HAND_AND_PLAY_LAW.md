# Hand And Play Law

Статус:

```text
canonical table law
```

Этот документ фиксирует базовую роль зоны:

```text
hand
```

и базовый контур хода.

## 1. Core identity

`hand` — это зона playable cards.

Именно из `hand` игрок берёт карту для хода.

Коротко:

```text
the turn begins from hand
```

## 2. Primary interaction surface

Карты из `hand` по базовому правилу
взаимодействуют с:

```text
manifest chain
```

Не с `latent`,
не с `targets`,
не с `grave`.

Базовая playable surface:

```text
hand -> manifest
```

## 3. Core turn skeleton

Базовый ход выглядит так:

1. игрок берёт карту из `hand`
2. игрок целит карту в `manifest chain`
3. целевая карта из `manifest` уходит в `grave`
4. на её место кладётся карта из `hand`

Короткая формула:

```text
hand card targets manifest card
manifest card goes to grave
hand card takes its place
```

## 4. Grave consequence

Когда целевая карта из `manifest` уходит в `grave`,
на неё распространяется:

- [GRAVE_LAW.md](./GRAVE_LAW.md)

То есть в `grave` она не может остаться скрытой.

## 5. Chain consequence

Сам этот документ пока описывает только
первичный replace-step.

Дальнейшая repair-логика chain surface
читается через:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [RESOLUTION_ORDER_LAW.md](./RESOLUTION_ORDER_LAW.md)

## 6. What this law does not decide yet

Этот документ пока не решает:

- weak vs strong legality
- operator payloads
- strong combined reading
- connect exceptions
- logic exceptions
- trump interaction

Он решает только:

```text
where the turn starts
what zone it targets
and what the primary replacement step looks like
```

## 7. Short formula

```text
hand is the source of the turn
manifest is the primary target surface
the played card replaces the targeted manifest card
```
