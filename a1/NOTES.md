# A1 worklog

Scratch notes kept while solving Assignment 1. Not a deliverable — the actual
report is in `REPORT.md`. This is just where I wrote down what I tried, what
broke, and the decisions I had to make so I wouldn't forget them by the time I
had to write the report.

---

## Day 1 — reading the handout

Unpacked `a1-handout.tar.gz` into `handin/`. First thing I checked was which
interpreter this is built on, because we've now written two of them:

- week 1: `eval :: Env -> Exp -> Either Error Val`, environment passed
  explicitly, errors as `Left String`.
- week 2: `eval :: Exp -> EvalM Val` with a reader+either monad.

The handout's `Eval.hs` is clearly the **week 1** one. That matters, because
`week2/solution/` in the course repo *already* has `ForLoop`, `Lambda`, `Apply`
and `TryCatch` implemented — it would have been very tempting to just lift
those. But the general assignment rules say not to change the types of exported
definitions, and `eval` here has the week-1 type. So: week-1 style it is, and
the week-2 code is only useful to me as a second opinion on what the semantics
are supposed to be. (Turned out to be worth having — see the `p == i` thing
below.)

Second thing: `printExp` is already in `APL.AST`'s export list, sitting there as
`undefined`. So the module boundary is fixed for me too — the printer goes in
`AST`, not in `Eval`. That's actually the answer to report question 8 staring
me in the face: `AST` doesn't know anything about values or environments, and
the printer doesn't need it to.

Plan: do the tasks in the order given, write tests as I go rather than at the
end (last time I left tests to the end and then wrote tests that just agreed
with whatever my code happened to do).

---

## Task 1 — ForLoop

Straightforward reading of the six steps in the text. Rough shape:

```haskell
eval env (ForLoop (p, initial) (i, bound) body) =
  case eval env initial of
    Left err -> Left err
    Right v ->
      case eval env bound of
        Left err -> Left err
        Right (ValInt n) -> ...iterate...
        Right _ -> Left "Non-integral loop bound"
```

**Mistake 1.** I first tried to put the loop helper in a `where` hanging off the
`Right (ValInt n)` alternative:

```haskell
        Right (ValInt n) -> loop 0 v
          where loop k acc = ...
```

That doesn't parse — a `where` attaches to the whole *equation*, not to a `case`
alternative. (You can use `let` inside an alternative, which would also have
worked, but then the helper is indented three levels deep and reads badly.)
Fixed by moving `loop` into the equation's `where` and passing `n` in as a
parameter. `env`, `p`, `i` and `body` are all still in scope there, so only `n`
has to be threaded.

**Mistake 2** — this one would have compiled fine and been wrong. My first
version of the iteration extended the environment it had just built:

```haskell
    loop k n acc envSoFar = ... eval (envExtend p acc (envExtend i (ValInt k) envSoFar)) body ...
```

which means after 1000 iterations the environment is 2000 entries long and
`envLookup` is walking past 1998 stale bindings to find the live one. Results
would still be *correct* (the newest binding shadows the old ones) but it's
quadratic for no reason. Every iteration should start from the original `env`.
Caught this by writing the "outer scope visible" test and noticing I was
thinking too hard about which `env` to use.

**Ambiguity: what if `p` and `i` are the same name?** The text says bind `i`
first (step 3) and `p` second (step 4). Later binding wins, so the body should
see `p`. `envExtend` conses onto the front and `envLookup` is `lookup`, which
takes the first hit, so "bound last" = "extended outermost":

```haskell
envExtend p acc (envExtend i (ValInt k) env)
```

Checked `week2/solution` afterwards out of curiosity and it does
`envExtend iv (ValInt i) . envExtend loopparam loop_v`, which resolves it the
*other* way (the counter wins). So the official solution and a literal reading
of the text disagree on this. It's a degenerate case nobody sane would write, but
I went with the text. Noting it in the report.

Other things I convinced myself of:

- A negative bound is not an error — step 5 is a `while`, so it just runs zero
  times and returns the initial value. Wrote a test for it.
- The *initial* value doesn't have to be an integer, only the bound does. Test
  with `CstBool True` as the initial value.
- Order matters for error reporting: the text evaluates `initial` first, so when
  both `initial` and `bound` are broken, `initial`'s error is what you see. Wrote
  a test that pins this down, since it's not forced by anything else.

---

## Task 2 — Lambda / Apply

`Lambda` was three minutes: don't touch the body, just capture `env` in a
`ValFun`. The only thing worth being careful about is that `Val` now mentions
`Env`, and `Env` mentions `Val` — mutually recursive, but Haskell doesn't care
about definition order in a module, so nothing to do. `deriving (Eq, Show)`
still works because `Env` and `Exp` both have those, which is what makes the
assignment's expected output `Right (ValFun [("x",ValInt 2)] "y" ...)` printable
at all.

`Apply` took longer, mostly deciding *how* to write it rather than what it does.
I wrote the tuple-`case` version to match `evalIntBinOp` and `Eql`:

```haskell
  case (eval env e1, eval env e2) of
    (Left err, _) -> Left err
    (_, Left err) -> Left err
    (Right (ValFun f_env var body), Right arg) -> eval (envExtend var arg f_env) body
    (Right _, Right _) -> Left "Cannot apply non-function"
```

Then I realised the *order of these alternatives* is exactly what report
question 1 is asking about, and it's a real choice, not boilerplate:

- If both `e1` and `e2` fail, alternative 1 fires and you get `e1`'s error.
  Swap the first two lines and you'd get `e2`'s error instead. Nothing in the
  assignment forces either — it says the order is unspecified — so whichever I
  pick I should be able to say which it is.
- Less obvious: if `e1` succeeds but isn't a function *and* `e2` fails, you get
  `e2`'s error, not "Cannot apply non-function", because alternative 2 comes
  before alternative 4. That surprised me a bit. Test for both.

The important bit is `f_env`, not `env` — the body runs in the environment from
the *definition* site. Wrote the static-scoping test (rebind `x` to 100 at the
call site, check you still get 1) because that's the one thing here I could
plausibly have got backwards and still passed all the other tests.

Also uncommented the `yComb`/`fact` block that the handout ships commented out —
it's obviously there to be switched on once `Lambda`/`Apply` exist. `fact 5`
gives 120. Nice sanity check, and it's also my evidence for report question 3
(this language can loop forever).

One more test I'm glad I wrote: applying a function that ignores its argument to
a division by zero still fails. That's APL being call-by-value, and it's the
reason question 4(a) isn't just "always".

---

## Task 3 — TryCatch

Four lines. The only thought here was whether to write it as

```haskell
  case (eval env e1, eval env e2) of
    (Right v, _) -> Right v
    (_, r)       -> r
```

which is what question 2 is poking at. In Haskell that version is actually
*fine*, because the tuple is lazy and `eval env e2` never gets forced unless the
first pattern fails. But it reads as if both are being evaluated, and the whole
point of `TryCatch` is that the handler runs only on failure — so I wrote the
explicit `case eval env e1 of Left _ -> ...` version instead. Kept the other one
in my head for the report.

---

## Task 4 — printExp

Longest task, which I didn't expect.

First instinct was to do it properly: track precedence levels, only emit
parentheses when a child binds looser than its parent, so `1 + 2 * 3` comes out
as `1 + 2 * 3` and not `(1 + (2 * 3))`. Started writing a `printExp' :: Int -> Exp
-> String` with precedence numbers, then re-read the assignment and it says in so
many words that extra parentheses are acceptable and *recommends* parenthesising
everything. Threw the precedence version away. It would have been more code, more
chances to be wrong, and worth no extra marks.

So: atoms (`CstInt`, `CstBool`, `Var`) print bare, everything else wraps itself in
parens. The bit worth checking is that this actually satisfies the two rules the
assignment makes *mandatory*:

- "any argument in an `Apply` must be parenthesised unless it is a constant or
  variable" — a non-atomic argument parenthesises itself, and the atomic ones
  are precisely the constants and variables allowed to be bare. ✓
- "the function part must be parenthesised unless it is a constant, variable, or
  another `Apply`" — same argument. I *do* parenthesise a nested `Apply` in
  function position, which is more than required, but that's the permitted
  direction. ✓

So both hold by construction rather than by a special case in the `Apply`
branch, which I liked.

Gotchas:

- `CstBool` must print `true`/`false`, so `show b` is wrong — it gives
  `True`/`False`. Easy to miss, hence a test for each.
- `Pow` is `**`, not `^`.
- The lambda needs a literal backslash, so `"\\x -> "` in the source.
- A consequence I should flag rather than hide: the whole top-level expression
  comes out parenthesised too, e.g. `printExp (Add (CstInt 1) (CstInt 2))` is
  `"(1 + 2)"`, not `"1 + 2"`. I think that's within "more parentheses than
  strictly necessary" but it's the thing most likely to trip an exact-string
  test written by someone else.

**Left undone.** `printExp` is quadratic on left-nested expressions, because
every `++` copies its left operand and the left operand is the whole prefix
built so far. `ShowS`/difference lists would fix it, i.e. build
`String -> String` and apply at the end. I didn't do it — the printer is a
debugging aid, nothing calls it on a 10000-deep expression, and rewriting it in
`ShowS` style would make it noticeably harder to read. But it's a real
shortcoming and question 6 asks about exactly this, so I'm not pretending
otherwise.

---

## Tests

35 evaluation tests, 23 printer tests; all 58 pass. The ones I'd point at if someone asked
which tests are actually load-bearing (as opposed to checking that `+` is `+`):

- `Apply (static scoping)` — the one test that would fail if I'd used the call
  site's environment.
- `Apply (function error wins)` and `Apply (argument error beats non-function)` —
  pin down the evaluation order, which is otherwise invisible.
- `Apply (argument evaluated even if unused)` — pins down call-by-value.
- `ForLoop (bindings do not escape)` and `ForLoop (outer scope visible)` —
  together these would have caught the environment-growth bug.
- `Apply (factorial via Y combinator)` — end-to-end, exercises `Lambda`,
  `Apply`, `If`, `Eql`, `Mul`, `Sub` and closures all at once.

Not tested, and I know it: the `p == i` shadowing case I agonised over above. I checked in the REPL what my code
actually does -- `ForLoop ("x", CstInt 100) ("x", CstInt 3) (Var "x")` gives
`100`, i.e. the parameter wins, which is what I intended; the other reading gives
`2`. But turning that into a test would mean asserting my reading of an ambiguous
sentence as if I were sure of it, and I'm not. Mentioned in the report instead.

Also untested: anything about non-termination, for obvious reasons (`runtests.hs`
sets a 1-second timeout, so a test for it would just be a test that the timeout
works).
