# CHOOSE

Symbol:

```text
☳
```

Статус:

```text
canonical operator law
current turn-law branch
```

## 1. Core identity

`☳` больше не читается как просто слабый оператор выбора
для old weak/strong chassis.

В текущей новой ветке его лучший кандидат такой:

```text
☳ = redirect the source column of latent promotion
```

То есть `☳` не просто “выбери цель эффекта”,
а:

```text
choose where the next visible world layer comes from
```

Short formula:

```text
☳ = repair redirection / promotion source selection
```

## 2. What it is not

`☳` is not:

- draw
- reveal
- generic removal
- abstract menu without board consequence

## 3. Current playtest law

Если карта с `☳` сыграна в колонку `i`,
то обычный repair:

```text
latent[i] -> manifest[i]
```

может быть переопределён.

Игрок выбирает другую колонку `j`,
и тогда происходит:

```text
latent[j] -> manifest[i]
deck -> latent[j]
```

При этом:

- `manifest[j]` не двигается
- переносится только hidden source card
- освобождённый `manifest[i]` получает latent-card из другой колонки

Коротко:

```text
☳ chooses which latent column feeds the consumed manifest slot
```

## 4. Why this fits the new move model

Этот оператор хорошо садится на новую ветку,
потому что:

- ход уже consume-ит один `manifest`-узел;
- latent promotion уже и так есть;
- `☳` не создаёт новую сущность,
  а вмешивается в уже существующую фазу world update.

То есть `☳` теперь меняет не абстрактный target,
а:

```text
which hidden world layer becomes visible next
```

## 5. Physical execution law

Choose must point to visible legal options.

That means:

- player chooses one visible column
- the chosen column must have a latent card
- no invisible branch list is required

## 6. Restrictions

- `☳` should not become free wildcard text
- it should not move whole manifest columns by itself
- it should redirect latent promotion, not rewrite the whole board

## 7. Open questions

- whether `☳` should always allow any other column,
  or only adjacent / legal topology-related columns
- whether `☳☳` should amplify this redirection or duplicate it
- whether later some mixed pairs should choose other phases, not only repair source

## 8. Legacy relation

Older readings of `☳` as weak-fragile selector
or null weak modifier should now be treated as legacy-branch thinking.

## 9. Short formula

```text
☳ CHOOSE = choose which latent column feeds the next manifest repair
```
