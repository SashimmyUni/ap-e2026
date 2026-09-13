module APL.AST_Tests (tests) where

import APL.AST (Exp (..), printExp)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

-- AI generated test from specifications.
tests :: TestTree
tests =
  testGroup
    "Prettyprinting"
    [ testCase "Constants and Arithmetic" $ do
        printExp 
          (CstInt 42) 
            @?= "42"
        printExp 
          (CstBool True) 
            @?= "True"
        printExp 
          (Add 
            (CstInt 1) 
            (Mul 
              (CstInt 2) 
              (CstInt 3)
            )
          )
            @?= "(1 + (2 * 3))",
      --
      testCase "Variables, Let and If" $ do
        printExp
          (Let "x" (CstInt 5)
            (If 
              (Eql 
                (Var "x") 
                (CstInt 5)
              )
              (Var "x")
              (CstInt 0)
            )
          )
          @?= "(let x = 5 in (if ((var x) == 5) then (var x) else 0))",
      --
      testCase "Lambda and Apply" $
        printExp
          (Apply
            (Lambda "x" 
              (Add 
                (Var "x") 
                (CstInt 1)
              )
            )
            (CstInt 5)
          )
            @?= "((\\x -> ((var x) + 1)) 5)",
      --
      testCase "TryCatch" $
        printExp
          (TryCatch
            (Div 
              (CstInt 10) 
              (CstInt 0)
            )
            (CstInt 0)
          )
            @?= "(try (10 / 0) catch 0)"
    ]