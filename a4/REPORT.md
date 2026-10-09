# AP 2026 - Assignment 4

## Introduction:

The hand-in consists of a solution for all four tasks. The code builds without warnings. AI was used in the structuring and creation of the tests.

Some details of the implementation:

- `runEval'` now also returns the `State`, so that a `KvPutOp` can be seen by the rest of the program.
- `TransactionOp` in `runEvalIO'` copies the database to a temporary database with `withTempDB`, runs the transaction on the copy, and only copies it back if it succeeds. Nested transactions work the same way, since the inner one just copies the temporary database of the outer one.
- For Task 4 we only added one effect, `BreakOp Val`. `looping` is not an effect, but a function that goes through the computation and replaces a `BreakOp v` with `Pure v`. The interpreters only see a `BreakOp` when there is no loop around it, and then they fail with "Break outside loop".

The text had some ambiguities. `TryCatchOp` may behave differently in the two interpreters, and we have kept it that way (see question 1). A `Break` outside a loop is a normal error for us, so `TryCatch` can catch it. The text does not say if a `Break` inside a `Transaction` should commit or roll back. In our solution it commits, since a break is not a failure.

We think Tasks 1-3 are functionally correct. All examples from the assignment text give the expected result in both interpreters, also the two nested transaction examples, which we checked by hand since they are not in the test suite. The 55 tests (31 pure, 24 IO) cover `TryCatch`, the key-value store, the missing key prompt, transactions and break.

On our Windows machine 44 of the 55 tests pass. The 11 that fail are exactly the IO tests that use `captureIO`. They fail with an `hDuplicateTo` exception inside `captureIO` in `APL.Util`, before our interpreter is run. We think this is because pipes are duplex handles on Windows. We ran the same 11 cases by hand with piped input and got the expected results, so we expect them to pass on Linux, but we could not run them there.

Task 4 is only partly correct. A `Break` directly in the loop body works, but a `Break` inside a `TryCatch` or `Transaction` only leaves that block, and the loop continues:

```haskell
ForLoop ("acc", CstInt 0) ("i", CstInt 10)
  (Add (TryCatch (Break (CstInt 42)) (CstInt 99)) (CstInt 1))
```

This should give 42, but it gives 43 after running all 10 iterations. The reason is that `looping` also replaces the `BreakOp` inside the payload of `TryCatchOp`, so the try-block just succeeds with 42. Our tests "Break inside TryCatch exits loop", "Break inside transaction exits loop" and "Break in TryCatch fallback exits loop" pass anyway, but only because the loop body gives 42 in every iteration.

With more time we would add a `LoopOp (EvalM Val) (Val -> a)` effect and handle it in both interpreters like `TryCatchOp`, so a break is passed on like an error until it reaches the loop. We would also move the rest of the program out of `withTempDB` in `runEvalIO'`, since the temporary database is now first deleted when the whole program is done.

## Questions and Answers:

### 1. Consider interpreting a `TryCatchOp m1 m2 k` effect where `m1` fails after performing some key-value store effects.

**(a) Is there a difference between your pure interpreter and your IO-based interpreter in terms of whether the key-value store effects that `m1` performed before it failed are visible when interpreting `m2`? If so, why?**

Yes, there is a difference. In the pure interpreter the effects are not visible in `m2`. In the IO-based interpreter they are visible.

In `runEval'` the state is passed around as a parameter. When `v1` fails, its state `s1` is thrown away, and `v2` is run with the state `s` from before the `TryCatchOp`:

```haskell
runEval' r s (Free (TryCatchOp v1 v2 k)) =
  let (msg1, s1, r1) = runEval' r s v1
   in case r1 of
    ...
    Left _ ->
      let (msg2, s2, r2) = runEval' r s v2
```

In `runEvalIO'` there is no state to throw away. A `KvPutOp` writes directly to the database file, and `v2` is run on the same file, so the writes from `v1` are still there:

```haskell
r1 <- runEvalIO' r db v1
case r1 of
  ...
  Left _ -> do
    r2 <- runEvalIO' r db v2
```

For example, `catch (evalKvPut (ValInt 0) (ValInt 1) >> failure "x") (evalKvGet (ValInt 0))` gives `Left "Invalid key: ValInt 0"` with `runEval` and `Right (ValInt 1)` with `runEvalIO`. We do not have a test for this, but we have checked it by hand.

**(b) Suppose you've implemented your interpreters such that the key-value store effects that `m1` performed before it failed are always visible when interpreting `m2`. Without changing the interpreters, is it possible to have different behavior where the key-value store effects in `m1` are invisible in `m2`? If so, how? If not, why not?**

Yes, it is possible. We can wrap `m1` in a transaction, so the program is `catch (transaction m1) m2`, or `TryCatch (Transaction e1) e2` in APL. This changes the program and not the interpreters.

When `m1` fails, the `TransactionOp` rolls the key-value store back to how it was before `m1`, and it still propagates the error. The `TryCatchOp` then runs `m2` on the rolled back store, so the effects of `m1` are invisible.

The pure test "Transaction rolls back bad put" does exactly this. For `runEvalIO` we checked it by hand: the example from (a) gives `Right (ValInt 1)`, but with `transaction` around `m1` we are asked for a replacement, since the key is gone.

### 2. Why is `TransactionOp` not defined as follows?

```haskell
data EvalOp a
  = ...
  | TransactionOp (EvalM ()) a
```

**What problems might arise with this definition? Would it make `TransactionOp` completely useless?**

With this definition the transaction cannot give a result back. The payload has type `EvalM ()`, so its value is thrown away. The continuation is just `a` and not `Val -> a`, so the rest of the program cannot depend on the result of the transaction.

This is a problem since `Transaction e` must evaluate to the value of `e`, and `transaction` has the type `EvalM Val -> EvalM Val`. For example, `Transaction (CstInt 5)` could not evaluate to 5. We would have to return some dummy value.

It would not be completely useless. The rollback does not need the result, so it still works for transactions that are only used for their effects. An example is `Let "_" (Transaction goodPut) get0`, where the result is ignored anyway. The result could also be saved in the key-value store inside the transaction and read afterwards, but that takes up a key, and it does not work for a `ValFun` in `runEvalIO`.

### 3. Why is `TryCatchOp` not defined as follows?

```haskell
data EvalOp a
  = ...
  | TryCatchOp a a
```

**What problems might arise with this definition?**

In `Free EvalOp a` the `a` in an effect is the rest of the program. So with `TryCatchOp a a` the two branches are not just the two blocks. They also contain everything that comes after the try-catch, since `>>=` uses `fmap` and puts the continuation into both:

```haskell
fmap f (TryCatchOp m1 m2) = TryCatchOp (f m1) (f m2)
```

The problem is that the interpreter cannot see where the try-block ends. It can only run the first branch to the end of the program and, if anything fails, run the second. Then an error after the try-catch is caught too, and the code after the try-catch is run twice. For example:

```haskell
Let "x" (TryCatch (CstInt 0) (CstInt 1)) (Div (CstInt 10) (Var "x"))
```

This should fail with "Division by zero", since the try-block succeeds with 0. With this definition the division error would be caught, and the program would give 10. Prints after the try-catch could also happen twice.

With the real definition `m1` and `m2` have the type `EvalM Val` and are not touched by `fmap`. Only `k` is the rest of the program, so the interpreter knows exactly what is inside the try-block.
