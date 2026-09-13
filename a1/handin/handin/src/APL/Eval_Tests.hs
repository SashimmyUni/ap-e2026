module APL.Eval_Tests (tests) where

import APL.AST (Exp (..))
import APL.Eval (Val (..), envEmpty, eval)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

-- -- Consider this example when you have added the necessary constructors.
-- -- The Y combinator in a form suitable for strict evaluation.
-- yComb :: Exp
-- yComb =
--   Lambda "f" $
--     Apply
--       (Lambda "g" (Apply (Var "g") (Var "g")))
--       ( Lambda
--           "g"
--           ( Apply
--               (Var "f")
--               (Lambda "a" (Apply (Apply (Var "g") (Var "g")) (Var "a")))
--           )
--       )

-- fact :: Exp
-- fact =
--   Apply yComb $
--     Lambda "rec" $
--       Lambda "n" $
--         If
--           (Eql (Var "n") (CstInt 0))
--           (CstInt 1)
--           (Mul (Var "n") (Apply (Var "rec") (Sub (Var "n") (CstInt 1))))

-- AI generated test from specifications.
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
      -- For Loop Tests -----------------------------------------------------------------
      testCase "For" $
        eval 
          envEmpty 
          ( ForLoop ("p", CstInt 0) ("i", CstInt 10) 
            (Add (Var "p") (Var "i"))
          )
          @?= Right (ValInt 45),
      --
      testCase "For (Bool Bound)" $
        eval 
          envEmpty 
          ( ForLoop ("p", CstInt 0) ("i", CstBool True) 
            (Add (Var "p") (Var "i"))
          )
          @?= Left "Non-integral loop bound",
      --
      testCase "For (Zero Ite)" $
        eval
          envEmpty 
          ( ForLoop ("p", CstInt 25) ("i", CstInt 0) 
            (Add (Var "p") (Var "i"))
          )
          @?= Right (ValInt 25),
      --
      testCase "For (Double)" $
        eval
          envEmpty 
          ( ForLoop ("p", CstInt 0) ("i", CstInt 3)
            ( ForLoop ("p", Var "p") ("i", CstInt 2)
              (Add (Var "p") (CstInt 1))
            )
          )
          @?= Right (ValInt 6),
      --
      testCase "For (Body Error)" $
        eval
          envEmpty 
          ( ForLoop ("p", CstInt 0) ("i", CstInt 10) 
            (Add (Var "p") (CstBool True))
          )
          @?= Left "Non-integer operand",
      --
      -- Lambda and Apply Tests -----------------------------------------------------------------
      testCase "Lambda Func" $
        eval
          envEmpty 
          (Let "x" (CstInt 2)
            ( Lambda "y" (Add (Var "x") (Var "y")))
          )
          @?= Right (ValFun [("x",ValInt 2)] "y" (Add (Var "x") (Var "y"))),
      --
      testCase "Apply" $
        eval
          envEmpty 
          (Apply 
            (Let "x" (CstInt 2) 
              (Lambda "y" (Add (Var "x") (Var "y")))
            ) 
            (CstInt 3)
          )
          @?= Right (ValInt 5),
      --
      testCase "Apply (Not type ValFun)" $
        eval
          envEmpty 
          (Apply 
            (CstInt 1) 
            (CstInt 3)
          )
          @?= Left "Apply: Left Expression not of Type ValFun",
      --
      testCase "Apply (Env Scope)" $
        eval
          envEmpty 
          (Apply
            (Apply
              (Lambda "y" (Lambda "x" (Var "y")))
              (CstInt 10)
            )
            (CstInt 5)
          )
          @?= Right (ValInt 10),
      --
      -- Try-Catch Tests -----------------------------------------------------------------
      testCase "Try-Catch (e1 succ, e2 succ)" $
        eval
          envEmpty 
          (TryCatch 
            (CstInt 0) 
            (CstInt 1)
          )
          @?= Right (ValInt 0),
      --
      testCase "Try-Catch (e1 succ, e2 fail)" $
        eval
          envEmpty 
          (TryCatch 
            (CstInt 0)
            (Var "missing")
          )
          @?= Right (ValInt 0),
      --
      testCase "Try-Catch (e1 fail, e2 succ)" $
        eval
          envEmpty 
          (TryCatch 
            (Var "missing")
            (CstInt 1)
          )
          @?= Right (ValInt 1),
      --
      testCase "Try-Catch (e1 fail, e2 fail)" $
        eval
          envEmpty 
          (TryCatch 
            (Var "missing")
            (Var "missing")
          )
          @?= Left "Unknown variable: missing"
    ]