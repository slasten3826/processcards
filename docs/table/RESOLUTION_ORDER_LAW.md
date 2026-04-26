# Resolution Order Law

Статус:

```text
canonical table law
```

Этот документ фиксирует базовый порядок резолва
для текущей chain-machine поверхности.

## 1. Why this law exists

Без порядка резолва один и тот же эффект
может собрать разные столы в зависимости от того,
когда именно чинятся пустые слоты.

Этот документ нужен, чтобы:

- не чинить `manifest` слишком рано
- не путать primary effect с structural repair
- не подменять effect-state автоматическим refill

## 2. Resolution layers

На текущем слое резолв делится на два базовых класса:

### A. Primary effect

Это то, что непосредственно сделал эффект:

- remove
- move
- replace
- reveal
- discard
- install
- и другие прямые действия

### B. Structural repair

Это уже не сам effect payload,
а приведение chain surface обратно в валидное состояние:

- repair `manifest` through `latent`
- repair `latent` through `deck`

## 3. Core precedence

Базовый порядок такой:

1. primary effect resolves
2. only after that chain surface repair resolves

Коротко:

```text
effect first
repair second
```

## 4. Manifest hole order

Если effect создал пустоту в `manifest[i]`,
то repair той же колонки идёт так:

1. `latent[i]` moves up to `manifest[i]`
2. that card is revealed if needed
3. `deck` refills `latent[i]` face-down

Но это происходит только после того,
как сам primary effect закончил свою работу.

## 5. Latent hole order

Если effect создал пустоту только в `latent[i]`,
то repair идёт так:

1. `deck` refills `latent[i]` face-down

И снова:
не во время самого effect-step,
а после него.

## 6. Why repair is not immediate

Repair не должен срабатывать
как микрореакция после каждого отдельного remove/move.

Иначе получится ложный стол:

- effect ещё не закончил работать
- а board уже автоматически подставил новые карты

Это запрещено.

Правильный закон:

```text
the effect creates the hole
the effect finishes
then the board repairs the hole
```

## 7. Current scope

Этот документ пока фиксирует только:

- relation between primary effect and chain repair
- порядок repair внутри колонки

Для новой turn-sequence ветки действует ещё одно уточнение:

```text
world update may still precede the played hand-card effect
if the move law explicitly says so
```

То есть:

- `RESOLUTION_ORDER_LAW` остаётся общим законом
- а конкретный порядок внутри topology-first move
  задаётся отдельно в `TURN_SEQUENCE_LAW_V2`

Он пока не решает:

- later trump post-resolution order
- duplicate cleanup order
- more advanced competing replacement effects

## 8. Relationship to chain law

Этот документ нужно читать вместе с:

- [CHAIN_SURFACE_LAW.md](./CHAIN_SURFACE_LAW.md)

Разделение такое:

- `CHAIN_SURFACE_LAW` = что именно чинится и чем
- `RESOLUTION_ORDER_LAW` = когда именно это чинится
- `TURN_SEQUENCE_LAW_V2` = как topology-first move собирает
  world update и hand-card effect в один конкретный sequence

## 9. Short formula

```text
primary effect resolves first
chain repair resolves second
manifest is repaired through latent
latent is repaired through deck
```
