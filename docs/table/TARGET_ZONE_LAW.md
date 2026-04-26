# Target Zone Law

Статус:

```text
canonical table law
```

Этот документ фиксирует поведение зоны:

```text
targets
```

## 1. Core identity

`targets` — это hidden target structure.

Базовый режим зоны:

```text
target cards lie face-down
```

## 2. Default face state

Карты в `targets` по умолчанию лежат закрытыми.

То есть:

- `targets[1]` hidden
- `targets[2]` hidden
- `targets[3]` hidden

Пока отдельный эффект или процедура не раскрыла карту.

## 3. Non-trump reveal law

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

## 4. Information consequence

Из этого следует:

- non-trump card не живёт в `targets` как открытая поверхность
- `targets` не превращается в обычный face-up row из minors
- hidden target structure сохраняется

## 5. Refill law

Когда non-trump card уходит из `targets[i]`,
её слот чинится напрямую из `deck`.

То есть:

```text
deck -> targets[i] face-down
```

Здесь не используется логика `manifest/latent`-колонки.

## 6. Trump reveal override

Если карта в `targets` раскрывается,
и это козырь,
то для этой зоны действует special-case override.

Такой козырь:

- **не** играет немедленно как событие
- **не** уходит из `targets`
- остаётся в том же `targets[i]`
- остаётся **в открытую**

Коротко:

```text
revealed trump in targets does not auto-resolve
revealed trump in targets remains in place face-up
```

## 7. Zone consequence

Из этого следует:

- `targets` может содержать открытый козырь
- открытый козырь в `targets` всё ещё считается частью target structure
- `targets` в этом месте переопределяет обычное trump-event поведение

## 8. What this law does not decide yet

Этот документ пока не решает:

- кто именно и когда раскрывает карту в `targets`
- как target victory semantics later читается поверх этой структуры
- порядок этого закона относительно других special resolve layers

Он решает только:

```text
what happens when a revealed target is a non-trump
and what happens when a revealed target is a trump
```

## 9. Short formula

```text
targets are hidden by default
revealed non-trump target goes to grave
deck refills the slot face-down
revealed trump target stays in targets face-up
```
