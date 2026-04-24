# Browser UI Contract

Статус:

```text
canonical crystall contract
```

Этот документ фиксирует UI-слой первого браузерного прототипа.

Он не задаёт полный visual design.
Он задаёт:

- layout contract
- interaction contract
- visibility rules
- границу между UI и rules

## 1. Purpose

UI первого browser prototype должен делать ровно одно:

```text
давать честно играть в minor-machine мышкой
```

Не маркетинг.
Не декоративный mockup.
Не “почти Balatro”.

Функциональный карточный стол first.

## 2. Main screen

Первый экран = сразу игровой стол.

Никакого landing screen.
Никакого отдельного menu-first flow.

При открытии пользователь должен сразу видеть:

- deck
- targets
- manifest row
- latent row
- hand
- runtime
- grave
- action controls
- log

## 3. Board layout

Current layout contract:

### Top band

- left: `deck`
- center: `targets`
- right: `system / counters`

### Center band

- main focus: `manifest row`
- directly beneath: `latent row`

### Bottom band

- left or center: `hand`
- side: `runtime`
- side: `grave`

### Bottom edge or side panel

- `action controls`
- `log`

This may be mirrored later,
but the first prototype must keep:

```text
manifest as the visual center
```

## 4. Manifest and latent presentation

Manifest row:

- 5 visible cards
- clearly separated slots
- visible slot targeting feedback
- ring adjacency does not need to be visually circular,
  but the UI must not imply false hard edges

Latent row:

- 5 hidden cards beneath manifest
- card backs visible
- relation to the same column visually obvious

## 5. Hand presentation

Hand must:

- show all current cards at once if possible
- remain clickable
- visibly indicate selected card
- not reorder itself unexpectedly during a turn

If hand grows too wide,
overlap is allowed,
but every card must stay selectable.

## 6. Action controls

The UI must expose exactly these action modes:

- `Weak`
- `Strong`
- `Discard`
- `Pass`

Controls must:

- always stay visible
- clearly indicate current mode
- not hide legality rules

## 7. Core interaction flow

The default click flow:

1. choose action mode
2. choose hand card
3. choose target if action needs target
4. resolve action

### Weak

- click `Weak`
- click hand card
- hover or click manifest slot
- UI shows legal / illegal target feedback
- click target to resolve

### Strong

- same structure as weak

### Discard

- click `Discard`
- click hand card
- resolve immediately

### Pass

- click `Pass`
- resolve immediately

## 8. Feedback rules

UI must give immediate feedback for:

- selected hand card
- selected action mode
- legal manifest targets
- illegal manifest targets
- current turn result
- card movement into grave / hand / manifest

Minimum acceptable feedback:

- outline
- glow
- opacity shift
- short log line

## 9. Hidden information rules

UI must not leak hidden truth.

That means:

- latent cards remain backs unless legally observed or manifested
- topdeck remains hidden unless legally accessed
- target hidden slots remain hidden unless legally exposed

The browser may remember revealed public state,
but may not reveal hidden state without a legal operator path.

## 10. Runtime presentation

Runtime must exist visually from v0.

Even if full runtime behavior is deferred,
the slot must be present and readable.

Requirements:

- capacity `1`
- occupied / empty state visible
- installed card visually distinct from manifest card

## 11. Grave presentation

Grave must communicate:

- order
- top card
- count

The first prototype does not need a full grave inspector,
but it must not flatten grave into a meaningless pile.

## 12. Targets presentation

Target zone must visually exist from v0.

Requirements:

- 3 ordered slots
- hidden/back state readable
- future-compiler importance hinted by placement,
  not by explanatory text

## 13. System panel

The first browser prototype may include a compact system panel.

Allowed contents:

- deck count
- hand count
- grave count
- current turn
- current mode

Do not overload it with debug junk on the main surface.

## 14. UI / rules boundary

UI is allowed to:

- calculate hitboxes
- render zones
- highlight legal states
- show animations later

UI is not allowed to:

- decide move legality
- own hidden truth
- mutate zones directly without rules layer
- silently apply operator effects

Short formula:

```text
rules decide
ui shows
input requests
```

## 15. Technical recommendation

Recommended browser structure:

```text
prototype/
  index.html
  styles.css
  app.js
  rules/
  ui/
```

Recommended responsibility split:

- `rules/`:
  - setup
  - legality
  - state transitions
  - operator resolution
- `ui/`:
  - render
  - click handling
  - visual state

## 16. Definition of done

UI contract is satisfied when:

1. player can perform all four action modes with mouse only
2. board zones are readable without explanation text
3. hidden/public distinction is preserved
4. legal and illegal targets are visually distinguishable
5. manifest is visually the center of play
6. no rules truth lives only in DOM state

## 17. Short formula

```text
browser UI v0 = readable clickable card table with strict rules separation
```
