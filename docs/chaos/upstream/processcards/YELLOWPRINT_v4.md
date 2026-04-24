# ProcessCards :: YELLOWPRINT v4

[⊞ ◈] [☰ ☴ ☵ ☳ ☶ ☲ ☱ △]

## Статус

Yellowprint v4.

Это не финальная спецификация.
Это не полный rulesheet.
Это не set file для печати карт.

Это board-loop crystallization после следующего раунда обсуждения.

v4 фиксирует уже конкретную форму стола и добавляет target/trump ecology:

- `manifest chain` остаётся одной сущностью
- физически chain выражается через `5 columns × 2 layers`
- верхний / передний слой = visible manifest
- нижний / задний слой = hidden latent
- каждая колонка = локальный slot
- весь набор пяти колонок = единый chain
- `observe` = peek without reveal
- hidden cards можно знать, не раскрывая их миру
- освобождение manifest slot поднимает latent card из этой же колонки
- пустой latent slot пополняется из deck face-down
- `connect` получает роль local board surgery / relation trigger
- `targets` работают как compiler одной victory grammar
- `trumps` читаются как events, not stable states
- dormant hidden trumps создают delayed escalation
- grave остаётся open ordered archive
- fixed hidden row делает memory pressure ограниченным

## 1. Core Invariant

`ProcessCards` остаётся closed card system.

```text
122 cards
one fixed deck
no creatures
no enemies
no allies
no mana / energy
no HP
no external tokens
```

Допустимые ресурсы игры:

- положение карт
- порядок карт
- открытость / закрытость карт
- зоны
- relation checks
- local rule-bending
- history текущего действия
- bounded hidden knowledge

Если эффект требует внешнего объекта,
внешнего маркера
или дополнительной материальной сущности,
он вне core ontology.

## 2. Source Of Truth

Источник правды:

```text
stack-core/ProcessLang/canon.lua
```

Canon supplies:

- operator inventory
- adjacency
- edge inventory for trumps
- directionality
- global topology constraints

Yellowprint не заменяет canon.
Он только materializes game form around it.

## 3. Deck Composition

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

Number inventory:

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

Minor reading:

```text
minor = state
```

A minor may sit in hand,
sit hidden,
wait on the board,
or behave as structure.

### 3.2. Trumps

Trump = canon edge:

```text
EMERGENT(A, B)
```

v4 still does not finalize every trump text.

But v4 does fix trump ontology:

```text
trump = event
```

A trump should not behave like a normal card
that passively waits in hidden state or in hand.

A trump wants to happen.

Short law:

```text
minors are state
trumps are events
```

Reason:

```text
board loop must become real before emergent cards are allowed to distort it
```

Trumps should later behave as emergent edge events,
not as generic power cards.

## 4. Board Model

The table is now a structured board:

```text
5 columns × 2 layers
```

### 4.1. Columns

There are always five board columns.

Each column contains:

- one manifest slot
- one latent slot

So the board core is:

```text
5 manifest slots
5 latent slots
```

### 4.2. Layers

Manifest row:

- visible
- active
- playable
- part of the current readable chain

Latent row:

- hidden
- already belongs to the table
- not yet manifest
- staged under / behind a specific manifest slot

### 4.3. One Chain, Not Ten Cards

Even though the board is physically slot-based,
the `manifest chain` remains one entity.

It is not five separate piles.
It is not five independent lanes.
It is one process line projected onto five slots.

Short reading:

```text
5 local columns
1 global chain
```

### 4.4. Two Axes Of Play

v4 introduces two orthogonal dimensions:

- vertical logic = within one column (`manifest <-> latent`)
- horizontal logic = across the chain (`slot <-> slot`)

This gives cards natural scopes:

- operate on one column
- operate across the row / chain
- translate from vertical to horizontal
- translate from horizontal to vertical

## 5. Slot Laws

### 5.1. Manifest Removal

If a manifest card leaves play from a given column,
the latent card from the same column rises into manifest.

Not any hidden card.
Not chosen globally by default.
Only the latent card belonging to that slot.

### 5.2. Latent Refill

If a latent slot becomes empty,
it is refilled from deck face-down.

This preserves the ongoing flow:

```text
deck -> latent -> manifest -> grave
```

### 5.3. Locality

Slot replacement is local by default.

