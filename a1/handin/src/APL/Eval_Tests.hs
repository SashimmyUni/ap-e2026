module APL.Eval_Tests (tests) where

import APL.AST (Exp (..))
import APL.Eval (Val (..), envEmpty, eval)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

-- Consider this example when you have added the necessary constructors.
-- The Y combinator in a form suitable for strict evaluation.
yComb :: Exp
yComb =
  Lambda "f" $
    Apply
      (Lambda "g" (Apply (Var "g") (Var "g")))
      ( Lambda
          "g"
          ( Apply
              (Var "f")
              (Lambda "a" (Apply (Apply (Var "g") (Var "g")) (Var "a")))
          )
      )

fact :: Exp
fact =
  Apply yComb $
    Lambda "rec" $
      Lambda "n" $
        If
          (Eql (Var "n") (CstInt 0))
          (CstInt 1)
          (Mul (Var "n") (Apply (Var "rec") (Sub (Var "n") (CstInt 1))))

tests :: TestTree
tests =
  testGroup
    "Evaluation"
    [ testCase "Add" $
        eval envEmpty (Add (CstInt 2) (CstInt 5))
          @?= Right (ValInt 7),
      --
      testCase "Add (wrong type)" $
        eval envEmpty (Add (CstInt 2) (CstBool True))
          @?= Left "Non-integer operand",
      --
      testCase "Sub" $
        eval envEmpty (Sub (CstInt 2) (CstInt 5))
          @?= Right (ValInt (-3)),
      --
      testCase "Div" $
        eval envEmpty (Div (CstInt 7) (CstInt 3))
          @?= Right (ValInt 2),
      --
      testCase "Div0" $
        eval envEmpty (Div (CstInt 7) (CstInt 0))
          @?= Left "Division by zero",
      --
      testCase "Pow" $
        eval envEmpty (Pow (CstInt 2) (CstInt 3))
          @?= Right (ValInt 8),
      --
      testCase "Pow0" $
        eval envEmpty (Pow (CstInt 2) (CstInt 0))
          @?= Right (ValInt 1),
      --
      testCase "Pow negative" $
        eval envEmpty (Pow (CstInt 2) (CstInt (-1)))
          @?= Left "Negative exponent",
      --
      testCase "Eql (false)" $
        eval envEmpty (Eql (CstInt 2) (CstInt 3))
          @?= Right (ValBool False),
      --
      testCase "Eql (true)" $
        eval envEmpty (Eql (CstInt 2) (CstInt 2))
          @?= Right (ValBool True),
      --
      testCase "If" $
        eval envEmpty (If (CstBool True) (CstInt 2) (Div (CstInt 7) (CstInt 0)))
          @?= Right (ValInt 2),
      --
      testCase "Let" $
        eval envEmpty (Let "x" (Add (CstInt 2) (CstInt 3)) (Var "x"))
          @?= Right (ValInt 5),
      --
      testCase "Let (shadowing)" $
        eval
          envEmpty
          ( Let
              "x"
              (Add (CstInt 2) (CstInt 3))
              (Let "x" (CstBool True) (Var "x"))
          )
          @?= Right (ValBool True),
      --
      -- Task 1: ForLoop.
      --
      -- The example from the assignment text: sums 0..9.
      testCase "ForLoop (sum)" $
        eval
          envEmpty
          ( ForLoop
              ("p", CstInt 0)
              ("i", CstInt 10)
              (Add (Var "p") (Var "i"))
          )
          @?= Right (ValInt 45),
      --
      -- A bound of zero means the body never runs, so we get the
      -- initial value straight back.  Note that it does not have to be
      -- an integer -- only the bound does.
      testCase "ForLoop (zero iterations)" $
        eval
          envEmpty
          (ForLoop ("p", CstBool True) ("i", CstInt 0) (CstInt 1337))
          @?= Right (ValBool True),
      --
      -- Same thing for a negative bound, where i < n is false from the
      -- start.
      testCase "ForLoop (negative bound)" $
        eval
          envEmpty
          (ForLoop ("p", CstInt 7) ("i", CstInt (-3)) (CstInt 1337))
          @?= Right (ValInt 7),
      --
      testCase "ForLoop (non-integral bound)" $
        eval
          envEmpty
          (ForLoop ("p", CstInt 0) ("i", CstBool True) (Var "p"))
          @?= Left "Non-integral loop bound",
      --
      -- An error inside the body aborts the whole loop.
      testCase "ForLoop (error in body)" $
        eval
          envEmpty
          ( ForLoop
              ("p", CstInt 1)
              ("i", CstInt 3)
              (Div (Var "p") (CstInt 0))
          )
          @?= Left "Division by zero",
      --
      -- We evaluate the initial expression before the bound, following
      -- the order the assignment gives, so when both are broken it is
      -- the error from the initial expression that comes out.
      testCase "ForLoop (initial before bound)" $
        eval
          envEmpty
          ( ForLoop
              ("p", Div (CstInt 1) (CstInt 0))
              ("i", Var "nope")
              (CstInt 0)
          )
          @?= Left "Division by zero",
      --
      -- The loop bindings are local to the body: i is not in scope once
      -- the loop is done.
      testCase "ForLoop (bindings do not escape)" $
        eval
          envEmpty
          ( Add
              (ForLoop ("p", CstInt 0) ("i", CstInt 3) (Var "p"))
              (Var "i")
          )
          @?= Left "Unknown variable: i",
      --
      -- ...and the surrounding environment is still visible inside the
      -- body: 5 added three times.
      testCase "ForLoop (outer scope visible)" $
        eval
          envEmpty
          ( Let
              "x"
              (CstInt 5)
              ( ForLoop
                  ("p", CstInt 0)
                  ("i", CstInt 3)
                  (Add (Var "p") (Var "x"))
              )
          )
          @?= Right (ValInt 15),
      --
      -- Task 2: Lambda and Apply.
      --
      -- The example from the assignment text.  Evaluating a Lambda does
      -- not touch the body, it just captures the environment.
      testCase "Lambda (captures environment)" $
        eval
          envEmpty
          (Let "x" (CstInt 2) (Lambda "y" (Add (Var "x") (Var "y"))))
          @?= Right
            (ValFun [("x", ValInt 2)] "y" (Add (Var "x") (Var "y"))),
      --
      -- Also from the assignment text.
      testCase "Apply" $
        eval
          envEmpty
          ( Apply
              (Let "x" (CstInt 2) (Lambda "y" (Add (Var "x") (Var "y"))))
              (CstInt 3)
          )
          @?= Right (ValInt 5),
      --
      testCase "Apply (non-function)" $
        eval envEmpty (Apply (CstInt 2) (CstInt 3))
          @?= Left "Cannot apply non-function",
      --
      -- Static scoping: f sees the x that was in scope where it was
      -- defined (1), not the one in scope where it is called (100).
      -- With dynamic scoping this would be 100.
      testCase "Apply (static scoping)" $
        eval
          envEmpty
          ( Let
              "x"
              (CstInt 1)
              ( Let
                  "f"
                  (Lambda "y" (Add (Var "x") (Var "y")))
                  (Let "x" (CstInt 100) (Apply (Var "f") (CstInt 0)))
              )
          )
          @?= Right (ValInt 1),
      --
      -- Functions are ordinary values, so they can be passed as
      -- arguments: this applies a doubling function to 21.
      testCase "Apply (higher order)" $
        eval
          envEmpty
          ( Apply
              ( Apply
                  (Lambda "f" (Lambda "x" (Apply (Var "f") (Var "x"))))
                  (Lambda "y" (Mul (Var "y") (CstInt 2)))
              )
              (CstInt 21)
          )
          @?= Right (ValInt 42),
      --
      -- Evaluation order: when both subexpressions fail, the error from
      -- the function expression is the one we report.
      testCase "Apply (function error wins)" $
        eval
          envEmpty
          (Apply (Var "nope") (Div (CstInt 1) (CstInt 0)))
          @?= Left "Unknown variable: nope",
      --
      -- ...and an error in the argument is reported in preference to
      -- complaining that the function is not a function.
      testCase "Apply (argument error beats non-function)" $
        eval
          envEmpty
          (Apply (CstInt 1) (Div (CstInt 1) (CstInt 0)))
          @?= Left "Division by zero",
      --
      -- APL is call-by-value: the argument is evaluated even though the
      -- body never looks at it.
      testCase "Apply (argument evaluated even if unused)" $
        eval
          envEmpty
          (Apply (Lambda "x" (CstInt 1)) (Div (CstInt 1) (CstInt 0)))
          @?= Left "Division by zero",
      --
      -- Recursion via the Y combinator, which only works once we have
      -- first-class functions.  Also shows that eval need not terminate
      -- in general.
      testCase "Apply (factorial via Y combinator)" $
        eval envEmpty (Apply fact (CstInt 5))
          @?= Right (ValInt 120),
      --
      -- Task 3: TryCatch.
      --
      testCase "TryCatch (no failure)" $
        eval envEmpty (TryCatch (CstInt 0) (CstInt 1))
          @?= Right (ValInt 0),
      --
      testCase "TryCatch (failure)" $
        eval envEmpty (TryCatch (Var "missing") (CstInt 1))
          @?= Right (ValInt 1),
      --
      -- The handler is not needed when the first expression succeeds,
      -- so its own failure is invisible.
      testCase "TryCatch (handler not used)" $
        eval envEmpty (TryCatch (CstInt 0) (Div (CstInt 1) (CstInt 0)))
          @?= Right (ValInt 0),
      --
      -- But a failure in the handler is not caught by anything.
      testCase "TryCatch (handler fails)" $
        eval
          envEmpty
          (TryCatch (Var "missing") (Div (CstInt 1) (CstInt 0)))
          @?= Left "Division by zero",
      --
      -- Nesting: the outer handler only gets a chance when both of the
      -- inner expressions have failed.
      testCase "TryCatch (nested)" $
        eval
          envEmpty
          (TryCatch (TryCatch (Var "a") (Var "b")) (CstInt 3))
          @?= Right (ValInt 3)
    ]
