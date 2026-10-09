# AP 2026 - Assignment 5

## Introduction:

The hand-in consists of a solution for all three tasks. We only changed `genExp`, `arbitrary`, `parsePrinted` and `onlyCheckedErrors` in `APL.Tests`, and `printExp` in `APL.AST`. AI was used in the structuring and creation of the tests.

The result of `cabal test` is that two properties pass and one fails:

- `expCoverage` passes. In one run of 10000 tests we got 40.45% domain errors, 68.37% type errors, 17.78% variable errors and 74.10% non-trivial variables. All of them are at least 11 points from the limit.
- `parsePrinted` passes 10000 tests. We ran it 10 times.
- `onlyCheckedErrors` fails. This is on purpose, since the assignment says that the property does not hold and that we should not repair `checkExp`. We ran it 300 times and it found a counterexample every time, on average after 1079 tests and at most after 7153.

Some details of the implementation:

- `genExp` has the type `[VName] -> Int -> Gen Exp`, where the list is the variables in scope, as the assignment suggests. `Let` and `Lambda` add their variable to the list for the body.
- Integer constants are between 0 and 5. Small numbers make it more likely that a division by zero or an equal comparison really happens.
- `onlyCheckedErrors` has the type `Exp -> Property` and not `Exp -> Bool`, because we use `discardAfter` to give up on programs that loop (see question 1).

The text had some ambiguities. It says that we will need to fix errors of more than one of the three kinds. We fixed errors in the implementation and in the generator, but we never found an error in the property. The text also does not say what to do with negative integer constants, which cannot be written in APL. We chose to not generate them (see question 3).

We think the solution is functionally correct. The argument is that the properties are short and say directly what the assignment asks for, and that all numbers in this report are from running the code. There are two things we are less sure of. `onlyCheckedErrors` only fails with some probability. We measured about 10 counterexamples per 10000 tests, so a run that finds none should be very rare, but it is possible. With QuickCheck 2.18 the build also gives a deprecation warning for `withMaxSuccess` in `properties`. This is from the handout, and we have not changed it. On Windows the test program sometimes prints lines with "onIOComplete" after the result, which comes from the timeouts and does not change the result.

With more time we would generate programs with fewer type errors, so that more of them are evaluated all the way (see question 5).

## Questions and Answers:

### 1. Can programs produced by your `genExp` loop infinitely when evaluated? If so, is it possible to avoid this?

Yes, they can. A variable in scope can be used anywhere, also as both the function and the argument in an `Apply`. Our generator produced this program:

```
(let d = (\ltm -> (ltm ltm)) in ((d d) == (d false)))
```

Here `d d` applies the function to itself forever. We measured that about 3 of 10000 generated programs do not finish within 0.1 seconds. That is rare, but with 10000 tests it happens in most runs, and before we handled it the test could hang.

It is possible to avoid it, in two ways. The first is in the generator, by only generating programs that are well typed, since a function then cannot be applied to itself. We did not do this, because it is a much bigger generator, and it would also remove the type errors that `expCoverage` asks for. The second is in the property, which is what we did:

```haskell
onlyCheckedErrors e = discardAfter 100000 $ case runEval (eval e) of
```

A test that takes more than 0.1 seconds is discarded and does not count. This does not avoid the looping programs, but it makes them harmless. It also handles programs that are not infinite but very slow, like many `**` inside each other.

### 2. Which of the four coverage requirements in `expCoverage` was hardest to satisfy, and what did you do to satisfy it?

The hardest was at most 30% variable errors, because it works against the requirement that at least 50% contain a variable. Many expressions are large, and one unknown variable anywhere is enough to give a variable error.

Our first version with the scope list still had 32% variable errors. We did two things. A `Var` is taken from the variables in scope 60 out of 61 times, and is only rarely a new name. When no variable is in scope, a `Var` is always an error, so there it has a low weight:

```haskell
, (if null vars then 1 else 12, Var <$> genVar)
```

After this we had about 18% variable errors and still over 60% non-trivial variables. We found the weights by counting with `classify` and `tabulate` in a small test program, and not by running `checkCoverage` again and again.

### 3. Which counterexamples did `parsePrinted` produce? For each counterexample, which component (implementation, generator or property) did you fix, and why was that the right place to fix it?

