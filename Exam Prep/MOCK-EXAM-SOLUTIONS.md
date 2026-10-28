# Mock exam B: solutions

Do not open this before you have finished `MOCK-EXAM.md`. ✔ = checked in GHC (A1 on the group hand-in, A4 on the group hand-in, week 7 on the compendium solution code). The rest are reasoned from the code; the notes section is given for each.

## 1 General
**1.1** (§G1) More boilerplate: every effect needs a constructor, a `Functor` case and a case in **every** interpreter. It is slower, because the program is built as a tree and then walked. It is less direct, since you cannot just call an `IO` function.

**1.2** (§A5) `classify` (like `label`/`tabulate`) only **reports** how often a condition held. `cover pct cond lbl` also reports it, and with `checkCoverage` the property **fails** if the condition holds in fewer than `pct`% of the tests (statistically). So it fails when the generator is too weak.

**1.3** (§G3)
```
E  ::= F E'
E' ::= "*" F E' | "/" F E' | ε
F  ::= int | "(" E ")"
```
```haskell
pE = do x <- pF; pE' x
pE' x = choice [ do lString "*"; y <- pF; pE' (Mul x y)
               , do lString "/"; y <- pF; pE' (Div x y)
               , pure x ]
```
`2*3/4` → `pE' 2` → `pE' (Mul 2 3)` → `Div (Mul 2 3) 4`.

## 2.1 A1
**2.1.1** (§A1) ✔
1. `Left "Unknown variable: y"`: `Let` is eager, so `e1` is evaluated even though `x` is unused.
2. `Left "Non-boolean conditional."`: the condition must be a boolean. The else-branch (`1/0`) is never evaluated.
3. `Right (ValInt 8)`: `p` goes 1 → 2 → 4 → 8 over 3 iterations.

**2.1.2** (§A1, G4) ✔ `Right (ValInt 5)`. The lambda's body uses `x` from its closure (`x = 5`). The `let x = 7` only scopes over the *argument* expression. **Dynamic scoping gives 5 too**: at the call site (the `Apply`) `x` is still 5, because the inner `let` has ended.

## 2.2 A2
**2.2.1** (§A2) `(["a: 1","b: 0"], Left "Division by zero")`. Both prints happen before the division fails, and this `EvalM` keeps the state on error.

**2.2.2** (§A2) `([], Left "Division by zero")`. With `Either Error (a, State)` an error carries no state, so all output so far is lost (rolled back).

**2.2.3** (§A2)
```haskell
EvalM m >>= f = EvalM $ \env s ->
  case m env s of
    Left err -> Left err
    Right (x, s') -> let EvalM m' = f x in m' env s'
```

## 2.3 A3
**2.3.1** (§A3) A name that **starts with** a keyword is split. For example, `iffy + 1` would be read as the keyword `if` followed by the variable `fy`, so `pLExp` commits to an `if` expression and the valid program is rejected. Similarly `getx` could become `get x` wherever the keyword alternative is tried before `lVName`.

**2.3.2** (§A3) Allow at most one `==`: `Exp0 ::= Exp1 [ "==" Exp1 ]`. In the parser, use `choice [do lString "=="; y <- pExp1; pure (Eql x y), pure x]` with **no recursive `chain`**. Then `a == b == c` leaves `== c` unconsumed and `eof` fails.

## 2.4 A4
**2.4.1** (§A4 ★Q1) ✔ Pure: `Left "Invalid key: ValInt 0"`. The `put` happened inside the failing try-block, and the pure interpreter runs the handler with the state from **before** the try, so the put is lost. IO: `Right (ValInt 1)`. The put was already written to the **database file**, which is not rolled back.

**2.4.2** (§A4) ✔ `Left "Invalid key: ValInt 0"`.
- The inner transaction fails (`die` is unknown), so it rolls back `put 0 2` and **rethrows**.
- The outer transaction therefore also fails, rolls back `put 0 1`, and rethrows.
- `TryCatch` then runs `get 0` on the empty store.

(Compare: if the inner transaction is wrapped in its own `TryCatch … true`, the outer one succeeds and `get 0` gives 1 ✔.)

**2.4.3** (§A4) `KvGetOp` produces a value, so the rest of the program must receive it: a continuation `Val -> a`. `KvPutOp` produces nothing, so it only needs the next program `a`. On `ErrorOp e`, `fmap` returns `ErrorOp e` unchanged. There is no continuation, so `>>=` cannot attach anything, and the program **stops there** (it propagates as the final result).

## 2.5 A5
**2.5.1** (§A5) The recursion never shrinks. Half the time `genExp` makes an `Add` with two recursive calls, so the expected number of children is 1 and the terms can be huge or never finish. Fix: `sized`, halve the size in recursive calls, and only make leaves at size 0. Also, `arbitrary :: Gen Integer` gives **negative** numbers, which the printer/parser cannot round-trip (APL has no negative literals). Restrict them, e.g. `choose (0, 5)`.

**2.5.2** (§A5 ★Q3) Fix the **printer** (implementation). The expression is a legal program, and the parser correctly reads `1 - 2 - 3` as `(1-2)-3`, because `-` is left-associative. The printer loses the grouping, so it must parenthesise the right operand: `1 - (2 - 3)`. The group's printer does this ✔: `(1 - (2 - 3))`.

## 2.6 A6
**2.6.1** (§A6 ★Q4)
- (a) The job never reports back. When its deadline passes, the central timeout check marks it `JobDone DoneTimeout` and replies, so the client gets `Just DoneTimeout`, although the job really died.
- (b) Nothing ever marks it done, so the client **blocks forever**.

In both cases SPC still believes the worker exists, so jobs given to it later are lost.

**2.6.2** (§G10, §A6) `jobStatus` must return information, so the client has to wait for the reply (`requestReply`). `jobCancel` returns nothing, so there is no reason to block the client, and it is sent with `sendTo`. The cost: when `jobCancel` returns, the cancel may not have been handled yet.

## 2.7 Week 7
**2.7.1** (§W7) ✔ Pure: **1**. `||` runs the left side first, it succeeds, and the right side never runs. Simulated: **2**. Both sides are stepped in the same round (left, then right) and both finish immediately, so `put 0 1` and then `put 0 2` both happen. The left one wins the tie, but the loser's `put` is **not undone**.

**2.7.2** (§W7) ✔ Pure: **3** (left first, and it succeeds). Simulated: **20**, because the right loop needs only 2 steps (one per iteration) against 3. Concurrent: **3 or 20**, depending on which SPC job finishes first. It is nondeterministic.

**2.7.3** (§W7)
- Pure: `Left "Invalid key: ValInt 1"`, since `get` on a missing key is an error.
- Simulated: the right side finishes, but `get 1` stays blocked forever (nobody puts key 1), so `runEval` **loops forever**.
- Concurrent: the `get` job blocks in KVDB, the `put` job finishes, and the interpreter waits for the `get` job. Every thread is now blocked, so the runtime throws **"thread blocked indefinitely in an MVar operation"**.

**2.7.4** (§W7) `f x.1` → `Apply (Var "f") (Project (Var "x") 1)`, because projection binds tighter than application. `a && b || c && d` → `OneOf (BothOf a b) (BothOf c d)`, because `&&` binds tighter than `||`.
