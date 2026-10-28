# Question bank

Practice questions in the style of `week7/exam-dummy.pdf`: short answers, reasoning about code you have seen. Write your answers in `answers/dayN.md`. Check them against **`EXAM-NOTES.md`**; each section below says which notes section holds the answers.

- **★ = an official question** from an assignment's report section. **(D) = in the dummy exam.** Both are **Must** questions: the exam reuses their ideas. Do these first.
- Unmarked questions are variants in the same style. Do them if time remains. They train the most important exam skill: adapting a model answer to a new expression.
- Unless a question says otherwise, "the handout" means the code handout of that assignment (compendium pages are in `EXAM-NOTES.md` §0).
- For "what does X evaluate to", give **the value plus a one-line reason**.

| Section | Study day | Answers in `EXAM-NOTES.md` |
|---|---|---|
| §0 General | 1 (and 3) | §G |
| §1 A1 | 1 | §A1 |
| §2 A2 | 2 | §A2 |
| §3 A3 | 2 | §A3, §G3 |
| §4 A4 | 3 | §A4 |
| §5 A5 | 4 | §A5 |
| §6 A6 | 4 | §A6 |
| §7 Week 7 | 5 | §W7 |

---

## §0 General (Day 1; answers: §G)

1. (D) Describe an advantage of representing a program's effects as data that an interpreter executes, rather than using `IO` directly.
2. (D) A QuickCheck property passes 100 tests. Why might we still add a `cover` requirement?
3. (D) Remove left recursion from `E ::= E "-" T | T`, `T ::= "1" | "2" | "3"`, and sketch a parser that produces `(1-2)-3`.
4. What is the difference between lexical (static) and dynamic scoping? Give an APL expression whose result differs between them.
5. State the three monad laws. Pick one and say what would go wrong in an `EvalM` that broke it.
6. Why does the course have you write `Functor`/`Applicative` instances via `liftM`/`ap`? What do they guarantee?
7. Name one thing that the free-monad `EvalM` (A4) can do that the "function" `EvalM` (A2) cannot, and one thing that is harder.

## §1 Week 1 + A1: evaluator with `Either` (Day 1; answers: §A1)

1. (D) In the A1 handout, what do `eval envEmpty (Add (Div (CstInt 1) (CstInt 0)) (Var "x"))` and `eval envEmpty (Add (Var "x") (Div (CstInt 1) (CstInt 0)))` produce? When does evaluation order *not* matter?
2. (D) What does `ForLoop ("p", e) ("i", CstInt 0) body` evaluate to? Does it matter whether `body` fails? Can `Let "i" (CstInt (-1)) (ForLoop ("p", e) ("i", Add (Var "i") (CstInt 1)) body)` loop forever?
3. What does `Let "x" (Div (CstInt 1) (CstInt 0)) (CstInt 5)` evaluate to? Would a lazy APL give a different answer?
4. What does this evaluate to?
   `Let "y" (CstInt 1) (Let "f" (Lambda "x" (Add (Var "x") (Var "y"))) (Let "y" (CstInt 100) (Apply (Var "f") (CstInt 1))))`
   What would it be under dynamic scoping, and which single line of `eval` would you change to get that?
5. `Eql (CstInt 1) (CstBool True)`: what happens, and why did the course choose this over returning `false`?
6. Why is `Val` a separate type from `Exp`? Why is `ValFun` not just `Lambda`?
7. ★ What is the observable evaluation order for `Apply`, and what difference does it make?
8. ★ Would it be correct for `TryCatch` to first call `eval` on both subexpressions? Under which assumptions might it be correct?
9. ★ Can your `eval` loop forever? Give an input, or explain why not.
10. ★ When do `Apply (Lambda "v" x) y == x` and `TryCatch (TryCatch x y) z == TryCatch x y` hold?
11. ★ What is the asymptotic complexity of `printExp` on a left-nested `Add (Add (Add …))`? How could it be improved?
12. ★ State natural properties for `printExp` (e.g. in terms of a parser).
13. ★ Why is `Val` defined in `APL.Eval` rather than `APL.AST`?

## §2 Week 2 + A2: monadic evaluator (Day 2; answers: §A2)

