# Cheat sheet (fill in as you go; print on 8 Nov)

Aim for 2–3 printed pages. Write **only** what you would otherwise have to hunt for: definitions, gotchas and the exact semantics of each construct. Code you can find in the compendium (page index in `README.md`).

## Exam technique
- Value + one-line reason. Most dummy answers are 1–3 sentences.
- "Is it always this result?" → think **deterministic (pure/sim) vs nondeterministic (concurrent)**.
- "What changes if…" → name the observable difference (result value, which error, which effects are kept).

## W1/A1: evaluator
- Scoping: closures capture the *definition* env → static scope.
- `ForLoop (p, init) (i, bound) body`: init and bound are evaluated in the **outer** env, before the loop.
-

## W2/A2: monads
- `(Either Error a, State)` = effects survive errors · `Either Error (a, State)` = rolled back.
- Monad laws: `pure a >>= f = f a` · `m >>= pure = m` · `(m >>= f) >>= g = m >>= (\x -> f x >>= g)`
-

## W3/A3: parsing
- Left recursion `E ::= E op T | T` → `E ::= T E'`, `E' ::= op T E' | ε`; left assoc via an accumulator.
- `try p`: if `p` fails *after consuming input*, rewind so that `choice` can try the next alternative.
-

## W4/A4: free monads
- `data Free e a = Pure a | Free (e (Free e a))`
- `Free g >>= f = Free (fmap (>>= f) g)`
-

## W5/A5: QuickCheck
-

## W6/A6: concurrency
-

## W7: concurrency in APL
-

## TA feedback I received
- A1:
- A2:
- A3:
- A4:
- A5:
- A6:
