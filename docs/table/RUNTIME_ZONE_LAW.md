# Runtime Zone Law

Статус:

```text
mixed table law
```

Этот документ фиксирует поведение зоны:

```text
runtime
```

Внутри него разделены:

- `canonical zone law`
- `draft gameplay hypothesis`

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

## 3. Persistence law

Если карта попала в `runtime`,
она лежит там до тех пор,
пока какой-либо эффект не уберёт её оттуда.

Коротко:

```text
runtime cards persist until explicitly removed
```

То есть `runtime` не является одноразовым transit-slot.

## 4. Current unresolved edge

На текущем слое ещё **не решено**:

- куда именно уходит карта после удаления из `runtime`
- какие конкретно эффекты имеют право её удалять
- может ли later существовать больше одной runtime slot

## 5. Draft gameplay hypothesis

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
draft only
not yet canonical
```

## 6. Why the draft is not locked yet

Эта гипотеза пока ещё не добита,
потому что она сразу тянет за собой:

- что значит `+1 weak effect`
- как это взаимодействует с strong
- что делать, если runtime-card itself has unusual pair structure
- stacking / replacement / removal order

То есть это уже не просто zone rule,
а кусок общей effect engine.

## 7. What is canonical right now

На текущем шаге жёстко зафиксировано только:

1. `runtime` — отдельная installed zone
2. туда могут попадать только runtime-cards
3. карта в `runtime` лежит там,
   пока эффект явно не уберёт её оттуда

## 8. Short formula

```text
runtime is a persistent install zone
only runtime-cards may enter it
what the installed card actually grants remains draft
```
