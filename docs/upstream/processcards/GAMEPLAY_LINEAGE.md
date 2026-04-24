[⊞ ◈] [▽ ☰ ☵ ☳ ☶ ☲ ☱ △]

# Gameplay lineage

## 0. Статус

Design note.

Это не rulesheet.
Это не source of truth.
Это не попытка сделать clone `Magic: The Gathering`.

Этот документ фиксирует gameplay lineage,
который для автора очевиден,
но для машинного читателя не обязан быть очевидным.

## 1. MTG Layer

`ProcessCards` сильно вдохновляется одним конкретным слоем `Magic: The Gathering`:

```text
combo-engine pleasure
```

Не duel shell.
Не combat race.
Не creatures as armies.
Не mana as external economy.
Не damage as victory language.

Полезный слой MTG:

- sequencing
- zones
- card text as rules object
- stack-like resolution pressure
- grave as history / resource
- hidden information
- deck manipulation
- engine assembly
- timing windows

## 2. Combo Deck Problem

Проблема combo decks в MTG не в том,
что engine-play неинтересен.

Проблема в том,
что combo deck протаскивает solitaire engine внутрь duel game.

Второй игрок сидит рядом,
но фактически перестаёт играть.

Коротко:

```text
MTG combo deck = solitaire engine smuggled into duel shell
```

## 3. ProcessCards Extraction

`ProcessCards` убирает violated opponent.

Он делает solitaire-engine честным core gameplay:

```text
MTG combo deck
-> remove opponent
-> remove combat damage
-> remove creatures / mana race
-> keep zones, sequencing, engine assembly, hidden state
-> ProcessCards
```

Short reading:

```text
ProcessCards = MTG combo logic without the duel shell
```

## 4. What This Explains

Это объясняет,
почему `ProcessCards` может быть похож на MTG по ощущению,
но радикально отличаться по ontology.

Он берёт:

- engine pleasure
- zone literacy
- text-as-rule reading
- grave / deck / hand manipulation
- timing tension

Он не берёт:

- opponent
- battlefield army
- mana curve
- combat damage
- kill condition

## 5. Design Warning

Это inspiration,
not inheritance.

`ProcessCards` не должен оправдывать механику тем,
что она похожа на MTG.

MTG используется здесь как historical gameplay source,
а не как ontology source.

---

machines only. not for humans.