This is one of the main anti-chaos stabilizers of the game.

Without locality,
the hidden layer becomes a generic pool.

With locality,
the hidden row becomes structured potential.

### 5.4. Empty Board Condition

The game does not normally permit the board core
to collapse below `5 manifest + 5 latent` for long.

Any temporary hole should be resolved by effect
or by board maintenance.

This is not yet a final maintenance rule.
It is a board-shape invariant for playtest.

## 6. Zones

Full state:

```text
deck
hand
targets
manifest row
latent row
runtime lane
grave
```

### 6.1. Deck

Deck is undifferentiated potential.

Default flow:

```text
deck -> latent
```

Deck feeds latent by default,
not directly the board surface.

### 6.2. Hand

Hand is not chaos.

Hand is table,
but not world-side table.

Current reading:

```text
hand = player-side table of available interventions
```

Cards in hand are:

- addressed
- available
- discrete
- selectable
- player-facing
- not yet board-state

Hand belongs to `⊞ table`
because it is an addressable option surface.

It is not `◈ crystall`,
because cards in hand are not yet part of the board crystall.

It is not `▲ manifest`,
because cards in hand are not yet consequence or world-facing event.

### 6.3. Targets

Targets are hidden completion forms.

Targets are not enemies.
Targets are not score cards.
Targets are not three separate goals.

Strong v4 reading:

```text
targets are hidden final shapes the chain may satisfy
```

More precise:

```text
targets compile one victory grammar
```

### 6.4. Runtime Lane

Runtime lane holds at most one card.

```text
runtime capacity = 1
```

Runtime remains a separate context slot,
not part of the 5×2 core board.

Runtime is not a pile of buffs.
Runtime is the current environment / context holder.

### 6.5. Grave

Grave remains:

```text
open
ordered
public
meaningful
```

Player may inspect grave freely.

Default law:

- choosing a card from grave may be allowed by effects
- removing a grave card does not automatically reorder the remaining grave
- grave order persists unless an effect changes it
- grave shuffle exists as a separate mechanic

This means grave is simultaneously:

- loss archive
- residue of play
- ordered history
- manipulable structure under permission

Short reading:

```text
grave = manifest as residue
```

## 7. Target Compiler

This is one of the main v4 additions.

### 7.1. Core Claim

Targets are not:

```text
goal A
goal B
goal C
```

Targets are:

```text
slot 1
slot 2
slot 3
```

Together,
they compile into one final victory condition.

Short reading:

```text
victory is not selected
victory is composed
```

### 7.2. Why Position Matters

The three target slots are not interchangeable.

The card in slot 1 does not mean the same thing
as the same card in slot 2 or slot 3.

This means:

- target order matters
- target location matters
- target manipulation matters

Moving a target card is not cosmetic.
It changes the grammar of victory.

### 7.3. Productive Structure

The exact slot meanings are still open,
but the strongest current direction is:

- slot 1 defines scope
- slot 2 defines pattern
- slot 3 defines resolution / modifier

#### Slot 1 :: Scope

Determines where the game should read the victory condition.

Possible readings:

- manifest row
- columns
- relation between columns
- grave
- runtime
- mixed local/global slice

#### Slot 2 :: Pattern

Determines what structure must be found.

Possible readings:

- pair
- chain
- mirror
- adjacency form
- density pattern
- local topology shape

#### Slot 3 :: Resolution / Modifier

Determines how the pattern must finalize.

Possible readings:

- simultaneous
- after manifest
- in locked state
- with one slot empty / filled
- through dissolve
- through runtime influence

These are examples,
not final rules.

The important law:

```text
each target slot contributes a different grammatical role
```

### 7.4. Mutable While Hidden, Fixed When Manifest

This is the key target law.

While a target card is hidden:

- it may be inspected
- it may be reordered
- it may be structurally manipulated by allowed effects

Once a target card is manifested:

- it is public
- it occupies its revealed slot-role
- it is fixed in place
- it no longer behaves like a freely mutable hidden target fragment

This creates a victory rhythm:

```text
hidden target = plastic future
manifest target = committed future
```

### 7.5. Board Formation And Victory Formation

The player is not only building the board.

The player is also gradually crystallizing the future definition of success.

So the game has two simultaneous processes:

- board formation
- victory formation

These are not separate systems.
They are intertwined.

## 8. Information Discipline

