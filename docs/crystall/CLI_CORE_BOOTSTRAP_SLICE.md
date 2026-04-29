# CLI Core Bootstrap Slice

Статус:

```text
canonical crystall slice
```

Этот документ фиксирует
первый extraction-pass
для headless logic core.

## 1. Goal

Не переписать всю игру сразу,
а завести:

- headless game state
- setup logic
- zone snapshot
- CLI runner

без повреждения текущего LOVE2D shell.

## 2. Scope

Этот slice вводит только:

1. core state modules
2. card/deck bootstrap
3. setup routine
4. board closure check
5. CLI snapshot runner

## 3. Not in scope

Пока не вытаскиваем:

- animation queue
- rendering
- input
- individual turn effects
- operator payloads
- trump payloads

## 4. Deliverable

Первый usable результат:

```text
lua cli.lua snapshot
```

должен уметь:

- собрать state
- выполнить setup
- вывести manifest / latent / targets / hand / flow / grave

## 5. Why this slice matters

Это первый шаг,
после которого логика
перестаёт быть полностью запертой в `main.lua`.
