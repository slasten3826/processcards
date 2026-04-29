# Trump Class Runtime Slice

Статус:

```text
canonical crystall slice
```

Этот документ фиксирует
следующий кодовый слой current prototype:

```text
introduce trump as a runtime class
without per-trump effects
```

## 1. Core decision

Сейчас в runtime не нужно вводить
конкретные payload rules отдельных козырей.

Не вводим пока:

- `FOOL`
- `SHUFFLE`
- `UNVEIL`
- `RESET`
- `HALT`
- `RECAST`
- и любые другие individual trump effects

Сейчас вводится только:

```text
trump card type infrastructure
```

## 2. What this slice must add

Runtime должен начать отличать:

- `minor`
- `trump`

как два разных класса поведения.

Для `trump` текущий минимальный контур такой:

1. card becomes `revealed`
2. if not in `targets`, it enters `trump flow`
3. it waits for full board closure
4. it waits for explicit player confirm
5. stub resolution sends it to `trump zone`

## 3. What this slice must not add

Этот slice не должен пока кодировать:

- special trump payloads
- per-trump world effects
- named trump exceptions
- full ecology details
- `HALT` behavior
- chain-close subtleties
- parent/child trump causality

Коротко:

```text
class first
content later
```

## 4. Why this order is correct

Если сейчас сразу кодировать
individual trumps,
runtime начнёт тащить в себя
специфику карт
до того, как появится
общая труба их существования.

Поэтому сначала нужен:

- `trump flow`
- `pending trump event`
- `confirm`
- `trump zone`

И только потом уже
конкретные законы каждой карты.

## 5. Required runtime behavior

Минимально этот слой должен дать:

### a. Trump recognition

Runtime знает, что revealed `trump`
не продолжает жить как ordinary minor result.

### b. Trump diversion

Revealed trump outside `targets`
уходит в `trump flow`.

### c. Board closure gate

Trump не резолвится,
пока board не закрыт полностью.

### d. Manual confirm

Trump event не проматывается автоматически.

Нужен explicit confirm.

### e. Stub finish

После confirm trump
проходит stub resolution
и попадает в `trump zone`.

## 6. Relationship to later work

После завершения этого slice
можно уже по одному вводить:

1. individual trump effects
2. more precise trump ecology
3. deeper draw/open-entry interactions

Но не раньше.

## 7. Short formula

```text
Right now we are not implementing trump meanings.
We are implementing trump existence in runtime.
Trump becomes a distinct class with its own flow, pause, confirm, and residue.
```
