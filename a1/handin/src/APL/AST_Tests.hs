module APL.AST_Tests (tests) where

import APL.AST (Exp (..), printExp)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

tests :: TestTree
tests =
  testGroup
    "Prettyprinting"
    -- Atoms are the only expressions printed without parentheses.
    [ testCase "CstInt" $
        printExp (CstInt 42) @?= "42",
      --
      testCase "CstInt (negative)" $
        printExp (CstInt (-1)) @?= "-1",
      --
      -- Lowercase, unlike Haskell's own show.
      testCase "CstBool (true)" $
        printExp (CstBool True) @?= "true",
      --
      testCase "CstBool (false)" $
        printExp (CstBool False) @?= "false",
      --
      testCase "Var" $
        printExp (Var "x") @?= "x",
      --
      -- One test per operator, mostly to catch a copy-paste slip in the
      -- six near-identical cases.
      testCase "Add" $
        printExp (Add (CstInt 2) (CstInt 3)) @?= "(2 + 3)",
      --
      testCase "Sub" $
        printExp (Sub (CstInt 2) (CstInt 3)) @?= "(2 - 3)",
      --
      testCase "Mul" $
        printExp (Mul (CstInt 2) (CstInt 3)) @?= "(2 * 3)",
      --
      testCase "Div" $
        printExp (Div (CstInt 2) (CstInt 3)) @?= "(2 / 3)",
      --
      -- Exponentiation uses **, not ^.
      testCase "Pow" $
        printExp (Pow (CstInt 2) (CstInt 3)) @?= "(2 ** 3)",
      --
      testCase "Eql" $
        printExp (Eql (CstInt 2) (CstInt 3)) @?= "(2 == 3)",
      --
      -- Nesting on either side; every compound subexpression brings its
      -- own parentheses, so we never need to think about precedence.
      testCase "Add (nested right)" $
        printExp (Add (CstInt 1) (Mul (CstInt 2) (CstInt 3)))
          @?= "(1 + (2 * 3))",
      --
      testCase "Add (nested left)" $
        printExp (Add (Add (CstInt 1) (CstInt 2)) (CstInt 3))
          @?= "((1 + 2) + 3)",
      --
      testCase "If" $
        printExp (If (CstBool True) (CstInt 1) (CstInt 2))
          @?= "(if true then 1 else 2)",
      --
      testCase "Let" $
        printExp (Let "x" (CstInt 1) (Add (Var "x") (CstInt 2)))
          @?= "(let x = 1 in (x + 2))",
      --
      testCase "ForLoop" $
        printExp
          ( ForLoop
              ("p", CstInt 0)
              ("i", CstInt 10)
              (Add (Var "p") (Var "i"))
          )
          @?= "(loop p = 0 for i < 10 do (p + i))",
      --
      testCase "Lambda" $
        printExp (Lambda "x" (Add (Var "x") (CstInt 1)))
          @?= "(\\x -> (x + 1))",
      --
      testCase "TryCatch" $
        printExp (TryCatch (Var "x") (CstInt 0))
          @?= "(try x catch 0)",
      --
      -- The Apply rules are the only ones the assignment makes
      -- mandatory, so they get a test each.  A variable argument stays
      -- bare...
      testCase "Apply (variable argument)" $
        printExp (Apply (Var "f") (Var "x")) @?= "(f x)",
      --
      -- ...so does a constant one...
      testCase "Apply (constant argument)" $
        printExp (Apply (Var "f") (CstInt 1)) @?= "(f 1)",
      --
      -- ...but anything else has to be parenthesised.
      testCase "Apply (compound argument)" $
        printExp (Apply (Var "f") (Add (CstInt 1) (CstInt 2)))
          @?= "(f (1 + 2))",
      --
      -- A nested Apply in function position is allowed to be bare, but
      -- we parenthesise it anyway; the text says extra parentheses are
      -- fine.
      testCase "Apply (nested in function position)" $
        printExp (Apply (Apply (Var "f") (Var "x")) (Var "y"))
          @?= "((f x) y)",
      --
      testCase "Apply (lambda in function position)" $
        printExp (Apply (Lambda "x" (Var "x")) (CstInt 1))
          @?= "((\\x -> x) 1)"
    ]