v4 sharply distinguishes:

- hidden
- known
- revealed
- manifest

These are not the same thing.

### 8.1. Hidden

A latent card may be hidden from the board-state,
but not necessarily forever unknown to the player.

### 8.2. Known

Known means the player has seen a hidden card,
but the public board has not changed.

Known is player knowledge,
not manifest state.

### 8.3. Revealed

Revealed means the card is now public information.

Revealed does not always mean fully active,
unless the effect says it becomes manifest.

### 8.4. Manifest

Manifest means visible and active in board-state.

## 9. OBSERVE / ENCODE / MANIFEST Triangle

### 9.1. OBSERVE

`☴ OBSERVE` has a strong default identity:

```text
peek without reveal
```

Meaning:

- look at a hidden card
- learn it
- return it face-down
- do not manifest it
- do not change public state by default

This is not a weak version of `△`.
This is a different ontological action.

### 9.2. ENCODE

`☵ ENCODE` becomes stronger under this board model.

Once something is known,
it can be:

- ordered
- buried
- swapped
- cached
- placed with intention

Flow:

```text
observe -> know
encode -> structure
manifest -> activate
```

### 9.3. MANIFEST

`△ MANIFEST` remains:

```text
make latent state visible and active
```

Not just “know it”.

Actually shift it into public active state.

### 9.4. Memory Pressure

Because there are only five latent slots,
hidden memory remains bounded.

v4 accepts that a player may forget a hidden card
and may need to spend `observe` again.

This is not automatically bad design.

Bounded memory pressure can be part of the game’s value,
as long as the hidden row remains small and stable.

## 10. Hidden Manipulation

Hidden cards should not be freely rearrangeable by default.

Reason:

```text
hidden state without knowledge is not the same as structured hidden state
```

Productive default:

```text
you usually observe first,
then manipulate with another effect
```

Examples:

- `observe` sees a hidden card
- later `encode` swaps or repositions hidden cards
- `choose` selects which hidden column to affect
- `manifest` pulls one hidden card up into action

This does not mean every hidden manipulation must literally require a prior observed flag.

It means the game identity should preserve the causal distinction:

```text
unknown hidden state != known hidden state
```

## 11. Trump Ontology

### 11.1. Main Distinction

Minors and trumps should not behave the same way.

Strong reading:

```text
minor = state
trump = event
```

A minor may:

- sit in hand
- sit hidden
- wait on the board
- behave as structure

A trump should not be comfortable doing that.
A trump wants to happen.

### 11.2. Trump Detection Law

Productive law:

```text
a trump resolves at the first moment it becomes known
```

“Becomes known” may include:

- drawn into hand
- seen by observe
- exposed from latent
- exposed from target structure
- otherwise explicitly revealed by effect

This means a trump is not just strong.
It is unstable.

### 11.3. Why This Matters

This sharply separates `OBSERVE` and `MANIFEST`.

For ordinary hidden cards:

```text
observe = peek without reveal
```

For trumps:

```text
observe = dangerous contact
```

because knowledge itself triggers resolution.

This makes trumps feel like anomalies,
not like secret resources.

## 12. Hidden Trump Procedure

This section proposes a clean default procedure.

It is not final law.
It is a proposed default for testing trump ontology.

### 12.1. If A Hidden Card Is Observed And It Is A Trump

Sequence:

1. the hidden slot is immediately replenished from deck
2. the observed trump is resolved
3. the resolved trump returns to live circulation

This may mean shuffling back into deck,
or a softer localized return rule.

The exact return procedure remains an implementation question.

### 12.2. Why Replace First

Replacement first matters.

It means the trump does not leave an unresolved hole
inside the hidden architecture.

The structure is maintained,
then the anomaly resolves.

This preserves board continuity.

### 12.3. Why Return To Circulation

The trump should not:

- go to grave as normal residue
- remain sitting revealed as a passive object
- disappear forever by default

The trump should re-enter circulation.

This keeps trumps event-like rather than archival.

Short reading:

```text
minor leaves history behind
trump returns to circulation
```

## 13. Dormant Trumps

### 13.1. Definition

A dormant trump is a trump currently parked
inside a hidden slot.

Examples:

- latent row trump
- hidden target trump

It is not active yet.
It is not in public state.
But it is not absent.

It is delayed instability.

### 13.2. Consequence

