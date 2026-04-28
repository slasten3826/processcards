# Board Scope Law

Статус:

```text
canonical table law
shared zone-scope definition
```

Этот документ фиксирует,
что в текущем `ProcessCards` считается:

```text
board
```

## 1. Core claim

`Board` — это не только `manifest`.

Это вся актуальная машинная поверхность,
которая существует на столе
как zones and exposed machine state.

## 2. Board includes

Current board includes:

- `targets`
- `manifest`
- `latent`
- `runtime`
- `grave`
- `trump flow`
- `trump zone`
- `topdeck`

Коротко:

```text
targets
manifest
latent
runtime
grave
trump flow
trump zone
topdeck
```

## 3. Board does not include

Current board does not include:

- `hand`
- deep `deck` beyond topdeck

Коротко:

```text
hand is not board
deep deck is not board
```

## 4. Why topdeck counts

`Topdeck` считается частью board,
потому что он может быть:

- visible
- known
- targetable by lawful effects
- structurally relevant to future state

То есть topdeck — это не просто abstract deck interior,
а current edge of future surface.

## 5. Why hand does not count

`Hand` не считается board,
потому что это не table-surface machine state,
а:

```text
intervention reservoir
```

Рука участвует в игре,
но не принадлежит `board` в scope-reading effects.

## 6. Why deep deck does not count

Внутренность `deck` beyond topdeck
не считается частью board,
потому что она не является directly exposed machine surface.

Если какой-то эффект later хочет работать
с deeper deck structure,
он должен explicitly override this law.

## 7. Relation to effects

Этот закон нужен,
чтобы эффекты могли говорить:

```text
on board
```

без повторного перечисления всех зон.

Это особенно полезно для:

- `WARRANT`
- later broad-access trumps
- later board-wide visibility / displacement effects

## 8. Short formula

```text
board = targets + manifest + latent + runtime + grave + trump flow + trump zone + topdeck
hand is not board
deep deck is not board
```
