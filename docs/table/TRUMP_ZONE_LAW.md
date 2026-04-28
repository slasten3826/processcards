# Trump Zone Law

Статус:

```text
canonical table law
```

Этот документ фиксирует поведение зоны:

```text
trump zone
```

## 1. Core identity

`trump zone` — это зона открытого residue для козырей.

Коротко:

```text
trump zone holds only trumps
trump zone is always open information
```

## 2. Card class restriction

В `trump zone` могут лежать только козыри.

Minor cards не могут:

- входить в `trump zone`
- оставаться в `trump zone`

## 3. Face state

В `trump zone` не может быть закрытых карт.

Если козырь попадает в `trump zone`,
он должен быть открыт.

Коротко:

```text
all cards in trump zone are face-up
```

## 4. Entry timing

На текущем слое козырь может попасть в `trump zone`
только после ordinary chain close.

То есть:

```text
trump enters trump zone only after event resolution
and only on ordinary chain close
```

Следствие:

- `trump zone` не является staging zone для нерешённого козыря
- `trump zone` не хранит pending trump
- `trump zone` хранит только уже resolved trump residue
- `trump zone` does not receive in-flight trumps mid-chain

Active unresolved trump now belongs in:

- [TRUMP_FLOW_LAW.md](./TRUMP_FLOW_LAW.md)

Ordered close handling now belongs in:

- [TRUMP_RESOLUTION_ORDER_LAW.md](./TRUMP_RESOLUTION_ORDER_LAW.md)

На текущем prototype scope minimal event meaning читается через:

- [TRUMP_EVENT_MINIMAL_LAW.md](./TRUMP_EVENT_MINIMAL_LAW.md)

## 5. Capacity

`trump zone` имеет ёмкость:

```text
2 cards
```

## 6. Overflow law

Если ordinary chain close должен припарковать козырь в `trump zone`,
но свободного места нет,
то происходит не вытеснение одной карты,
а chamber release обратно в deck.

Порядок:

1. новый ordinary-closing trump объединяется с текущими козырями в `trump zone`
2. весь этот набор шафлится обратно в `deck`
3. `trump zone` становится пустой

То есть:

```text
overflow does not keep the new trump in zone
overflow flushes the whole trump residue back into deck
```

Коротко:

```text
third parked trump releases the chamber
```

## 7. Information consequence

Пока козырь лежит в `trump zone`:

- его identity открыта
- он считается частью публичной истории машины

После overflow-flush:

- эти козыри снова теряются в `deck`
- их порядок не сохраняется

## 8. What this law does not decide yet

Этот документ пока не решает:

- как именно козырь сначала резолвится до попадания в зону
- какие эффекты later могут ссылаться на `trump zone`
- можно ли в будущем менять ёмкость зоны

Он решает только:

```text
who may live in trump zone
when they enter
and what happens on overflow
```

## 9. Short formula

```text
trump zone = 2 open trumps parked after ordinary chain close
if a third parked trump would enter,
new trump + all zone trumps shuffle back into deck
```