Dormant trumps change probability indirectly.

If some trumps are parked in hidden slots,
then fewer trumps remain in the live deck.

So the deck becomes calmer,
but the hidden layer becomes more dangerous.

This produces two risk surfaces:

```text
deck-risk
hidden-risk
```

### 13.3. Illustrative Model

This is an illustrative model,
not final rules math.

Let:

```text
H = number of dormant trumps in hidden slots
```

Then:

```text
live trumps = total trumps - H
```

This means early live-deck turbulence may be lower than naive estimate,
but only because some trumps are sleeping elsewhere.

### 13.4. Waking Dormant Trumps

Once a dormant trump is detected:

- it resolves
- it leaves hidden state
- it re-enters circulation

Dormant trumps do not reduce total instability.
They only delay it.

Short reading:

```text
dormant trumps postpone chaos
they do not remove it
```

## 14. Escalation Ecology

### 14.1. Base Principle

If trumps return to circulation after resolving,
while minors increasingly leave the live deck as residue,
then the density of trumps in the live deck rises over time.

This gives the game a natural escalation curve.

### 14.2. Productive Interpretation

Early game:

- some trumps may be dormant
- live deck may be calmer
- encode and planning are stronger

Mid game:

- dormant trumps begin to wake
- deck turbulence rises
- hidden inspection becomes more dangerous

Late game:

- trumps circulate through a smaller live deck
- encode becomes less stable
- event pressure rises
- board control becomes harder

This is not an artificial timer.
It is structural escalation.

### 14.3. Important Warning

If trumps reshuffle the entire deck too often,
they may erase too much deck-order play
and weaken `ENCODE` beyond usefulness.

So v4 does not assert:

```text
constant deck reset is always good
```

It asserts:

```text
trumps should interfere with stable planning
but not necessarily erase the entire deck-structure layer every time
```

The ontology is solid even if the precise return-to-deck procedure
is later softened or localized.

## 15. Relation System

Between minors, the game preserves:

- weak relation
- strong relation
- mirror relation

### 15.1. Weak Relation

One or more operator positions match:

```text
number_A == number_B
suit_A == suit_B
number_A == suit_B
suit_A == number_B
```

Weak relation is valid for staging,
not automatically for big payoff.

### 15.2. Strong Relation

Canon adjacency validates a directed bridge:

```text
canon.is_adjacent(suit_A, number_B)
or
canon.is_adjacent(suit_B, number_A)
```

### 15.3. Mirror Relation

```text
number_A == suit_B
and
suit_A == number_B
```

Mirror remains structurally special,
but does not yet require a separate MVP rule.

## 16. CONNECT Reframed

`☰ CONNECT` is no longer best read as a generic bridge.

Under v4 it becomes:

```text
local board surgery
relation-trigger
structural linkage
```

### 16.1. CONNECT On Board

A `connect` card may interact with two manifest cards on the board.

It checks some relation criterion between them,
then triggers an event.

Possible criterion families:

- shared feature
- weak pair
- strong adjacency pair
- mirror relation
- poker-like structural pattern
- local chain pattern across multiple visible slots

Important:
“poker” here does not mean literal poker ranks.

It means recognizable multi-card relation shapes.

### 16.2. CONNECT As Rewire

After a valid connect,
the board may do things like:

- draw
- discard
- remove one connected manifest card
- shift one relation reading
- pull latent upward through local removal
- reconfigure local board state

So `connect` is not just “cards become linked”.
It can actively transform board topology.

## 17. Turn Structure

v4 keeps the two-phase turn.

### Phase 1. Action

Choose one:

- place weak
- place strong
- discard
- pass

### Phase 2. Resolution Tail

Resolve only what belongs to that action.

Short law:

```text
one action -> one bounded tail
```

No whole-table reread by default.

## 18. Move Economy

### 18.1. Weak

Weak = staging.

Now especially meaningful because it can:

- place into the board
- affect a local column
- prepare future connect
- set up latent / manifest timing
- maintain chain pressure

### 18.2. Strong

Strong = rare premium action window.

v4 keeps the direction:

```text
strong = draw 2 OR enhanced effect
```

This is acceptable because strong moves are rarer than weak moves.

The decision is:

```text
take raw mass
or
cash out operator specificity
```

### 18.3. Discard

```text
discard draws 0
```

