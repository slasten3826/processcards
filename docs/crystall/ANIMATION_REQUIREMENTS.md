# Animation Requirements

Статус:

```text
canonical crystall requirement
```

Этот документ фиксирует требования к animation layer.

## 1. Intent

Игра должна ощущаться живой и приятной в движении.

Reference feel:

```text
Balatro-like card juice
```

Это не значит копировать Balatro буквально.
Это значит:

- карточное движение должно быть выразительным
- flip / slide / snap / pop должны давать удовольствие
- игра не должна ощущаться как сухой debug table

## 2. Priority

Animation is important,
but not first before table skeleton.

Priority order:

```text
board engine skeleton
-> stable interaction
-> animation layer
```

То есть красивые анимации нужны,
но не ценой ломки surface truth.

## 3. Baseline animation goals

Later runtime should support:

- card move animation
- snap-to-slot animation
- flip animation
- draw/discard motion
- reveal/hide transitions
- subtle emphasis on selected card / legal slot

## 4. Non-goal

Animation must not become:

- fake compensation for unclear rules
- replacement for readable board state
- heavy visual layer that blocks portability

## 5. Architecture consequence

Animation should be its own layer.

That means:

- rules decide state
- animation presents transition between states
- animation must not own rules truth

## 6. Portability constraint

Animation must remain compatible with:

- `720p`
- Switch-like hardware constraints
- non-mouse input modes

That means:

- avoid relying on expensive effects as core readability
- keep motion expressive but lightweight

## 7. Current working rule

We do not need full Balatro-level polish in the first skeleton build.

But we should already avoid architecture that makes good animation hard later.

## 8. Short formula

```text
good card animation is a real requirement,
but it comes after board truth and interaction truth
```
