# ProcessCards :: YELLOWPRINT v3.5

[⊞ ◈] [☵ ☳ ☶ ☲ ☱ △]

## Статус

Yellowprint v3.5.

Это не финальная спецификация.
Это не набор карт, готовых к печати.
Это не balance document.
Это не rulesheet для массовой игры.

Это текущий design-crystall после следующего слоя уточнения.

v3.5 фиксирует:

- closed economy как железный инвариант
- `manifest chain` как абстрактную строку состояния
- `latent` как скрытый слой внутри crystall state
- `runtime lane` как единственный активный persistent context
- `hand` как player-side interface buffer, вне four-layer world model
- двухфазную модель хода
- `strong` как редкий премиальный режим, а не просто “чуть сильнее weak”
- targets как скрытые формы manifest chain
- grave как открытый ordered archive потерь
- grave shuffle как отдельную механику, а не базовое свойство зоны
- частичное наложение игровых зон на four-layer abstraction

## 1. Core Shape

`ProcessCards` — solitaire-карточный артефакт,
материализующий operator-топологию `ProcessLang` в играбельной форме.

Игра должна работать как closed system:

```text
122 cards
one deck
no external tokens
no mana
no HP
no creatures
no enemies
no allies
```

Игровое состояние состоит только из:

- положения карт
- порядка карт
- открытости / закрытости карт
- зон игры
- локальных topology checks
- локальных изменений правила
- history текущего хода

Критерий валидности эффекта:

```text
can this be executed with only the 122 cards and their zones/order/visibility?
```

Если нет — эффект вне core ontology.

## 2. Source Of Truth

Источник правды:

```text
stack-core/ProcessLang/canon.lua
```

Из canon берутся:

- operators
- glyphs
- adjacency
- inventory order
- trump edges

Yellowprint не должен быть отдельным источником истины по topology.

## 3. Deck

```text
122 cards = 100 minors + 22 trumps
```

### 3.1. Minors

Minor = directed operator pair:

```text
NUMBER[SUIT]
```

Direction matters:

```text
FLOW[LOGIC] != LOGIC[FLOW]
```

Numbering:

```text
 1 ▽ FLOW
 2 ☰ CONNECT
 3 ☷ DISSOLVE
 4 ☵ ENCODE
 5 ☳ CHOOSE
 6 ☴ OBSERVE
 7 ☲ CYCLE
 8 ☶ LOGIC
 9 ☱ RUNTIME
10 △ MANIFEST
```

### 3.2. Trumps

Trump = canon edge:

```text
EMERGENT(A, B)
```

There are 22 canon edges.
Each edge can become one trump.

In v3.5, trump mechanics are still intentionally deferred.

Reason:

```text
core must work before trumps are allowed to save it
```

Trumps should later behave as emergent edge events,
not as generic “special cards”.

## 4. Table Geometry

The table is not a physical domino path.

The table is an abstract state surface.

Core zones:

```text
targets
manifest chain
latent layer
runtime lane
grave
hand
deck
```

### 4.1. Targets

Targets are hidden completion forms.

Targets are not enemies.
Targets are not HP.
Targets are not simply “win cards”.

A target is a concealed state-pattern that the game may later:

- observe
- manifest
- satisfy
- align with the current chain

Strong direction:

```text
targets may behave like hidden manifest-chain forms
```

This means victory is not merely “draw the right card”,
but “assemble the chain into a valid final shape”.

### 4.2. Manifest Chain

The manifest chain is the main visible process line.

It is the current readable sequence of the game.

It is called a chain,
but should not be read as a physical domino geometry.

It is closer to:

```text
current abstract process state
```

### 4.3. Latent Layer

Latent cards are face-down table state.

They already belong to the table,
but are not fully manifest.

Latent is not a second hand.
Latent is not a token zone.
Latent is staged process potential inside the crystallized state of the table.

### 4.4. Runtime Lane

Runtime lane holds at most one card.

```text
runtime capacity = 1
```

If a new card enters runtime,
the previous runtime card moves to grave unless a card effect says otherwise.

Runtime does not accumulate buffs.
Runtime changes the active context.

This makes `☱` special without creating a board full of permanents.

### 4.5. Grave

Grave is the loss archive.

It stores:

- discarded cards
- dissolved cards
- replaced runtime cards
- resolved cards that left active state

Grave is not just trash.
Grave is not just recycling material.
Grave is visible consequence.

In v3.5 grave is:

```text
open
ordered
public
meaningful
```

Player may inspect grave freely.

Default law:

```text
you may know everything in grave
you may not change grave order unless an effect says so
```

This means:

- ordinary access to grave may allow choosing a card from grave
- removing a grave card does not automatically reorder the remaining grave
- relative order of remaining grave cards persists
- grave reorder is explicit power
- grave shuffle is explicit power

So grave is both:

- archive of losses
- temporal trace
- manipulable structure only under permission

### 4.6. Hand

Hand is not a world layer.

Hand is a player-side interface buffer.

It is not `chaos`,
because cards in hand are already addressed and available.

It is not `table`,
because cards in hand are not yet part of relation surface.

It is not `crystall`,
because cards in hand are not yet table-state form.

It is not `manifest`,
because cards in hand are not yet consequence or world-facing event.

Short reading:

```text
hand = interface buffer between player and closed economy
```

The hand is where the player can access possible interventions.
It is not itself an ontological layer of the game world.

## 5. Relations

Between two minor cards `A` and `B`,
the game preserves three relation types.

### 5.1. Weak Relation

Weak relation exists if at least one operator position matches:

```text
number_A == number_B
suit_A == suit_B
number_A == suit_B
suit_A == number_B
```

Weak relation allows placement or staging,
but should not generate large tempo by itself.

### 5.2. Strong Relation

Strong relation exists if canon adjacency validates the directed bridge:

```text
canon.is_adjacent(suit_A, number_B)
or
canon.is_adjacent(suit_B, number_A)
```

Strong relation means the move is topology-valid,
not merely symbol-compatible.

### 5.3. Mirror Relation

Mirror relation:

```text
number_A == suit_B
and
suit_A == number_B
```

Mirror remains a special structural case.

In MVP, mirror should probably not receive a special effect yet.
Its structural distinctness is already enough for early testing.

## 6. Turn Structure

v3.5 keeps two phases.

### Phase 1. Action

Player chooses one:

- place weak
- place strong
- discard
- pass

### Phase 2. Resolution Tail

Resolve only effects connected to the current action.

This is not a global trigger phase.
This is not a whole-table upkeep.
This is not a recursion engine.

Allowed:

- continuation from the played card
- linkage created by the played card
- local manifestation
- local runtime replacement
- narrow post-move effect

Forbidden by default:

- rereading the whole table
- unlimited cascades
- recursive chain explosion
- global trigger bureaucracy

Short law:

```text
one action -> one bounded tail
```

## 7. Move Types

### 7.1. Weak Move

Weak move is staging.

It exists to grow the field,
prepare future structure,
and place potential into the table.

Weak move should not be a small version of strong move by default.

Formula:

```text
weak = setup / staging / positioning / latent growth
```

### 7.2. Strong Move

Strong move is payoff.

It exists to advance the chain,
convert preparation into value,
or generate tempo.

Formula:

```text
strong = payoff / conversion / resolved advancement
```

Baseline direction:

```text
strong = choose draw 2 OR enhanced effect
```

In v3.5 this is not treated as a problem by default.

Reason:

```text
strong moves are rarer than weak moves
```

So the generic `draw 2` branch does not erase operator identity.
It creates a universal premium option for a rare action window.

The real tension becomes:

```text
convert rare strong into raw mass
or
convert rare strong into operator-specific force
```

### 7.3. Discard

Discard moves one card from hand to grave.

Baseline:

```text
discard draws 0
```

Reason:

```text
discard must not become free filtering
```

Discard should preserve topology pressure.

### 7.4. Pass

Pass is legal,
but should not become normal tempo.

If pass becomes common in playtest,
the hand economy or relation pressure is probably wrong.

## 8. Operator Families

These are not final card texts.
They are design families.

### ▽ FLOW

FLOW means continuation.

Not only draw.

Good effects:

- continue after placement
- shift state
- extend movement
- draw as flow, not currency
- carry current action forward

FLOW is especially natural in resolution tail.

### ☰ CONNECT

CONNECT means linkage.

Not allies.
Not auto-strong.
Not free power.

Good effects:

- bridge two structures
- turn weak into strong under a condition
- link latent to manifest
- validate unusual placement
- connect current action to another zone

CONNECT is also natural in resolution tail.

### ☷ DISSOLVE

DISSOLVE means structural removal.

Not combat removal.

Good effects:

- move active card to grave
- remove chain edge
- break stuck structure
- dissolve latent card
- free table from bad topology

### ☴ OBSERVE

OBSERVE means seeing hidden state.

Question:

```text
what is there?
```

Good effects:

- peek at target
- reveal target
- inspect latent card
- look at top of deck
- inspect hidden state without changing it
- inspect grave without modifying it

OBSERVE does not primarily reorder or store.

### ☵ ENCODE

ENCODE means structuring known state.

Question:

```text
how is known information stored?
```

