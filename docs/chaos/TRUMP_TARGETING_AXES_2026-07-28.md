# Две оси прицеливания козырей

Статус:

```text
слой: chaos
дата: 2026-07-28
вид: наблюдение + предложение формы объявления
авторитет: не контракт
код изменён: нет
```

## 1. С чего началось

Я перечислял, какие козыри убирают со стола открытые карты, и записал в этот список `GATE`. Автор поправил:

> манифест слой — это не совсем ревиалд карты, там не ревиалд карт быть не может

И это не придирка к слову. Я смешал две разные вещи, которые сейчас почти совпадают, а после наших же правок разойдутся.

## 2. Оси

```text
по состоянию   hidden / known / revealed
по зоне        deck / hand / manifest / latent / targets / grave /
               trump flow / trump zone / runtime / play / topdeck
```

Множества пересекаются, но не равны.

```text
"все revealed карты"   состояние, живёт в нескольких зонах
"манифестный слой"     зона, в которой не бывает не-revealed
```

Сейчас различие почти незаметно, потому что открытые карты в основном и лежат в манифесте. Разойдётся оно на **открытой латентной карте**: она `revealed`, но не в манифесте. А латент начнёт открываться как раз после наших изменений — `MANIFEST` фиксирует карту прямо в слоте, `UNVEIL` раскрывает латентный ряд.

То есть эффект, написанный как «все открытые», и эффект, написанный как «манифестный слой», сегодня дадут одинаковый результат, а завтра разный. Ошибка проявится не при написании, а через несколько недель, в чужой партии.

## 3. Почему это важно именно сейчас

Десять козырей из двадцати двух ещё не написаны. Если прицел не объявлен явно, при их написании кто-нибудь напишет «revealed» там, где имелось в виду «манифест», и наоборот. Это ровно тот способ, которым козыри, вводившиеся по одному, уже однажды разошлись — тогда по режиму разрешения, теперь по прицелу.

## 4. Предлагаемая форма объявления

В дескрипторе козыря прицел объявляется **двумя полями**, а не одним.

```lua
PURGE = {
    edge = {"LOGIC", "MANIFEST"},
    targets_state = "revealed",
    zones = {"manifest", "latent", "topdeck", "targets"},
    pick = "all",
}

GATE = {
    edge = {"LOGIC", "RUNTIME"},
    zones = {"manifest"},
    pick = "all_but_matching",
}

EJECT = {
    edge = {"FLOW", "DISSOLVE"},
    zones = {"trump", "targets", "latent", "manifest", "grave",
             "hand", "runtime", "play", "topdeck"},
    pick = 1,
}
```

`pick` отделяет **подметающие** козыри от **точечных**. Это различие уже есть по смыслу: `EJECT` и `WARRANT` требуют прицела, поэтому они хирургия, а не контрмера чему-либо массовому.

## 5. Черновая карта двадцати двух

Источник: одностраничные чтения из `PROCESSCARDS_GAME_OVERVIEW §11` плюс код для двенадцати реализованных.

`код` = прочитано в `trump.lua`. `док` = только замысел, в коде отсутствует.

```text
имя        ребро              зоны                          состояние      pick   ист.
FOOL       FLOW–CONNECT       deck -> grave                 раскрывает     all    код
EJECT      FLOW–DISSOLVE      почти все                     любое          1      код
ORACLE     FLOW–OBSERVE       deck, hand                    не-revealed    6->1   код
GRANT      CONNECT–DISSOLVE   manifest (доп. колонка)       -              -      док
WARRANT    CONNECT–OBSERVE    ? (любая разрешённая)         -              1      док
CANON      CONNECT–ENCODE     deck -> hand                  раскрывает     цепь   док
UNBOUND    DISSOLVE–OBSERVE   targets                       -              1      док
RUSH       DISSOLVE–CHOOSE    deck -> hand                  раскрывает     6      код
TIGEL      OBSERVE–ENCODE     trump zone                    -              ёмкость док
SWAP       OBSERVE–CHOOSE     где лежат козыри              -              2      док
ENOUGH     OBSERVE–RUNTIME    manifest, latent (чтение)     revealed       all    док
MAXIMIZE   ENCODE–CHOOSE      hand -> manifest              -              цепь   док
REQUIEM    ENCODE–RUNTIME     поле -> runtime               hidden         1      док
SHUFFLE    ENCODE–CYCLE       grave -> deck                 -              all    код
ERROR      CHOOSE–RUNTIME     grave -> hand                 -              all    код
RECAST     CHOOSE–LOGIC       manifest, latent, hand,
                              deck, grave, trump zone       -              all    код
RESET      LOGIC–CYCLE        hand -> grave, deck -> hand   -              all    код
GATE       LOGIC–RUNTIME      manifest                      -              all    док
PURGE      LOGIC–MANIFEST     manifest, latent, topdeck,
                              targets                       revealed       all    код
REPEAT     CYCLE–RUNTIME      -                             -              мета   код
UNVEIL     CYCLE–MANIFEST     targets, latent, topdeck      только
                                                            не-revealed    all    код
HALT       RUNTIME–MANIFEST   trump flow                    -              ёмкость код
```

Таблица черновая. Строки с пометкой `док` не проверены кодом и могут разойтись с замыслом — их надо сверять с отдельными `trumps/*.md`, а не принимать отсюда.

## 6. Что видно из карты

**Подметающих, работающих по состоянию `revealed`, ровно один: `PURGE`.** И он не написан. Значит у якорения через `△ MANIFEST` сейчас нет широкого противовеса, а точечные `EJECT` и `WARRANT` тратят на одну карту целый козырь.

Практическое следствие: замер силы `MANIFEST` до реализации `PURGE` покажет его сильнее, чем он будет.

**`UNVEIL` не убирает открытое, а создаёт его.** В коде `unveil_target_slot` выходит сразу, если карта уже `revealed`. Он по построению работает только с не-раскрытыми. Я ошибочно относил его к убирающим.

**Два козыря меняют ёмкость, и оба на разных зонах:** `HALT` сужает `trump flow`, `TIGEL` расширяет `trump zone`. Это отдельный род, не прицел.

**`REPEAT` вообще вне осей** — он мета, его прицел это чужой козырь.

## 7. Открытое

```text
1. WARRANT: "любая разрешённая карта" — где граница разрешённого,
   в доке не сказано.
2. SWAP: меняет местами два козыря "на столе" — targets и trump zone,
   или шире.
3. GRANT: временная колонка — это изменение размера зоны manifest,
   то есть, возможно, третий род наряду с ёмкостью.
4. Нужен ли axis для "читает, но не двигает" (ENOUGH только считает).
```

---

Наблюдение о смешении зоны и состояния: slasten.
Запись и черновая карта: Opus 5 (claude-opus-5), 2026-07-28.

---

machines only. not for humans.
