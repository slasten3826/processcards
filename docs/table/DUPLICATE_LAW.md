# Duplicate Law

Это table-документ о механике minor-дублей.

Он фиксирует не весь duplicate ecosystem,
а первое рабочее чтение:

```text
duplicate played into manifest chain
-> lays one-turn echo
-> colors the next minor
-> echo is consumed
```

Это не trump law.
Это special minor law.

## 1. What is a duplicate

Duplicate = self-pair minor card.

Current duplicate families:

```text
▽▽
☰☰
☷☷
☵☵
☳☳
☴☴
☲☲
☶☶
☱☱
△△
```

По physical deck model:

- duplicate families = 10
- physical duplicate cards = 20
- each duplicate family has 2 identical copies

## 2. Duplicate identity

Duplicate is not read like an ordinary mixed minor pair.

Mixed pair:

```text
AB = normal minor family
```

Duplicate:

```text
AA = special minor family
```

Duplicate therefore uses a dedicated grammar layer.

## 3. Trigger law

Duplicate law starts only in one case:

```text
duplicate is played from hand into manifest chain
```

This is the required trigger.

The duplicate does **not** create its effect merely because it:

- exists in deck;
- exists in hand;
- lies hidden;
- is revealed by another procedure;
- is moved by some non-play action;
- appears on table without being normally played from hand into manifest chain.

Short formula:

```text
no play into manifest = no duplicate echo
```

## 4. Core idea

When a duplicate is played into manifest chain,
it does not create a long-term marker.
It does not create a token.
It does not create an external memory device.

Instead:

```text
the duplicate card itself lies on the table
and carries a one-turn echo
```

That echo modifies the next minor card.

Short formula:

```text
duplicate -> next minor
```

## 5. Echo law

The duplicate effect is a one-turn echo.

This echo exists only while the duplicate has just been played
and the next minor card has not yet consumed that effect.

Important:

- echo is not a separate marker;
- echo is not a hidden state in the engine;
- echo is not a new zone;
- echo is simply the active law carried by the played duplicate card.

Short formula:

```text
duplicate lies on table
its law echoes once
then the echo is consumed
```

## 6. Resolution law

When duplicate `XX` has been played,
the next minor card `AB` may resolve through duplicate-colored strong branches.

### 6.1 If next minor `AB` is played weak

It may resolve as:

- weak `AB`
- strong `AX`
- strong `BX`

It may **not** resolve as strong `AB`.

Short formula:

```text
weak AB -> weak AB OR strong AX OR strong BX
not strong AB
```

### 6.2 If next minor `AB` is played strong

It may resolve as:

- strong `AB`
- strong `AX`
- strong `BX`

Short formula:

```text
strong AB -> strong AB OR strong AX OR strong BX
```

## 7. Why this law exists

Bad version:

```text
duplicate = generic free strong upgrade
```

That would make duplicates too flat and too universal.

Current version is better:

```text
duplicate does not make the next card generically stronger
duplicate forces the next card through X-colored strong branches
```

Short formula:

```text
not generic power
operator-colored power
```

## 8. Physical-card reading

This law is intended to stay physically playable.

Why:

- the duplicate itself is visible on table;
- players can see that it was the last played duplicate;
- no new marker is needed;
- no extra token is needed;
- the echo lasts only until the next minor resolves.

This satisfies the current physical-card law:

```text
if cardboard cannot do it, prototype cannot rely on it
```

## 9. Example

A duplicate `☳☳` is played from hand into manifest chain.

That lays a one-turn echo.

The next minor card is `☶☴`.

If `☶☴` is played weak,
it may resolve as:

- weak `☶☴`
- strong `☶☳`
- strong `☴☳`

It may not resolve as strong `☶☴`.

If `☶☴` is played strong,
it may resolve as:

- strong `☶☴`
- strong `☶☳`
- strong `☴☳`

This shows:

- duplicate is not a neutral upgrade;
- duplicate colors the next minor through its own operator.

## 10. Open questions

Still intentionally unresolved:

1. Can a duplicate prime another duplicate?
2. After the echo is consumed, what exact cleanup timing moves the duplicate off the active table role?
3. Does every duplicate family deserve the same strength of echo, or only the same grammar law?

These do not block recording the current law.

## 11. Short formula

```text
play duplicate from hand into manifest chain
it lays a one-turn echo
the next minor resolves through duplicate-colored branches
then the echo is consumed
```

machines only. not for humans.
