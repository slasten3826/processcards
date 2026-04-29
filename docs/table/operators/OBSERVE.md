# OBSERVE

Symbol:

```text
☴
```

Статус:

```text
canonical operator law
aligned with hidden / known / revealed model
aligned with play-zone execution shell
```

## 1. Core identity

`☴` now reads through the current information-state model:

```text
hidden -> known
```

It is no longer useful to describe `☴`
as vague “look at hidden card” language only.

Short formula:

```text
☴ = choose one hidden card on board and make it known
```

## 2. What it is not

`☴` is not:

- reveal by default
- draw
- discard
- removal
- free broad search

## 3. Execution position

`☴` no longer resolves as abstract text detached from the played card.

Current runtime shell is:

```text
hand -> play
pending operator choice
choose ☴
resolve ☴ while the card remains in play
then play -> grave
```

So `☴` is a real `play-zone` payload,
not a free-floating inspection permission.

## 4. Current runtime law

If `☴` is the chosen operator effect:

1. choose one legal hidden card on board
2. that card becomes:

```text
known
```

It does **not** become `revealed` by default.

That means:

- card identity is known
- card may remain face-down on the table
- current visual branch should show ghost identity over the back

## 5. Target class

`☴` is defined by information class first,
not by one special zone.

That means its target class is:

```text
hidden card on board
```

So `☴` is not restricted to only one concealed structure,
unless a later law says otherwise.

Current intended examples include:

- hidden card in `latent`
- hidden card in `targets`
- hidden topdeck, if topdeck is currently a legal hidden board-object

## 6. Trump consequence

At the current stage,
`☴` only upgrades information state:

```text
hidden -> known
```

It does not by itself imply mandatory public reveal.

Any stronger trump-on-known consequence
should be treated as a later runtime branch
until explicitly promoted into current code and law.

## 7. Pair law directions

Example pair directions:

- `☴☳` — choose which hidden card to observe
- `☴△` — observe, then manifest under pair-specific conditions
- `☴☵` — observe, then reorder or encode within allowed scope
- `☴☶` — observe while ignoring one normal observe restriction
- `☴☱` — install observe as runtime-form behavior

## 8. Physical execution law

Observe must stay cardboard-playable.

That means:

- player may privately inspect one physical hidden card
- card position must remain recoverable
- observation cannot rely on invisible engine memory
- if digital prototype shows ghost identity,
  that overlay must represent real knowledge, not fake engine clairvoyance

Current visual direction is fixed in:

- [../../crystall/KNOWN_VISUALIZATION_SLICE.md](../../crystall/KNOWN_VISUALIZATION_SLICE.md)

## 9. Restrictions

- observe does not by itself move the card
- observe does not by itself reveal the card to everyone
- observe scope is `hidden card on board` by default
- observe does not by itself trigger a second zone change unless another law says so

## 10. Open questions

- whether topdeck counts as ordinary observe target by default
- whether some mixed pairs should escalate known directly into revealed
- whether later current canon should make some trump behavior trigger on `known`

## 11. Short formula

```text
☴ OBSERVE = choose one hidden card on board
make it known
without mandatory reveal
```