1. (D) `EvalM (Env -> State -> (Either Error a, State))` vs `EvalM (Env -> State -> Either Error (a, State))`: what does each imply for APL's semantics, and which is closer to conventional impure languages?
2. (D) What is `runEval (eval (Add (Print "a" (CstInt 1)) (Print "b" (CstInt 2))))`?
3. (D) For the `catch` in dummy-exam question 2.2.3, what does `TryCatch (Div (CstInt 1) (Print "a" (CstInt 0))) (Print "b" (CstInt 2))` give? Rewrite `catch` so that the effects of the failing branch remain visible.
4. Write `>>=` for `newtype EvalM a = EvalM (Env -> Either Error a)` from memory. Then for the state version.
5. Explain what `askEnv` and `localEnv` do and why `Let` needs `localEnv` instead of passing `env` explicitly.
6. What is `runEval $ eval $ Let "x" (KvPut (CstInt 0) (CstBool True)) (KvGet (CstInt 1))`? Why is the KvPut not "lost"?
7. In `mapM eval [e1, e2, e3]`, in which order do the effects happen, and why is that guaranteed?
8. ★ What is the asymptotic complexity of your `Print`? Can it be improved?
9. ★ If a program keeps updating the same key with `KvPut`, does memory stay constant or grow?
10. ★ In `TryCatch e1 e2`, if `e1` fails after some effects, are those effects visible in `e2`? Show the code change that would flip the behaviour.
11. ★ Could you define `instance Monad m => Semigroup (m ())` / `Monoid (m ())`? What are `mempty` and `<>`? Argue the monoid laws from the monad laws.

## §3 Week 3 + A3: parsing (Day 2; answers: §A3)

1. (D) In APL, how does the parser avoid parsing `get` as a variable name? What stops `getx` from parsing as `get x`? Does `if x y then z else w` parse, and why?
2. Rewrite `E ::= E "+" E | E "*" E | int` so that it has no left recursion, `*` binds tighter than `+`, and both are left-associative.
3. Why must whitespace be consumed *after* each token (lexeme style) rather than before? What happens at the very start of input?
4. What does `try` do in Megaparsec? Give an example from the parser where removing a `try` changes *which inputs are accepted*, and one where it only changes the error message.
5. Why is `choice [lString "*", lString "**"]` wrong, and what are two fixes?
6. Why is application `f x y` parsed as `Atom Atom*` folded with `foldl`? What tree would `foldr` give?
7. Why can't `if …` or `\x -> …` appear as a function argument without parentheses (`f \x -> x`)? Which grammar level enforces that?
8. Where is `eof` needed, and what goes wrong without it?
9. ★ Show the final grammar with left recursion removed and ambiguities resolved.
10. ★ Why might it (not) be problematic that `*` is a prefix of `**`?
11. ★ Where is `try` strictly necessary and where is it just convenient? For one removable `try`, what changes: language, error messages or running time?
12. ★ Give an example where ordered `choice` matters.
13. ★ How would you add line/block comments, and how much would change?

## §4 Week 4 + A4: free monads (Day 3; answers: §A4)

1. Write `data Free e a`, its `Functor` instance and `>>=` from memory. Why must `e` be a `Functor`?
2. Why does `KvGetOp` carry a continuation `(Val -> a)` while `KvPutOp` carries a plain `a`? What about `ErrorOp`, which has no `a`?
3. Write the `InterpPure` case for a new effect `TickOp a` that counts ticks in the state.
4. In A4, how is `localEnv` implemented without a dedicated "local" effect? (Hint: `modifyEffects`/`ReadOp`.)
5. What is the practical difference between the pure interpreter's key-value store and the IO interpreter's file-based store when the program **crashes halfway**?
6. (D) What do `ForLoop ("p", CstInt 0) ("i", CstInt 10) (Apply (Lambda "x" (Break (Var "i"))) (CstInt 0))` and `Apply (Let "f" (ForLoop ("p", CstInt 0) ("i", CstInt 1) (Lambda "x" (Break (CstInt 7)))) (Var "f")) (CstInt 0)` evaluate to? Is "innermost loop" lexical or dynamic?
7. What does `Transaction (Let "x" (KvPut (CstInt 0) (CstInt 1)) (Div (CstInt 1) (CstInt 0)))` followed by `KvGet (CstInt 0)` give, and why?
8. ★ For `TryCatchOp m1 m2 k` where `m1` fails after key-value effects: (a) do your pure and IO interpreters differ in whether those effects are visible in `m2`? (b) If effects are always visible, can a program still make them invisible without changing the interpreters? (Hint: transactions.)
9. ★ Why is `TransactionOp` not `TransactionOp (EvalM ()) a`? Would that make it useless?
10. ★ Why is `TryCatchOp` not `TryCatchOp a a`? What would go wrong?
11. Your own A4 report found a `break` bug (43 ≠ 42). Explain it in two sentences, as you would at the exam.

