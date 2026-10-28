# Mock exam B (for Day 6)

A fresh exam in the style of `week7/exam-dummy.pdf`. The questions are **variants**, not copies, so you practise *adapting* the Exam Notes rather than copying them.

**Rules:** 2 hours. Use only what you will have at the exam: printed `EXAM-NOTES.md`, `ap-notes.pdf`, `compendium.pdf`. No IDE, no GHCi, no AI. Write in `week7/answer-sheet.docx` (or a plain file) with 1–3 sentences per answer. Mark it afterwards with `MOCK-EXAM-SOLUTIONS.md`.

---

## 1 General

**1.1** Name one *disadvantage* of representing effects as data that an interpreter executes (free monads), compared with using `IO` directly.

**1.2** What is the difference between `classify` and `cover` (used with `checkCoverage`) in QuickCheck?

**1.3** Consider this grammar, where `*` and `/` are left-associative:
```
E ::= E "*" F | E "/" F | F
F ::= int | "(" E ")"
```
1. Remove the left recursion.
2. Sketch a parser that produces `Div (Mul 2 3) 4` for `2*3/4`.

## 2 Assignment questions

### 2.1 A1
**2.1.1** With the A1 semantics, what do these produce?
1. `eval envEmpty (Let "x" (Var "y") (CstInt 1))`
2. `eval envEmpty (If (CstInt 1) (CstInt 2) (Div (CstInt 1) (CstInt 0)))`
3. `eval envEmpty (ForLoop ("p", CstInt 1) ("i", CstInt 3) (Mul (Var "p") (CstInt 2)))`

**2.1.2** What does this evaluate to? Would the answer change if APL were dynamically scoped?
```
Let "x" (CstInt 5)
  (Apply (Lambda "y" (Var "x"))
         (Let "x" (CstInt 7) (Var "x")))
```

### 2.2 A2
**2.2.1** With `newtype EvalM a = EvalM (Env -> State -> (Either Error a, State))`, what is
```
runEval (eval (Let "x" (Print "a" (CstInt 1))
                       (Div (Var "x") (Print "b" (CstInt 0)))))
```

**2.2.2** What would the same expression give with `newtype EvalM a = EvalM (Env -> State -> Either Error (a, State))`? Why?

**2.2.3** Write `>>=` for `newtype EvalM a = EvalM (Env -> State -> Either Error (a, State))`.

### 2.3 A3
**2.3.1** Suppose `lKeyword` were defined *without* `notFollowedBy (satisfy isAlphaNum)`. Give an input whose meaning changes, and explain.

**2.3.2** How would you change the grammar so that `==` is **non-associative**, i.e. `a == b == c` is a parse error, but `a == b` still parses?

### 2.4 A4
**2.4.1** In the A4 pure interpreter (where the effects of a failing `m1` are not visible in `m2`), what does this evaluate to? What would the IO interpreter give, and why?
```
Let "_" (TryCatch (Let "_" (KvPut (CstInt 0) (CstInt 1)) (Var "nope"))
                  (CstInt 2))
        (KvGet (CstInt 0))
```

**2.4.2** What does this evaluate to in the pure interpreter? Explain the role of each `Transaction`.
```
TryCatch (Transaction (Let "_" (KvPut (CstInt 0) (CstInt 1))
                          (Transaction (Let "_" (KvPut (CstInt 0) (CstInt 2))
                                                (Var "die")))))
         (KvGet (CstInt 0))
```

**2.4.3** Why does `KvGetOp` carry a `Val -> a` while `KvPutOp` carries an `a`? What does `fmap` do on an effect like `ErrorOp Error` that has no `a`, and what does that mean for the program?

### 2.5 A5
**2.5.1** What is wrong with this generator? How would you fix it?
```haskell
genExp :: Gen Exp
genExp = oneof [CstInt <$> arbitrary, Add <$> genExp <*> genExp]
```

**2.5.2** `parsePrinted` fails on `Sub (CstInt 1) (Sub (CstInt 2) (CstInt 3))`, which is printed as `1 - 2 - 3`. Which component do you fix: implementation, generator or property? Why?

### 2.6 A6
**2.6.1** A client is blocked in `jobWait` on a job, and a scoundrel `killThread`s the worker running that job. What does the client observe (a) if timeouts are enforced centrally by SPC, and (b) if there are no timeouts at all?

**2.6.2** Why is `jobCancel` asynchronous while `jobStatus` is synchronous?

### 2.7 Week 7 exercises
**2.7.1** What does `let _ = (put 0 1 || put 0 2) in get 0` evaluate to in the pure interpreter and in the simulated interpreter? Explain the difference.

**2.7.2** What does `(loop p = 0 for i < 3 do p + 1) || (loop p = 0 for i < 2 do p + 10)` evaluate to in the pure, simulated and concurrent interpreters?

**2.7.3** What happens when evaluating `get 1 && put 0 1` in each of the three interpreters?

**2.7.4** How do `f x.1` and `a && b || c && d` parse? Give the ASTs.
