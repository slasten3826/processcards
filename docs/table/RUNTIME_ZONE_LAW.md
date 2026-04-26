# Runtime Zone Law

Статус:

```text
canonical table law
current runtime install branch
```

Этот документ фиксирует поведение зоны:

```text
runtime
```

Внутри него сохранён текущий канон зоны
и отдельно оставлена legacy-draft гипотеза
для исторического следа.

## 1. Core identity

`runtime` — это специальная установленная зона.

Она не является:

- обычной частью `manifest`
- hidden reservoir как `latent`
- discard residue как `grave`

Это отдельный installed layer.

## 2. Entry restriction

В `runtime` может попасть только runtime-card.

На текущем уровне это значит:

```text
only a card with RUNTIME operator may enter runtime zone
```

Non-runtime cards не могут:

- устанавливаться в `runtime`
- оставаться в `runtime`

Special-case override:

- if `☱☱` currently occupies runtime,
  one later chosen minor card may replace it there

## 3. Persistence law

Если карта попала в `runtime`,
она лежит там до тех пор,
пока какой-либо эффект не уберёт её оттуда.

Коротко:

```text
runtime cards persist until explicitly removed
```

То есть `runtime` не является одноразовым transit-slot.

## 4. Current canonical grant law

Если в `runtime` лежит карта `☱X`,
то она не даёт фоновую ауру.

Она даёт:

```text
one extra reusable operator choice: X
```

То есть при розыгрыше любой карты игрок может выбрать:

- operator A карты
- operator B карты
- runtime operator `X`

Но всегда ровно один эффект.

## 5. Special opener law: `☱☱`

Если в `runtime` лежит `☱☱`,
то оно открывает install-rule:

```text
the next chosen minor card may be installed into runtime
even if it has no ☱
```

Эта новая карта:

1. replaces `☱☱` in runtime
2. sends `☱☱` to `grave`
3. grants both of its operators as extra runtime choices

## 6. Current unresolved edge

На текущем слое ещё **не решено**:

- куда именно уходит карта после удаления из `runtime`
- какие конкретно эффекты имеют право её удалять
- может ли later существовать больше одной runtime slot

## 7. Legacy draft branch

Ниже идёт **не канон**, а рабочий draft.

Идея:

```text
while a runtime card remains in runtime,
its second operator becomes a +1 weak effect
for all played cards
```

То есть runtime-card не просто лежит в зоне,
а создаёт глобальную модификацию текущей машины.

Но это пока **не зафиксировано как law**.

Статус этой идеи:

```text
legacy draft only
not current canonical branch
```

## 8. Why the draft is not locked yet

Эта гипотеза пока ещё не добита,
потому что она сразу тянет за собой:

- что значит `+1 weak effect`
- как это взаимодействует с strong
- что делать, если runtime-card itself has unusual pair structure
- stacking / replacement / removal order

То есть это уже не просто zone rule,
а кусок общей effect engine.

## 9. What is canonical right now

На текущем шаге жёстко зафиксировано только:

1. `runtime` — отдельная installed zone
2. туда по умолчанию могут попадать только runtime-cards
3. `☱☱` may temporarily open runtime for any later minor card
4. installed runtime card grants extra choice(s), not free extra cast
5. карта в `runtime` лежит там,
   пока эффект явно не уберёт её оттуда

## 10. Short formula

```text
runtime is a persistent install zone
runtime grants extra future operator choices
☱☱ opens runtime for any later minor card
```
