# Machine Primitives Law

Статус:

```text
working table draft
machine vocabulary draft
to be tightened during gameplay prototyping
```

Этот документ не фиксирует
все правила игры заново.

Он фиксирует рабочий язык,
на котором должна быть описана механика игры
и отдельных карт.

Главная цель:

```text
card effects should be written
as compositions of reusable machine actions
```

Не так:

```text
this card does a special thing
```

А так:

```text
this card runs a sequence
of already defined machine actions
```

## 1. Core split

Текущую механику полезно мыслить в трёх слоях:

1. atomic primitives
2. standard procedures
3. card procedures

Коротко:

```text
atoms -> reusable procedures -> card effects
```

## 2. Atomic primitives

Атомарный примитив —
это минимальное действие машины,
которое не требует собственной внутренней драматургии.

Current working set:

### Information atoms

- `look`
- `make known`
- `reveal`

Working reading:

- `look` = private inspection, no truth-state upgrade
- `make known` = `hidden -> known`
- `reveal` = `hidden/known -> revealed`

### Transfer atoms

- `move card from X to Y`
- `move card to hand`
- `move card to grave`
- `move card to manifest`
- `move card to latent`
- `move card to targets`
- `move card to runtime`
- `move card to trump flow`
- `move card to trump zone`
- `move card to top of deck`
- `shuffle cards into deck`

### Structural atoms

- `swap two cards`
- `shuffle zone`
- `reorder ordered subset`
- `shift concealed structure by one step`

### Resolution atoms

- `enter ordinary trump flow`
- `follow ordinary trump ecology`
- `perform post-closure victory check`

## 3. Standard procedures

Стандартная процедура —
это уже не атом,
а повторяемая машинная сборка,
которая используется многими законами.

### Draw procedure

Current reading:

1. reveal topdeck
2. if card is trump, it enters ordinary trump flow
3. otherwise it enters hand

Коротко:

```text
draw procedure = reveal topdeck
if trump -> trump flow
else -> hand
```

### Manifest repair

Current reading:

1. `latent[i]` reveals if needed
2. `latent[i] -> manifest[i]`
3. `deck top -> latent[i]`
4. refill preserves current information state of topdeck

Коротко:

```text
manifest hole repaired by latent
latent hole repaired by deck
```

### Target refill

Current reading:

1. revealed non-trump target leaves slot
2. `deck -> targets[i]` face-down

### Ordinary trump entry

Current reading:

1. trump becomes known outside override
2. trump enters ordinary trump flow

### Ordinary trump close

Current reading:

1. resolved in-flight trumps remain in flow until close
2. ordinary close parks them into trump zone
3. chamber release applies if third parked trump would enter

### Halted trump close

Current reading:

1. current resolving item finishes
2. later trump starts are denied
3. halted-flow non-`HALT` trumps flush into deck
4. `HALT` itself follows ordinary ecology

## 4. Card procedures

Card procedures should be described
as compositions of atoms and standard procedures.

Examples:

### `CONNECT`

Not:

```text
gain cards somehow
```

But:

```text
perform 2 draw procedures
```

### `CYCLE`

Not:

```text
cycle vaguely
```

But:

```text
perform 1 draw procedure
then discard 1 card from hand
```

### `RESET`

Not:

```text
reset hand
```

But:

```text
move all hand cards to grave
perform 6 draw procedures
then follow ordinary trump ecology
```

### `RECAST`

Not:

```text
invert the whole world magically
```

But:

```text
move manifest row to proto-hand
reveal latent row
move latent row to manifest
shuffle hand
deal up to 6 cards from hand into latent
fill remaining latent slots from deck
reveal hand overflow one by one
route overflow by class
move proto-hand to hand
follow ordinary trump ecology
```

## 5. Why this matters

Этот split нужен,
чтобы игра не расползалась
в набор уникальных исключений.

Если одна и та же вещь уже существует как machine procedure,
новая карта должна по возможности переиспользовать её,
а не изобретать свою отдельную физику.

Коротко:

```text
reuse procedure
do not invent hidden physics per card
```

## 6. Important distinction

Не всё должно быть атомом.

Если раздробить механику слишком сильно,
документы станут нечитаемыми.

Поэтому current draft признаёт два полезных масштаба:

- atomic primitives
- standard reusable procedures

Это важнее,
чем пытаться сделать идеально формальную низкоуровневую систему уже сейчас.

## 7. Current open questions

Во время прототипирования ещё придётся уточнить:

- какой набор transfer atoms действительно нужен отдельно,
  а какой можно считать просто частным случаем общего `move`
- надо ли выделять отдельный atom для `discard`
  или это всегда `move to grave`
- надо ли выделять отдельный atom для `install`
  или это частный случай zone transfer
- какие процедуры будут достаточно стабильны,
  чтобы считать их canonical machine macros

## 8. Short formula

```text
ProcessCards mechanics should be written
as reusable machine actions.
First define atomic primitives.
Then define standard procedures.
Then define card effects as compositions of those procedures.
```
