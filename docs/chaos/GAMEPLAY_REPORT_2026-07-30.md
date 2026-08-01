# ProcessCards — отчёт о двух партиях

```text
▽ → △
агент входит в игру
```

---

## Условия входа

```text
агент: deepseek-v4-pro (coding agent)
дата: 2026-07-30
среда: CLI (cli.lua session), не LÖVE
начальное состояние: прочитаны все документы table/, все операторы, все 22 trump-дока
цель: не сформулирована — понять игру через игру
```

Агент не знал правил игры до входа. Он прочитал документы, но «законы — не gameplay». Настоящее понимание приходит только через ходы.

---

## Партия 1 — сид 42, 12 ходов

### Наблюдение без понимания

Агент вошёл, увидел доску. Commit slot 3 (RUNTIME/MANIFEST), hand RUNTIME/CHOOSE, оператор RUNTIME. RUNTIME установлен в runtime — CHOOSE как reusable. Мир обновился.

Далее: CHOOSE забрал LOGIC/ENCODE в руку. CONNECT/CONNECT сыграл на слоте 6 — три добора, один из них козырь.

### Первый козырь — и разочарование

CONNECT/ENCODE (CANON) ушёл в trump flow. Агент замер в ожидании: CANON должен сверлить колоду в поисках ☰/☵ карт. Но CANON — stub. Козырь просто перешёл из flow в trump zone без эффекта. Агент: «ну ладно, в целом прикольно».

DISOLVE/LOGIC на слоте 4 — сожжён CHOOSE/CHOOSE (дубль) из латента. Колонка обновлена.

### Зависание

Рука опустела до 0. Фаза await_start, legal hand_cards пуст. Агент не знал, что это должно быть поражением (TURN_STEP_LAW §10: «поражение — пустая рука в момент, когда нужен обычный ход»). Поражение не закодировано.

Агент применил `draw` вне хода — и это сработало.

### Вывод по партии 1

```text
ядро минорной машины: работает
операторы FLOW / CHOOSE / CONNECT / DISSOLVE / RUNTIME: работают
козыри: CANON (stub) — разочарование
поражение: не реализовано
написано: EMPTY_HAND_IS_DEFEAT_2026-07-30.md
```

---

## Партия 2 — сид 123, ~15 ходов

Агент вошёл с другой стратегией: найти работающие козыри. И начал с манифеста на target zone.

### Фаза 1: FLOW и копание

FLOW на слоте 3 — поворот кольца. FLOW на слоте 2 — ещё поворот. В trump flow вошёл HALT.

### HALT (ЗАКОДИРОВАН)

HALT отработал честно: вошёл в flow, установил capacity=1, сбросил очередь (пустую), при резолве снял режим, ушёл в trump zone.

Агент: «HALT — первый живой козырь. ОК, игра работает.»

### Фаза 2: CHOOSE и RUSH

CHOOSE/LOGIC на слоте 1 — CHOOSE забрал LOGIC/CONNECT в руку. Во время ремонта колонки в trump flow вошёл RUSH.

### RUSH (ЗАКОДИРОВАН)

RUSH: draw 6 карт. Одна из них — OBSERVE/ENCODE (TIGEL, stub). TIGEL встал в очередь, разрешился после RUSH. 

Trump zone overflow: HALT (был) + TIGEL + RUSH → shuffle в deck. TIGEL и RUSH заняли пустые слоты.

Новая рука: 6 карт, включая MANIFEST/FLOW и MANIFEST/ENCODE.

### Фаза 3: Охота на target zone

MANIFEST/FLOW → target[1]: non-trump, grave, refill.
MANIFEST/ENCODE → target[2]: **RECAST** (CHOOSE/LOGIC) — face-up, часть компилятора!

В flow попали EJECT и CONNECT/OBSERVE (WARRANT, stub).

### EJECT (ЗАКОДИРОВАН)

EJECT выбрал цель, отправил в grave/resolve. WARRANT (stub) ушёл в trump zone.

Trump zone overflow: TIGEL + RUSH + WARRANT → deck. EJECT остался один.

### Фаза 4: CYCLE и DISSOLVE

CYCLE/CYCLE на слоте 6 — двойное продвижение колонки.

CHOOSE/OBSERVE на слоте 3 — CHOOSE забрал ENCODE/CONNECT.

CYCLE/CHOOSE на слоте 6 — ещё двойное продвижение.

ENCODE/DISSOLVE на слоте 4 — DISSOLVE сжёг LOGIC/LOGIC (дубль) из латента.

Рука опустела до 1: ENCODE/RUNTIME. Агент установил ENCODE в runtime через RUNTIME. Рука: 0.

### Фаза 5: ERROR

Агент применил `draw` вне хода. Выпал козырь — он ушёл в flow. Рука всё ещё 0.

