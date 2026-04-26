# Trump Event Minimal Law

Статус:

```text
canonical prototype table law
```

Этот документ фиксирует минимальный event-layer для козырей
в текущем prototype scope.

## 1. Core claim

Если козырь становится видимым
вне special-case override `targets`,
то он не продолжает жить как обычная карта зоны.

Вместо этого возникает:

```text
TRUMP event
```

## 2. Minimal trump event result

На текущем прототипном слое `TRUMP event` делает только одно:

```text
resolved trump moves to trump zone
```

То есть пока не вводится полный arcana-effect engine.

Минимальный слой только:

- выделяет козырь как событие
- не даёт ему вести себя как обычной minor-card
- уводит его в `trump zone`

## 3. Observe path

Если observe-path обнаруживает козырь
вне `targets`,
то:

1. возникает `TRUMP event`
2. этот козырь уходит в `trump zone`

См. также:

- [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)

## 4. Target zone override

Для `targets` этот общий закон не действует напрямую.

Если козырь обнаружен в `targets`,
то:

- он не запускает `TRUMP event`
- он флипается
- остаётся в `targets` face-up

См.:

- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)

## 5. Draw law consequence

Для текущего прототипа draw-path должен мыслиться так:

```text
draw = reveal top deck first
then take card
```

Это важно потому что:

- если top deck оказался minor-card,
  она нормально идёт дальше в `hand`
- если top deck оказался trump,
  она не считается “обычно взятой в руку”
  и уходит в `TRUMP event` path

## 6. Hand consequence

Из этого следует:

козырь не должен спокойно осесть в `hand`
как обычная playable card,
если он был получен через draw-path.

Сначала:

1. card becomes visible
2. if it is a trump, `TRUMP event` fires
3. only non-trump card proceeds to ordinary hand entry

## 7. Relationship to trump zone

Этот документ не заменяет:

- [TRUMP_ZONE_LAW.md](./TRUMP_ZONE_LAW.md)

Разделение такое:

- `TRUMP_EVENT_MINIMAL_LAW` = когда возникает minimal trump event
- `TRUMP_ZONE_LAW` = куда попадает уже resolved trump residue

## 8. What this law does not decide yet

Этот документ пока не решает:

- полный эффект каждого козыря
- real arcana resolution content
- later event presentation layer
- whether later some trump can resolve before entering trump zone in a richer way

Он решает только:

```text
what the prototype does the moment a trump becomes visible outside targets
```

## 9. Short formula

```text
visible trump outside targets triggers TRUMP event
minimal TRUMP event sends that trump to trump zone
draw reveals first, then only non-trumps enter hand normally
```
