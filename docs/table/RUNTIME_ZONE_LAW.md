# Runtime Zone Law

Статус:

```text
canonical table law
aligned with current machine branch
```

Этот документ фиксирует поведение зоны:

```text
runtime
```

## 1. Core identity

`runtime` — это специальная установленная зона.

Она не является:

- обычной частью `manifest`
- hidden reservoir как `latent`
- active event queue как `trump flow`
- discard residue как `grave`

Это отдельный installed machine layer.

## 2. Why this zone exists

`runtime` нужен,
чтобы некоторые operator choices
не исчезали сразу после одного хода,
а становились:

```text
persistent future choices
```

То есть `runtime` не хранит passive aura by default.

Он хранит:

```text
installed future option state
```

## 3. Entry restriction

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

## 4. Persistence law

Если карта попала в `runtime`,
она лежит там до тех пор,
пока какой-либо эффект не уберёт её оттуда.

Коротко:

```text
runtime cards persist until explicitly removed
```

То есть `runtime` не является одноразовым transit-slot.

## 5. Current canonical grant law

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

Но всегда ровно один effect.

## 6. Machine consequence

Из этого следует:

- runtime не создаёт auto-cast
- runtime не даёт free multi-effect
- runtime расширяет menu of legal future choices

Коротко:

```text
runtime adds choice
runtime does not add extra cast count
```

## 7. Special opener law: `☱☱`

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

То есть `☱☱` — это opener,
а не final payload.

## 8. Slot law

Current branch assumes:

```text
runtime slot count = 1
```

Это важно,
чтобы future operator menu
не расползалось бесконтрольно.

## 9. Physical execution law

Runtime must stay cardboard-readable.

That means:

- runtime is a real table zone
- installed card visibly occupies it
- players can see which extra operator choice(s)
  the machine currently grants

## 10. Relationship to other machine zones

Разделение now looks like:

- `manifest / latent` = breathing world surface
- `targets` = compiler zone
- `trump flow` = active trump queue
- `trump zone` = resolved trump residue
- `runtime` = installed future choice layer

Коротко:

```text
runtime is not world surface
runtime is not trump queue
runtime is installed choice memory
```

## 11. Current unresolved edge

На текущем слое ещё **не решено**:

- какие конкретно эффекты имеют право удалять runtime card
- может ли later существовать больше одной runtime slot
- whether runtime-installed card is always considered revealed by placement law

## 12. Legacy draft branch

Ниже сохраняется уже не current canon,
а historical hypothesis:

```text
while a runtime card remains in runtime,
its second operator becomes a +1 weak effect
for all played cards
```

Статус этой идеи:

```text
legacy draft only
not current canonical branch
```

## 13. What is canonical right now

На текущем шаге жёстко зафиксировано только:

1. `runtime` — отдельная installed zone
2. туда по умолчанию могут попадать только runtime-cards
3. `☱☱` may temporarily open runtime for any later minor card
4. installed runtime card grants extra choice(s), not free extra cast
5. карта в `runtime` лежит там,
   пока effect явно не уберёт её оттуда

## 14. Short formula

```text
runtime is a persistent install zone
runtime grants extra future operator choices
runtime stores installed choice-memory, not aura math
☱☱ opens runtime for any later minor card
```
