# Chain Surface Law

Статус:

```text
canonical table law
```

Этот документ фиксирует,
как устроена рабочая поверхность:

```text
manifest + latent
```

## 1. Core identity

`manifest` и `latent` нельзя мыслить как две независимые зоны.

Они образуют:

```text
one vertical column system
```

Для каждой колонки `i`:

- `manifest[i]` = верхний слой
- `latent[i]` = нижний подпирающий слой

Коротко:

```text
latent supports manifest
```

## 2. Empty-slot prohibition

Для chain surface действует закон:

```text
svyato mesto pusto ne byvaet
```

То есть после завершения резолва
пустые слоты не должны оставаться:

- в `manifest`
- в `latent`

## 3. Manifest repair law

Если карта уходит из `manifest[i]`,
то её слот не пополняется напрямую из `deck`.

Правильный порядок такой:

1. `latent[i]` поднимается в `manifest[i]`
2. поднятая карта раскрывается,
   если она была закрыта
3. в `latent[i]` докладывается новая карта из `deck`
   с сохранением её текущего information state

Короткая формула:

```text
manifest hole is repaired by latent
latent hole is repaired by deck
```

## 4. Latent repair law

Если карта уходит из `latent[i]`,
то:

1. слот `latent[i]` становится пуст
2. в `latent[i]` докладывается новая карта из `deck`
   с сохранением её текущего information state

То есть:

```text
deck repairs latent directly
```

## 5. Reveal law on ascent

Когда карта поднимается из `latent[i]` в `manifest[i]`,
она должна быть открыта.

Если карта была скрыта,
она раскрывается в момент подъёма.

Коротко:

```text
latent -> manifest = reveal on ascent
```

## 6. Information consequence

Из этого следует:

- `manifest` не пополняется скрытой картой
- `latent` по умолчанию остаётся hidden reservoir
- `deck` взаимодействует с `manifest` только опосредованно, через `latent`

Но если карта из `deck` уже стала `known` или `revealed`
по другому закону,
repair не должен заново делать её полной hidden.

## 7. What this law does not decide

Этот документ пока не решает:

- когда именно внутри полного резолва запускается repair step
- что происходит, если эффект сам же потом снова двигает ту же колонку
- как эта логика later сочетается с более сложными exception effects

Он решает только:

```text
how manifest and latent structurally refill
```

## 8. Short formula

```text
manifest is repaired by latent
latent is repaired by deck
latent rises revealed
deck refill preserves current known/revealed state
```