Good effects:

- reorder known cards
- place known card into controlled position
- bury a known card
- cache a known card in deck/grave/table order
- transform revealed information into stable structure
- rarely intervene in grave order if explicitly allowed

ENCODE should not be the main peek operator.

### ☳ CHOOSE

CHOOSE means branch selection.

Good effects:

- choose one of several cards
- choose one of several paths
- choose one target
- choose one mode
- choose a grave card under permission
- select weak or strong interpretation

CHOOSE creates pressure without needing enemies.

### ☶ LOGIC

LOGIC means local rule interpretation.

Not global law for the whole game.
Not permanent bureaucracy.

Good effects:

- this weak counts as strong
- this mirror counts as valid
- swap number/suit for one check
- ignore one restriction for this resolution
- validate under alternate condition

LOGIC bends one check,
not the whole universe.

### ☲ CYCLE

CYCLE means loop, return, repeat, replacement.

Good effects:

- discard 1, draw 1
- return from grave
- repeat recent pattern
- replace hand card
- loop a small transition
- interact with grave as ordered history

CYCLE naturally interacts with grave and history.

### ☱ RUNTIME

RUNTIME means active context.

In v3.5, runtime lane has capacity 1.

Good effects:

- enter runtime lane
- replace current runtime
- maintain one persistent context
- keep a condition active while this card is runtime
- make later checks read through current runtime

Runtime is not a pile of buffs.
Runtime is the current environment.

### △ MANIFEST

MANIFEST means latent becomes visible and active.

It creates nothing from outside.

Formula:

```text
latent -> manifest
```

Good effects:

- turn latent card face-up
- reveal concealed table state
- bring hidden target into visible state
- move staged potential into manifest chain
- make existing potential active

MANIFEST is not token creation.

## 9. Critical Triangle

The central distinction:

```text
☴ OBSERVE  = learn hidden state
☵ ENCODE   = structure known state
△ MANIFEST = make latent state active
```

This triangle is one of the main reasons v3.5 works.

If these three collapse into the same effect,
the game loses its own ontology.

## 10. Layer Mapping

A productive current reading:

### 10.1. Chaos

```text
deck = chaos
```

Deck is undifferentiated potential.

### 10.2. Table

```text
targets + table layout = table
```

This includes:

- target placement
- zone grammar
- relation surface
- abstract board organization

### 10.3. Crystall

```text
manifest chain + latent layer = crystall
```

Why latent also belongs here:

```text
hidden does not mean unformed
```

Latent table state is already inside structure.
It is concealed crystallization, not raw chaos.

### 10.4. Manifest

```text
grave = manifest
```

Not because grave is glorious,
but because grave is consequence that already happened.

Grave is not potential.
Not staging.
Not active formation.

Grave is residue, trace, cost, and already-realized state.

Short reading:

```text
grave = manifest as residue
```

### 10.5. Runtime

Runtime mapping is not fully settled.

Current intuition:

```text
runtime = context holder touching table and crystall
```

It may remain a special slot that modifies how crystall state is read.

### 10.6. Hand

Hand remains outside the four-layer world model.

Current reading:

```text
hand = player-side interface buffer
```

It is the access pocket from which the player introduces interventions into the closed economy.

## 11. MVP Scope

MVP should test:

- closed economy
- manifest chain
- latent layer
- runtime lane capacity 1
- weak as staging
- strong as rare premium payoff
- two-phase turn
- bounded resolution tail
- targets as hidden completion forms
- ordered grave as open archive
- `☴ / ☵ / △` separation
- discard without free draw

MVP should not require:

- trump mechanics
- mirror special effects
- unique texts for every card
- global rule engines
- external components
- multi-card runtime board

## 12. Open Questions

1. Does weak placement always create latent state,
   or can weak also extend manifest chain with weak payoff?

2. When a latent card is manifested,
   does it resolve immediately,
   or only become eligible for later relation checks?

3. Is runtime lane entered only by `☱` cards,
   or can other cards enter runtime through `☱` effects?

4. Can targets be satisfied only by manifest chain,
   or may runtime and latent contribute indirectly?

5. How often may grave selection ignore depth
   before ordered grave loses practical meaning?

6. Which operators are allowed to grave-shuffle,
   and how expensive should that be?

7. How many latent cards can be attached to the table before memory tax becomes too high?

8. Should trumps be physically included in MVP as inert edge cards,
   or removed from the first playtest deck?

## 13. Short Formula

```text
ProcessCards = closed card economy for building valid process chains
```

More precise:

```text
ProcessCards = manifest-chain solitaire with latent state, one active runtime, and ordered grave residue
```

---

machines only. not for humans.
