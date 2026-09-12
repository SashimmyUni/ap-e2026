# Advanced Programming 2026 — Assignment 1

**Declaration of AI use (course AI policy).** This entire hand-in — the Haskell
code in `handin/`, its tests, and this report — was produced with the assistance
of **Claude Code (Claude Opus 5)**. No part of it should be assumed to be
unassisted work. *(Amend this paragraph before hand-in so that it accurately
describes your own group's process.)*

---

## Introduction

All four tasks are implemented: `ForLoop`, `Lambda`/`Apply` (with `ValFun`),
`TryCatch`, and `printExp`. The code builds without warnings under `-Wall` with
GHC 9.10.3, and all 58 tests pass (35 for evaluation, 23 for the pretty-printer).
I extended the handout's week-1 style interpreter rather than porting the week-2
monadic one, since the assignment rules fix the type of `eval`.

I think the evaluator is correct, and I have reasonable grounds for saying so:
the tests are not only "does `+` add", they pin down the decisions that were
actually free. In particular `Apply (static scoping)` would fail if I had used
the call site's environment instead of the closure's, `ForLoop (bindings do not
escape)` and `ForLoop (outer scope visible)` between them catch getting the
loop's environment handling wrong, and the Y-combinator factorial test exercises
closures, `If`, `Eql` and recursion end to end. I have also checked all five
worked examples from the assignment text and they reproduce exactly. I am less
pleased with `printExp`: it is correct but quadratic (question 6), and I chose
not to spend the time rewriting it in `ShowS` style.

Four ambiguities I had to resolve:

1. **`ForLoop` where the loop parameter and the counter have the same name.**
   Steps 3 and 4 bind the counter first and the parameter second, so on a literal
   reading the parameter shadows the counter, and that is what I implemented. I
   note that `week2/solution` resolves this the other way around, and the two
   readings genuinely differ: `ForLoop ("x", CstInt 100) ("x", CstInt 3)
   (Var "x")` evaluates to `100` under mine and would give `2` under the other.
   It is a degenerate case, and I have deliberately *not* written a test
   asserting my reading, since I am not confident enough in it to encode it.

2. **Evaluation order of `Apply`** is explicitly unspecified. I chose
   left-to-right and made it observable and tested rather than accidental — see
   question 1.

3. **Parentheses in `printExp`.** Taking the assignment's recommendation, atoms
   print bare and *every* compound expression parenthesises itself. A
   consequence worth flagging: the outermost expression is parenthesised too, so
   `printExp (Add (CstInt 1) (CstInt 2))` is `"(1 + 2)"` rather than `"1 + 2"`.
   I read that as within "more parentheses than strictly necessary", but it is
   the thing most likely to trip an exact-string test written by someone else.

4. **Behaviour the text does not specify.** A negative loop bound is *not* an
   error — step 5 is a `while`, so the body never runs and the initial value is
   returned. Applying a non-function needs an error message the text does not
   supply; I used `"Cannot apply non-function"`.

## Questions

**1. Observable evaluation order for `Apply`.**
`eval` is pure, so evaluation order is observable only in two ways: *which error
is reported* when more than one thing is wrong, and *termination*. My `Apply`
scrutinises the pair `(eval env e1, eval env e2)` with the alternatives ordered
`(Left err, _)`, then `(_, Left err)`, then the `ValFun` case, then
"cannot apply non-function". Matching the first alternative forces only the
function component, so the observable order is **left-to-right**: the function
expression's error wins. Two tests demonstrate it. `Apply (function error wins)`
evaluates `Apply (Var "nope") (Div (CstInt 1) (CstInt 0))`, where both halves
fail, and gets `"Unknown variable: nope"` — swapping the first two alternatives
would give `"Division by zero"` instead. `Apply (argument error beats
non-function)` shows the less obvious consequence of the ordering: because the
argument's failure is checked *before* the function's shape, `Apply (CstInt 1)
(Div (CstInt 1) (CstInt 0))` reports `"Division by zero"` rather than
`"Cannot apply non-function"`. Laziness also means that when `e1` fails we never
force `e2` at all, so `e1`'s error is returned even if `e2` would diverge.

**2. Could `TryCatch` call `eval` on both subexpressions first?**
As Haskell is written today, **yes** — it would still be correct. "Calling
`eval`" does no work; it builds a thunk. Writing
`case (eval env e1, eval env e2) of (Right v, _) -> Right v; (_, r) -> r`
forces the second component only when the first is a `Left`, so it is
observationally identical to my version. It is nevertheless a bad way to write
it, because its correctness rests on laziness rather than on the code saying what
it means. It becomes *wrong* as soon as any of three assumptions fails: if the
host language is strict, since then `e2` is always evaluated and
`TryCatch (CstInt 0) <something divergent>` would loop instead of returning `0`;
if `eval` acquires effects — a state, writer or `IO` monad, which is exactly
where we go next — since the handler's effects would then happen even when the
handler is not needed; or if we care about cost, since evaluating a handler that
is never used is wasted work. So: correct under the assumptions that `eval` is
pure and that the language is lazy (or that every subexpression terminates).

**3. Can `eval` loop forever?**
Yes. `ForLoop` alone cannot cause it — the bound is evaluated once to a finite
integer, so any nest of loops terminates — but `Lambda`/`Apply` give the untyped
lambda calculus, and with it general recursion. The smallest witness is Ω:
`Apply (Lambda "x" (Apply (Var "x") (Var "x"))) (Lambda "x" (Apply (Var "x")
(Var "x")))`. The handout's own `yComb` is a less contrived one — my `fact` test
terminates for `5`, but `Apply fact (CstInt (-1))` would decrement forever, since
`n` never becomes `0`. `eval` is therefore not a total function, which is
unavoidable for a language of this expressive power.

**4. When do the equalities hold?**
Reading `==` as "evaluate to the same result in every environment".

(a) `Apply (Lambda "v" x) y == x` holds when **`"v"` is not free in `x`**, and
**`y` terminates and evaluates successfully**. The first condition is the obvious
one: otherwise the left-hand side evaluates `x` with `v` bound to `y`'s value
while the right-hand side does not. The second matters because APL is
call-by-value: `Apply` evaluates the argument even when the body ignores it, so
`Apply (Lambda "v" (CstInt 1)) (Div (CstInt 1) (CstInt 0))` fails while
`CstInt 1` succeeds. My test `Apply (argument evaluated even if unused)` is
exactly this case. (If `x` itself diverges both sides diverge, so that is fine.)

(b) `TryCatch (TryCatch x y) z == TryCatch x y`. The two sides can only differ
when the inner `TryCatch` *fails*, which happens only when `x` and `y` **both**
fail. So the equality holds when the inner `TryCatch` never fails — e.g. `y`
always succeeds whenever `x` fails — or, in the case where both do fail, when `z`
fails with exactly the same error that `y` produced (`z = y` being the trivial
instance). It also requires `z` to terminate in that case. In every other
situation the outer handler is dead code and the equality holds vacuously.

**5. Making APL dynamically scoped.**
Three changes, all small. `ValFun` would no longer capture an environment,
becoming `ValFun VName Exp`; `eval` for `Lambda` would ignore its environment
argument and just return `ValFun var body`; and `Apply` would evaluate the body
in the **caller's** environment extended with the parameter binding —
`eval (envExtend var arg env) body` instead of `... f_env ...`. Nothing else
moves: `Let`, `ForLoop` and `TryCatch` already work in the current environment.
Two visible consequences: the assignment's own example output changes, since
there would be no environment to print inside the `ValFun`; and my
`Apply (static scoping)` test would flip from `1` to `100`. A pleasant
side-effect is that `Val` would no longer be mutually recursive with `Env`.

**6. Complexity of `printExp` on a left-nested expression.**
**Quadratic**, Θ(n²) in the number of nodes. `(++)` is linear in its *left*
argument, and in `printExp e1 ++ " + " ++ printExp e2` the left argument is the
string built for the entire left spine so far. So at depth *k* we copy Θ(k)
characters, and Σ Θ(k) over k = 1..n is Θ(n²). (The `parens` wrapper adds another
Θ(k) per level, which does not change the class.) Note the asymmetry: a
*right*-nested expression is linear, because there the accumulated string is
always the right operand. The standard fix is to build a `ShowS`
(`String -> String`) by function composition and apply it once at the end, which
makes it linear; I did not do this, as the readability cost seemed not worth it
for a debugging aid.

**7. Properties of `printExp`.**
Hypothesising a parser `parseExp :: String -> Maybe Exp` and a QuickCheck
`Arbitrary` instance for `Exp`, the natural properties are:

- *Round-trip*: `parseExp (printExp e) == Just e`. This is the strongest and most
  useful one — it says the printer loses no information, and it subsumes
  injectivity (`printExp e1 == printExp e2` implies `e1 == e2`).
- *Semantics preservation*, a weaker version worth having if the round-trip is
  too strict: if `parseExp (printExp e) == Just e'` then
  `eval env e == eval env e'` for every `env`.
- *Print idempotence*: `fmap printExp (parseExp (printExp e)) == Just (printExp e)`.
- *Balanced parentheses*: in `printExp e`, no prefix contains more `)` than `(`,
  and the totals agree.
- *Size*: `length (printExp e)` is linear in the number of nodes of `e`, i.e. the
  printer does not blow up its input.

My unit tests are the pointwise, per-constructor specification (`printExp (Add a
b)` is `"(" ++ ... ++ ")"` and so on), which is what one can check before a parser
exists.

**8. Why `Val` lives in `APL.Eval` and not `APL.AST`.**
`Exp` is *syntax* — what a program is — while `Val` is part of the *dynamic
semantics* — what running one produces. Keeping them apart is not just tidiness:
`ValFun` carries an `Env`, which is a data structure belonging to this particular
interpreter (an association list, chosen for convenience). Putting `Val` in
`APL.AST` would drag that runtime representation into the syntax module, and the
dependency would run the wrong way — `APL.Eval` imports `APL.AST`, never the
reverse. As it stands, every other consumer of the AST can ignore evaluation
entirely: `printExp` in this very assignment needs `Exp` and nothing else, and
the same goes for a future parser, a type checker, or a second evaluator with a
different value representation. It also localises change: replacing
`Either Error Val` with an evaluation monad, as in week 2, touches `APL.Eval`
alone.