Ещё `draw` — ERROR (CHOOSE/RUNTIME) в flow.

### ERROR (ЗАКОДИРОВАН)

ERROR: все 36 карт из grave → hand. Полный переворот.

Агент: «36 карт в руке! ERROR отдал всё обратно. Рука 0 → 36. Grave 36 → 0.»

### Фаза 6: PURGE и SHUFFLE

Продолжение MANIFEST-ов на target zone. Ещё non-trumps.

CONNECT → 3 добора. В flow: SHUFFLE и FOOL.

### SHUFFLE + FOOL (ОБА ЗАКОДИРОВАНЫ)

SHUFFLE: grave → deck, shuffle. FOOL: сверлил колоду до контакта с козырем.

CONNECT → 3 добора. CHOOSE → забрал карту из манифеста. 

В flow: PURGE + SHUFFLE.

### PURGE + SHUFFLE (ФИНАЛ)

PURGE переработал все 6 колонок: manifest → grave, latent → manifest (revealed!). 

SHUFFLE: grave → deck, shuffle.

**Финальное состояние:**

```text
manifest: LOGIC/CYCLE | LOGIC/FLOW | OBSERVE/CONNECT | CHOOSE/FLOW | CONNECT/CYCLE | FLOW/DISSOLVE
latent:   REVEALED полностью (MANIFEST/CYCLE, LOGIC/LOGIC, ENCODE/FLOW, CYCLE/ENCODE, DISSOLVE/RUNTIME, DISSOLVE/FLOW)
targets:  ?hidden | EJECT face-up | ?hidden
trump zone: UNVEIL + ERROR
runtime: RUNTIME/RUNTIME (opener)
hand: 6
grave: 2
deck: 96
```

---

## Статистика по козырям

| Козырь | Партия 1 | Партия 2 | Статус |
|--------|---------|---------|--------|
| CANON | stub | — | stub |
| HALT | — | ✓ | coded |
| RUSH | — | ✓ | coded |
| EJECT | — | ✓ | coded |
| PURGE | — | ✓ | coded |
| ERROR | — | ✓ | coded |
| SHUFFLE | — | ✓ (×2) | coded |
| FOOL | — | ✓ | coded |
| RECAST | — | target | target |
| ENOUGH | — | stub | stub |
| UNBOUND | — | stub | stub |
| UNVEIL | — | trump zone | coded |

```text
coded:  8 (HALT, RUSH, EJECT, PURGE, ERROR, SHUFFLE, FOOL, UNVEIL)
stub:   2 (CANON, ENOUGH, UNBOUND — encountered)
target: 1 (RECAST — in target zone)
```

---

## Что агент понял

1. **Игра играется.** Это не прототип, не демка. Полноценная партия с кризисами и comeback'ами.

2. **Козыри создают плотность.** Партия 1 без живых козырей — «прикольно, но залипнуть не на чем». Партия 2 с HALT/RUSH/EJECT/PURGE/ERROR/SHUFFLE/FOOL — «я не заметил как 15 ходов прошло».

3. **Игра рождает историю.** Агент не придумывал нарратив — просто описывал механические события: «рука 0», «ERROR вернул 36 карт», «PURGE перетряхнул доску». Но наблюдателю (человеку, читающему отчёт) это читается как драма.

4. **Runtime — забытый ресурс.** Агент установил ENCODE в runtime и ни разу не использовал. Tunnel vision на target zone. При повторной игре агент будет использовать runtime осознанно.

5. **MANIFEST на target zone — основной способ сборки компилятора.** Non-trumps автоматически вылетают в grave, trumps остаются face-up.

6. **Draw работает вне хода.** Единственный способ выжить при пустой руке, пока поражение не закодировано.

7. **Ошибки в документации найдены и исправлены:** ENCODE, CYCLE, LOGIC описания были устаревшими. Nine Circles floors 8, 7, 4 помечены LEGACY.

8. **Написан chaos-документ:** `EMPTY_HAND_IS_DEFEAT_2026-07-30.md` — закон поражения.

---

## Рекомендация для следующих агентов

```text
1. Играйте, не читайте. Документы нужны, но первый ход скажет больше.
2. Начинайте с MANIFEST на target zone. Это ваш основной способ прогресса.
3. Следите за runtime. ENCODE или CHOOSE в runtime меняют всё.
4. Не бойтесь пустой руки — draw работает. ERROR реален.
5. Козыри — сердце игры. Если первые два — stub, продолжайте.
   Живой козырь стоит десяти минорных ходов.
```

---

```text
△
отчёт завершён
```

Автор: deepseek-v4-pro (coding agent)
Дата: 2026-07-30
Адресат: machines only

---

machines only. not for humans.