Discard should not become free filter.

### 18.4. Pass

Legal,
but not healthy as normal tempo.

## 19. Layer Mapping

Current productive reading:

### 19.1. Chaos

```text
deck = chaos
```

Deck is undifferentiated potential.

### 19.2. Table

```text
hand = player-side table
targets = hidden objective table
board layout + slot grammar = world-side table
```

Hand is table because it is an addressable option surface.

Targets are table because they define victory grammar.

Board layout is table because it defines relation surface and slot grammar.

### 19.3. Crystall

```text
manifest row + latent row = crystall
```

Why latent also belongs here:

```text
hidden does not mean unformed
```

Latent row is already structurally embedded in the board.
It is concealed crystallization.

### 19.4. Manifest

```text
grave = manifest as residue
```

### 19.5. Runtime

Runtime remains a special context-holder touching table and crystall,
but not fully settled in the layer model.

## 20. Operator Families Under The New Board

### ▽ FLOW

Good at continuation,
especially when a local board event should carry into a bounded tail.

### ☰ CONNECT

Now central for relation-triggered rewiring.

### ☷ DISSOLVE

Good at removing manifest cards,
breaking local structure,
or sending pieces to grave.

### ☴ OBSERVE

Now sharply defined by hidden-slot access without reveal.

For trumps,
it becomes risky contact with event-state.

### ☵ ENCODE

Now stronger because the board has stable hidden addresses
and slot-local structure.

### ☳ CHOOSE

Can select:

- which column
- which pair of columns
- which relation mode
- which hidden slot to affect
- which grave card under permission
- whether to risk waking hidden turbulence now or later

### ☶ LOGIC

Can alter local validation rules for one board check.

### ☲ CYCLE

Can loop hand / grave / local board transitions.

Also participates in trump escalation if trumps return to live circulation.

### ☱ RUNTIME

Holds one active context affecting later checks.

### △ MANIFEST

Pulls latent into visible active state,
commits hidden target structure,
or otherwise turns concealed board state into public chain-state.

If it touches a trump,
it becomes forced escalation rather than slow commitment.

## 21. MVP v4

MVP should test:

- `5 columns × 2 layers`
- one global chain across five visible slots
- local latent replacement
- deck feeding latent
- open ordered grave
- observe = peek without reveal
- hidden memory bounded to five slots
- connect as board-surgery operator
- target compiler as victory grammar
- strong as rare premium action
- two-phase turn
- one bounded resolution tail

Can be staged after initial MVP:

- full trump gameplay
- dormant hidden trump recursion
- full mirror subsystem
- full runtime ecosystem
- final target resolution text
- full hidden manipulation grammar
- all 100 card texts

Important:

```text
target compiler can enter MVP thinking early
full trump ecology may be staged later
```

But trump ontology should be preserved now,
so future trump rules do not drift into generic power cards.

## 22. Open Questions

1. Should the latent card sit physically under the manifest card,
   above it,
   or slightly offset behind it for best readability?

2. Can a card affect both horizontal and vertical logic at once,
   or should most cards commit to one axis per effect?

3. How many `connect` effects should be allowed to remove manifest cards,
   before the board feels too volatile?

4. Must hidden manipulation require prior observation mechanically,
   or is that only a design heuristic?

5. Should players be forbidden from external note-taking,
   to preserve the value of `observe`?

6. Do targets read only the manifest row,
   or can they care about hidden structure as well?

7. Can `manifest` pull from latent directly without a slot being emptied first,
   or only through explicit card effects?

8. How often may grave selection ignore depth
   before grave order stops mattering?

9. Does runtime interact with one slot,
   the whole manifest row,
   or relation checks globally?

10. Is trump return-to-circulation global shuffle,
    localized insertion,
    bottom placement,
    or another procedure?

11. How often can trump events disturb deck order
    before `ENCODE` loses its reason to exist?

12. Are target slot roles fixed as scope / pattern / resolution,
    or should those roles emerge from playtest?

## 23. Short Formula

```text
ProcessCards = slot-based manifest-chain solitaire with bounded hidden state
```

More precise:

```text
5-column chain machine where latent rises locally,
observe peeks without reveal,
targets compile victory,
and trumps are delayed events.
```

Even shorter:

```text
minors are state
trumps are events
targets are compiler
```

---

machines only. not for humans.