We got four kinds of counterexamples, in this order:

**`CstInt (-3)`**. It is printed as `-3`, and the parser gives an error, since APL has no negative constants. We fixed the generator, so it only makes constants from 0 to 5. The printer cannot print it in another way that parses back to the same expression, and making the parser accept `-3` would change the language, since `x -3` is a subtraction.

**`Div (TryCatch (CstInt 1) (CstInt 2)) (CstInt 0)`**. It is printed as `(try 1 catch 2 / 0)`, which parses as `TryCatch (CstInt 1) (Div (CstInt 2) (CstInt 0))`. We fixed the implementation, by putting parentheses around `try` in `printExp`. The expression is a valid program and the parser follows the grammar, so the error is that the printer loses where the `catch` part ends.

**`Apply (CstBool True) (Apply (Var "qoww") (CstInt 2))`**. It is printed as `true qoww 2`, which parses as `Apply (Apply (CstBool True) (Var "qoww")) (CstInt 2)`, since application is left associative. We fixed the implementation again, with parentheses around an `Apply`:

```haskell
printExp (Apply x y) =
  parens $ printExp x ++ " " ++ printExp y
```

**`Let "in" (CstInt 0) (Var "in")`** and **`Lambda "if" (Var "if")`**. The variable is a keyword, so the printed program cannot be parsed. We fixed the generator, so `genVName` does not give a keyword. A keyword is not a valid variable name in APL, so the parser is right to reject it, and the expression should not be generated.

We did not change the property. It was `parseAPL "" (printExp e) == Right e` the whole time.

### 4. Which assumption underlying `checkExp` is not justified, and which counterexample did `onlyCheckedErrors` produce to demonstrate this?

The assumption is in the `TryCatch` case:

```haskell
check (TryCatch x y) = do
  maskErrors $ check x
  check y
```

`checkExp` assumes that an error in the code inside a `try` can only happen while the `try` is evaluated, so it is always caught. This is not justified, because of functions. A `Lambda` inside a `try` evaluates without error to a function value, and the body is first evaluated when the function is applied. If that happens outside the `try`, the error is not caught.

The smallest counterexample we got was:

```haskell
Apply (TryCatch (Lambda "nn" (Var "b")) (CstInt 4)) (CstInt 4)
```

This is the program `((try (\nn -> b) catch 4) 4)`. `checkExp` returns `[NonFunction]`, since the unknown variable `b` is masked. Evaluation gives `Left (UnknownVariable "b")`, because the `try` succeeds with the function, and `b` is first looked up when the function is applied to 4. All 300 counterexamples in our runs had a `Lambda` inside a `TryCatch`.

These counterexamples are rare, since a function must be made inside a `try` and applied outside it. Our first generator found one in only 9 of 12 runs. We raised the weights of `Lambda`, `Apply` and `TryCatch`, and then it was 300 of 300.

### 5. Your generator satisfies `expCoverage`. Describe a class of expressions that your generator will nevertheless produce essentially never, but that would be worth testing. How would you change either the generator or `expCoverage` to cover it?

Expressions where a domain error really happens when they are evaluated. `expCoverage` says that 40% of our expressions have a domain error, but that only means that they contain a `Div` or `Pow`. We evaluated 100000 generated expressions, and only 0.066% gave `DivisionByZero` and 0.004% gave `NegativeExponent`. The rest gave no error (57%) or failed with a type error or an unknown variable.

The reason is that the operands are random expressions, so they are often a boolean or a function, and the evaluation fails with `NonInteger` before the division. A negative exponent is even more rare, since we have no negative constants, so it must come from a `Sub`.

This class is worth testing, since it is the only way to test `checkedDiv` and `checkedPow` in the evaluator and the masking of domain errors in `checkExp`.

We would change both. In `expCoverage` we would add a requirement about what happens at run time, and not only what `checkExp` says:

```haskell
. cover 5 (runEval (eval e) == Left DivisionByZero) "division by zero happens"
```

To satisfy it, the generator should make the operands of `Div` and `Pow` with a generator for integer expressions (constants, integer variables and arithmetic), and sometimes make the right operand `CstInt 0` or `Sub (CstInt 0) e`.
