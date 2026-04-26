# Grave Law

Статус:

```text
canonical table law
```

Этот документ фиксирует информационный режим зоны:

```text
grave
```

## 1. Core rule

В `grave` не может быть закрытых карт.

Коротко:

```text
grave is always open information
```

## 2. On entry

Если карта попадает в `grave`,
она должна быть раскрыта в момент попадания.

Источник карты не важен.

Если карта пришла в `grave` face-down,
то переход должен читаться так:

1. карта перемещается в `grave`
2. карта немедленно раскрывается

То есть:

```text
face-down -> grave = reveal on entry
```

## 3. Consequence

После попадания карты в `grave`:

- её identity больше не скрыта
- её card face считается открытым знанием
- `grave` не хранит hidden residue

## 4. Why this law exists

Этот закон нужен, чтобы:

- `grave` оставался зоной истории и residue
- hidden information не консервировалась в discard state
- игроки могли читать,
  что именно уже прошло через машину

## 5. What this law does not decide

Этот документ пока не решает:

- ordered vs unordered reading inside grave
- можно ли просматривать весь grave свободно или только top-first
- какие эффекты later могут ссылаться на grave

Он решает только:

```text
no face-down cards may remain in grave
```

## 6. Short formula

```text
all cards enter grave face-up
grave contains no hidden cards
```