## §5 Week 5 + A5: property-based testing (Day 4; answers: §A5)

1. Why does a recursive generator need `sized` and halved sizes? What happens without them?
2. Why should generated variable names come from a small pool? What would `onlyCheckedErrors` look like with fully random names?
3. What makes a good `shrink`? Why must shrinking terminate, and what does `shrink (Add e1 e2)` typically return?
4. `cover`, `classify`, `label`, `checkCoverage`: what is the difference?
5. Why does `parse (printExp e) == Right e` catch *printer* bugs and *parser* bugs at the same time? Give a typical counterexample (negative literals, keywords as names, associativity).
6. (D) Can the A5 generator produce a non-terminating program? Is it likely? Give two ways to stop the suite from hanging. How do `while` loops change the answer?
7. ★ Can programs from your `genExp` loop infinitely? Can that be avoided?
8. ★ Which `expCoverage` requirement was hardest, and what did you do?
9. ★ Which counterexamples did `parsePrinted` produce, and where did you fix each (implementation / generator / property)? Why there?
10. ★ Which assumption behind `checkExp` is unjustified, and which counterexample showed it?
11. ★ Name a class of expressions your generator essentially never produces but should. How would you change the generator or `expCoverage`?

## §6 Week 6 + A6: concurrency, GenServer, SPC (Day 4; answers: §A6)

1. What does a server loop look like (state, message type, `receive`, recurse)? Why is all mutable state kept *inside* the loop?
2. Synchronous vs asynchronous API calls: how is each implemented with `Chan` and a reply channel? Which SPC functions are which?
3. What happens to clients if the SPC server thread itself crashes? What error does the runtime give?
4. How does SPC notice timeouts? Why is a separate "ticker" thread needed instead of checking only when messages arrive?
5. Why must a job's exception be caught *in the thread running the job*? Why is catching `SomeException` dangerous with `killThread` (`ThreadKilled`)?
6. What does `jobWait` do if the job is already done? If it is not, where is the waiting client stored?
7. (D) Central vs local (worker) timeouts: one advantage of each, plus the effect a client can observe.
8. ★ (A6) A job is enqueued with no workers and a worker is added later. What happens?
9. ★ Central or decentral timeouts in your design? Pros, cons, observable effects.
10. ★ Which tests show that a worker survives a cancelled / timed-out / crashed job?
11. ★ If a worker thread crashes (bug or `killThread`), how does that affect the rest of SPC?
12. ★ `jobCancel` (async), then immediately `jobStatus`: is `DoneCancelled` guaranteed, or is there a race?
13. `workerStop` on a busy worker: list the messages exchanged, in order.

## §7 Week 7: tuples, `&&`/`||`, three interpreters (Day 5; answers: §W7)

**A–C**
1. How does the parser tell `(e)`, `()` and `(e1, e2, …)` apart? Why is `try` needed?
2. What do `(1,2).2`, `(1).0` and `let x = (1,2) in x.0` give?
3. Extend the precedence table with `&&` and `||` and write the corresponding no-left-recursion grammar levels.
4. Where exactly does `evalStep` occur, and why also at function application and not only in loops? (Hint: `(\x -> x x)(\x -> x x)`.)
5. In the pure interpreter, what do `(1+2) || (3+4)`, `(1/0) || 5` and `(1/0) && (2/0)` give?

**D–F**

6. (D) In the simulated interpreter, what does `(1+2) || (3+4+5+6)` give, and why? Is it always that result? What about `(loop p = 0 while true do p) || 1`?
7. Why must `step` stop *at* the next `StepOp` and not run to completion?
8. `get 0 && put 0 true`: what is the result in the pure, simulated and concurrent interpreters, and why do they differ?
9. In the simulator, what should happen with `get 0 && get 1` (all computations blocked)? How would you detect that?
10. Why does the concurrent interpreter store job results in `IORef`s? Why must it use SPC instead of `forkIO`?
11. In the concurrent `||`, what happens to the losing job? What could go wrong if it were left running?
12. KVDB: what state does the server keep so that a `kvGet` on a missing key blocks until a `kvPut`? Sync or async for each operation?
13. When can "thread blocked indefinitely in an MVar operation" occur with a *correct* interpreter? Give an APL program.
14. Is the simulated interpreter deterministic? Is the concurrent one? What does that mean for writing tests?
