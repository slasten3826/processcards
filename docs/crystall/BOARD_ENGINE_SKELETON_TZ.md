# Board Engine Skeleton TZ

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует ближайший build layer:

```text
board engine skeleton
```

Это ещё не gameplay-complete prototype.
Это скелет стола и перемещения карт.

## 1. Goal

Собрать первый живой board-engine слой,
в котором уже существуют все ключевые зоны
и уже можно физически гонять карты по столу.

Главная задача этого слоя:

```text
доказать, что поверхность игры живёт как карточный стол
ещё до полного gameplay law
```

## 2. What this layer is

This layer is:

- zone skeleton
- card movement skeleton
- visibility skeleton
- interaction skeleton

This layer is not yet:

- full weak/strong gameplay
- full operator engine
- full trump gameplay
- victory system

## 3. Required zones

Board engine skeleton must contain:

- `deck`
- `hand`
- `grave`
- `runtime`
- `targets`
- `manifest row`
- `latent row`
- `trump zone`

All these zones must already exist visually and structurally.

## 4. Card model in this layer

На этом этапе карты могут быть:

- blank placeholders
- backs
- simple dummy faces
- ids without full gameplay text

This is allowed.

The point of this layer is not full card semantics.
The point is table surface and movement.

## 5. Required interactions

The skeleton must support:

- selecting a card
- dragging a card
- dropping a card into a zone
- zone snapping
- returning card to origin if move is not accepted
- face-up / face-down state changes
- drawing from deck
- discarding to grave

## 6. Minimum movement law

At this stage,
movement law may still be skeletal,
but it must not be arbitrary chaos.

The engine should already distinguish:

- valid manual move
- invalid manual move
- hidden/public orientation
- ordered zones vs unordered zones

## 7. Ordered zones

The skeleton must already preserve ordered behavior for:

- `grave`
- `targets`
- `manifest row`
- `latent row`

That means the engine must understand:

- slot order
- insertion point
- top/bottom semantics where relevant

## 8. Hidden/public law

This layer must already support:

- face-up card
- face-down card
- reveal
- hide

Important:

```text
hidden/public state is part of the board engine
not an afterthought
```

## 9. Trump zone law

`trump zone` must already exist in the skeleton,
but trumps do not enter active gameplay yet.

Current rule:

- zone exists
- cards can be represented there
- active trump resolution is deferred

This is shell-only presence,
not gameplay commitment.

## 10. Runtime law

`runtime` must also exist from the start.

Current requirement:

- visible zone
- capacity can already be represented
- installation logic may still be deferred

Again:

shell first,
full mechanic later.

## 11. Input law

Board engine skeleton must be usable without full rule text.

That means the player can already:

- pick card
- move card
- place card
- flip card where allowed
- see zone reaction

## 12. Out of scope

This layer does not yet require:

- complete weak/strong legality
- full strong pair readings
- complete operator payloads
- duplicate law execution
- active trump gameplay
- victory check

## 13. Definition of done

Board engine skeleton is done when:

1. all key zones exist
2. cards can be selected and moved
3. drag/drop or equivalent placement works
4. invalid moves snap back safely
5. face-up / face-down states work
6. deck decreases when drawing
7. grave grows visibly and in order
8. manifest/latent/targets/runtime/trump zone are all already present as board reality

## 14. Short formula

```text
first we build the table as a real card surface
then we teach it the game
```
