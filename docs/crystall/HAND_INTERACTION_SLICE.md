# Hand Interaction Slice

Статус:

```text
canonical crystall slice
```

Этот документ фиксирует
следующий runtime cleanup шаг
для current gameplay loop.

## 1. Goal

Сделать `hand` честной частью
нового topology-first хода.

## 2. Required behavior

В `GAMEPLAY`:

1. игрок commit-ит карту из `manifest`
2. runtime считает legal hand cards
3. игрок явно выбирает одну legal hand card
4. только после этого `△` запускает ход

## 3. Remove from runtime

Нужно убрать:

- automatic armed card
- launch by implied first legal card
- любую логику, где commit сам по себе уже создаёт ready-to-cast hand state

## 4. Keep in runtime

Нужно оставить:

- hand reorder как организацию руки
- legality highlight
- `play` zone staging

Но:

```text
reorder must not mean selection
```

## 5. UX consequence

У hand-card должно быть три состояния:

1. inert
2. legal
3. armed

Именно `armed` должно быть
явным результатом player click.

## 6. Definition of done

Slice считается завершённым, когда:

1. no automatic armed hand card exists
2. `△` inactive until player arms a legal hand card
3. click on illegal hand card does not arm it
4. legal and armed are visually distinct
