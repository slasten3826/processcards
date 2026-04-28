# Gameplay Dedev Plan

Статус:

```text
canonical crystall cleanup plan
```

Этот документ фиксирует следующий cleanup шаг runtime:

```text
remove dev sandbox behavior
from active gameplay mode
```

## 1. Core decision

`GAMEPLAY` больше не должен жить
как свободная structural sandbox.

Подсветка legality (`commit -> legal hand cards`)
теперь не просто hint-layer.

Это:

```text
the active move mechanic
```

## 2. What must stop being active gameplay behavior

Из `GAMEPLAY` нужно убрать:

- свободный drag/drop карт по зонам
- ручное перемещение карты в любую зону через shortcuts
- ручной `flip` любой карты как обычный gameplay action
- ручной `discard` любой карты как обычный gameplay action
- старую manual sandbox grammar

Коротко:

```text
free structural manipulation is no longer gameplay
```

## 3. What becomes the real gameplay loop

В `GAMEPLAY` должен остаться один живой move contour:

1. choose one open `manifest` card
2. commit it
3. compute legal hand cards
4. choose one legal hand card
5. press `△`
6. run the turn sequence

То есть:

```text
hint becomes law
```

## 4. What may remain as debug capability

Допустимо сохранить debug tools,
но только как:

- `DEV` mode behavior
- hidden debug hotkeys
- explicit debug-only controls

Они не должны мешаться
с current gameplay reading.

## 5. Why this matters

Пока в active gameplay остаётся старая sandbox grammar,
runtime одновременно поддерживает две разные игры:

1. current topology-first machine
2. old free manipulation playground

Это ломает:

- плейтест
- UX clarity
- trust in legality rules

## 6. Definition of done

Cleanup считается завершённым, когда:

1. `GAMEPLAY` больше не позволяет свободный zone manipulation
2. legality highlight стал обязательной частью move loop
3. `△` стал единственным обычным способом запускать ход
4. old dev controls остались только в `DEV`, если вообще нужны

## 7. Short formula

```text
remove sandbox from gameplay
keep only the move law
commit -> legal hand card -> △ -> turn sequence
```
