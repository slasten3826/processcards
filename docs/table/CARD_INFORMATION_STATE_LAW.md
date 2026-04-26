# Card Information State Law

Статус:

```text
canonical table law
```

Этот документ фиксирует информационные состояния карты
в текущем prototype scope.

## 1. Core distinction

У карты есть не два, а три важных информационных состояния:

1. `hidden`
2. `known`
3. `revealed`

Коротко:

```text
hidden = unknown card
known = card identity is known without public face-up persistence
revealed = card is openly surfaced in board state
```

## 2. Hidden

`Hidden` значит:

- карта не раскрыта для машины как открытая поверхность
- её лицо не показано на столе
- её identity не считается известной по умолчанию

Это базовый режим для:

- `targets`
- `latent`
- unrevealed top deck

## 3. Known

`Known` значит:

- identity карты уже известна
- но сама карта не обязана становиться `revealed`
- карта может оставаться face-down как board-object

`Known` — это не косметика, а отдельное truth-state.

Коротко:

```text
known is not the same thing as revealed
```

## 4. Revealed

`Revealed` значит:

- карта стала открытой частью board state
- она лежит как public face-up object
- это уже не частное знание, а surfaced state of the machine

Из этого следует:

```text
every revealed card is also known
```

## 5. Observe law

По умолчанию `observe` делает не `reveal`, а:

```text
hidden -> known
```

То есть:

- `observe` даёт узнать карту
- но не обязан делать её face-up на столе

## 6. Reveal law

`Reveal` делает:

```text
hidden -> revealed
known -> revealed
```

То есть reveal — это более сильное изменение, чем observe.

## 7. No automatic re-hide

Если карта уже стала `known` или `revealed`,
она по общему закону не должна самопроизвольно возвращаться в полное `hidden`.

Коротко:

```text
known cards do not become unknown again by default
revealed cards do not re-hide by default
```

Это особенно важно для:

- top deck after `UNVEIL`
- refill into `latent`
- later delayed zone movement

## 8. Trump consequence

Для козырей важно не только `revealed`, но и `known`.

Если козырь становится `known`,
то по общему закону это уже достаточно,
чтобы сработал trump-event path,
если zone override не говорит иначе.

Коротко:

```text
trump may trigger on known, not only on revealed
```

## 9. Visual consequence

`Known` и `revealed` не обязаны выглядеть одинаково.

Допустимый visual law для prototype:

- `hidden` = обычная рубашка
- `known` = рубашка + ghost identity overlay
- `revealed` = полноценное открытое лицо карты

Этот документ не фиксирует точный арт,
но разрешает этот middle layer явно.

## 10. Relationship to other laws

Этот документ нужно читать вместе с:

- [OBSERVE_VS_REVEAL_LAW.md](./OBSERVE_VS_REVEAL_LAW.md)
- [TARGET_ZONE_LAW.md](./TARGET_ZONE_LAW.md)
- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)

Разделение такое:

- `CARD_INFORMATION_STATE_LAW` = общий truth-model hidden / known / revealed
- `OBSERVE_VS_REVEAL_LAW` = distinction of information acts
- `TARGET_ZONE_LAW` = target-zone override
- `TRUMP_EVENT_MINIMAL_LAW` = what prototype trump-event does when trump becomes known outside targets

## 11. Short formula

```text
observe creates known
reveal creates revealed
revealed implies known
known does not automatically imply revealed
known and revealed do not revert to full hidden by default
```
