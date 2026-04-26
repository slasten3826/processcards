# Turn Law V2

Статус:

```text
canonical table law
current turn-law branch
```

Этот документ фиксирует текущую каноническую модель хода,
которая появилась из плейтеста прототипа
и теперь считается active table canon.

Старый закон хода остаётся в:

- [HAND_AND_PLAY_LAW.md](./HAND_AND_PLAY_LAW.md)

как предыдущая replacement-model ветка.

## 1. Why this exists

Плейтест показал важный сигнал:

карта из `hand`,
которая просто встаёт в `manifest`,
ощущается слабее,
чем карта из `manifest`,
которая visibly уходит в `grave`.

Из этого родилась другая интуиция:

```text
hand card should act on the world
not become part of the world
```

## 2. Core shift

Старая модель:

```text
hand card replaces manifest card
```

Новая модель:

```text
hand card is cast at manifest
hand card does not remain in manifest
```

То есть:

- `manifest / latent` = active world strip
- `hand` = action reservoir

Рука даёт не board-objects,
а operation packets.

## 3. World-strip reading

В этой модели `manifest chain`
надо мыслить не как место,
куда игрок выкладывает свои карты.

А как:

```text
active open layer of the world
```

`latent` при этом остаётся скрытым подпирающим слоем мира.

См.:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)

## 4. Weak move draft

Ранний weak sketch теперь уступил место более жёсткой sequence-ветке.

Текущую рабочую последовательность хода
см. в:

- [TURN_SEQUENCE_LAW_V2.md](./TURN_SEQUENCE_LAW_V2.md)

Старый weak-черновик сохраняется здесь только как historical step:

1. игрок берёт 1 карту из `hand`
2. игрок целит 1 карту в открытом `manifest`
3. hand-card effect резолвится
4. hand-card уходит в `grave`
5. manifest-card уходит в `grave`
6. `latent[i]` поднимается
7. `deck` пополняет `latent[i]`

Коротко:

```text
the branch has moved from weak-sketch
to a stricter turn-sequence model
```

## 5. Strong move draft

Strong move в этой ветке
больше не должен мыслиться
как “чуть более сильная версия того же placement”.

Предварительная интуиция такая:

```text
strong = pair declaration from hand
applied against manifest
```

То есть strong move,
скорее всего,
должен играться через 2 hand-cards,
а не через “one card enters manifest and becomes strong there”.

Точный strong law пока не зафиксирован.

## 6. Grave consequence

Так как и played hand-card,
и affected manifest-card
уходят в `grave`,
grave в этой модели становится ещё сильнее
не просто discard pile,
а:

```text
history of opened and spent layers
```

См.:

- [GRAVE_LAW.md](./GRAVE_LAW.md)

## 7. Chain consequence

В этой ветке особенно важно,
что `manifest / latent` остаются самостоятельной машиной.

`hand` не подпирает `manifest`.

`manifest` восстанавливается только через:

```text
latent -> manifest
deck -> latent
```

См.:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)
- [RESOLUTION_ORDER_LAW.md](./RESOLUTION_ORDER_LAW.md)

## 8. Operator consequence

Эта ветка пока не пересобирает все operator laws.

Но она уже меняет общий режим чтения:

- некоторые масти будут читаться чище как operations on the world
- некоторые масти, особенно `CONNECT` и `RUNTIME`,
  почти наверняка придётся переосмыслить сильнее других

То есть:

```text
turn law changes first
operator reinterpretation follows later
```

## 9. Runtime consequence

Эта ветка существует не в отрыве от кода.

Она опирается на уже собранную модульность прототипа:

- zones already exist
- chain repair already exists
- grave path already exists
- animation queue already exists

Поэтому смена turn-law
не требует тотального переписывания runtime-shell.

Это и есть один из признаков,
что модульность прототипа была собрана правильно.

## 10. Development consequence

С этого места проект входит в более жёсткую gameplay-фазу:

```text
think
prototype
playtest
keep or revert
```

То есть допустим такой цикл:

1. рождается новая mechanical idea
2. она фиксируется документом
3. она кодится модульно
4. она плейтестится
5. если работает — остаётся
6. если не работает — откатывается без разрушения всей машины

Этот документ и существует именно для такой фазы.

## 11. What is still unresolved

Этот draft пока не решает:

- точный strong move law
- какие operator families меняются сильнее всего
- как именно `observe`, `runtime`, `connect`, `logic` перестраиваются в новой модели

## 12. Short formula

```text
hand cards are cast at the world
not installed into the world
the exact move sequence is specified separately
in TURN_SEQUENCE_LAW_V2
```
