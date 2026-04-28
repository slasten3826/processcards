# Target Zone Law

Статус:

```text
canonical table law
current compiler-zone branch
```

Этот документ фиксирует поведение зоны:

```text
targets
```

## 1. Core identity

`targets` — это не просто hidden target structure.

В текущей машине это:

```text
hidden compiler zone
for future victory pattern
```

То есть `targets`:

- хранит скрытые target cards
- может позже содержать открытые trumps
- компилирует victory pattern

См.:

- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)

## 2. Default face state

Карты в `targets` по умолчанию лежат закрытыми.

То есть:

- `targets[1]` hidden
- `targets[2]` hidden
- `targets[3]` hidden

Пока отдельный эффект или процедура не раскрыла карту.

## 3. Default slot count

Current compiler shell has:

```text
3 target slots
```

Коротко:

```text
3 target slots
3 possible compiler trumps
```

## 4. Non-trump reveal law

Если карта в `targets` раскрывается,
и это **не козырь**,
то она не остаётся открытой в target zone.

Вместо этого происходит:

1. раскрытая non-trump card уходит в `grave`
2. на её место из `deck` кладётся новая карта face-down

Коротко:

```text
revealed non-trump target -> grave
deck refills that target slot face-down
```

## 5. Information consequence

Из этого следует:

- non-trump card не живёт в `targets` как открытая поверхность
- `targets` не превращается в обычный face-up row из minors
- hidden compiler structure сохраняется

## 6. Refill law

Когда non-trump card уходит из `targets[i]`,
её слот чинится напрямую из `deck`.

То есть:

```text
deck -> targets[i] face-down
```

Здесь не используется логика `manifest/latent`-колонки.

## 7. Trump reveal override

Если карта в `targets` раскрывается
или становится `known` через observe,
и это козырь,
то для этой зоны действует special-case override.

Такой козырь:

- **не** играет немедленно как событие
- **не** уходит из `targets`
- остаётся в том же `targets[i]`
- остаётся **в открытую**

Коротко:

```text
trump seen in targets does not auto-resolve
trump seen in targets remains in place face-up
```

## 8. Compiler consequence

Открытый козырь в `targets`
не просто “лежит в special zone”.

Он уже считается частью victory compiler.

Когда в `targets` собрано `3` trumps:

```text
compiler is complete
victory pattern exists
```

Когда trump-карт меньше:

```text
compiler is incomplete
no victory check yet
```

## 9. Zone consequence

Из этого следует:

- `targets` может содержать открытые trumps
- открытые trumps в `targets` всё ещё считаются частью target structure
- `targets` в этом месте переопределяет обычное trump-event поведение
- `targets` writes the future victory sentence

## 10. Timing relation

Этот документ сам по себе не делает win check.

Он только фиксирует compiler zone.

Победа проверяется отдельно:

- only after `targets` holds `3` trumps
- only after full turn closure

См.:

- [WIN_CHECK_LAW.md](./WIN_CHECK_LAW.md)
- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)

## 11. What this law does not decide yet

Этот документ пока не решает:

- exact derivation grammar from specific target trump trio
- whether some special trumps may later alter compiler behavior
- exact late-game pressure when targets are partially compiled

Он решает только:

```text
what targets are
what happens when target cards become visible
and when target compilation becomes complete
```

## 12. Short formula

```text
targets are hidden by default
revealed non-trump target goes to grave
deck refills the slot face-down
trump known or revealed in targets stays in targets face-up
three target trumps complete the compiler
```
