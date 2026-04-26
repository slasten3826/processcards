# Observe Vs Reveal Law

Статус:

```text
canonical table law
```

Этот документ фиксирует различие между:

- `observe`
- `reveal`

А также special-case поведение козырей в observe-path.

## 1. Core distinction

`observe` и `reveal` — не одно и то же.

Коротко:

```text
reveal changes the board
observe shows hidden information without automatically changing the board
```

## 2. Reveal

`Reveal` значит:

- карта реально становится открытой частью board state
- её информационный режим меняется для машины
- это больше не просто частное знание наблюдателя

Примеры:

- `latent -> manifest` with reveal on ascent
- explicit target reveal
- any later effect that truly turns a hidden card face-up on the board

## 3. Observe

`Observe` значит:

- игрок получает доступ к скрытой информации
- но сама карта не обязана менять свой board-state
- это inspection of hidden content, not automatic board reveal

То есть:

```text
observe is an inspection act
not the same thing as face-up persistence
```

## 4. Trump on observe: general law

Если в observe-path обнаруживается козырь,
то по общему правилу возникает `TRUMP event`.

Коротко:

```text
observed trump triggers TRUMP event
```

## 5. Target zone override

Для `targets` действует специальное переопределение общего закона.

Если observe касается карты в `targets`,
и там обнаруживается козырь,
то он:

- **не** запускает `TRUMP event`
- просто флипается
- остаётся в том же `targets[i]`
- остаётся там в открытую

Коротко:

```text
observed trump in targets does not auto-resolve
it flips and remains in targets face-up
```

## 6. Why this distinction matters

Этот закон нужен, чтобы не смешивать:

- изменение board state
- частное получение скрытой информации
- special trump event behavior

Иначе `observe` превратится в неясную смесь:

- flip
- reveal
- event trigger

## 7. Relationship to other zone laws

Этот документ нужно читать вместе с:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)
- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)
- [GRAVE_LAW.md](./GRAVE_LAW.md)

Разделение такое:

- `OBSERVE_VS_REVEAL_LAW` = distinction of information acts
- `TARGET_ZONE_LAW` = special behavior of target cards
- `TRUMP_EVENT_MINIMAL_LAW` = what prototype-level trump event currently means
- `TRUMP_ZONE_LAW` = what happens to resolved trump residue later

## 8. What this law does not decide yet

Этот документ пока не решает:

- exact UI of observe
- whether observe pauses the board or opens an inspect layer
- exact resolution timing of observed trump outside target zone

Он решает только:

```text
observe is not reveal
and observed trump normally triggers TRUMP event except in targets
```

## 9. Short formula

```text
observe != reveal
observed trump usually triggers TRUMP event
observed trump in targets only flips and stays there
```
