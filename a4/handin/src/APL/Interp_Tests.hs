module APL.Interp_Tests (tests) where

import APL.AST (Exp (..))
import APL.Eval (eval)
import APL.InterpIO (runEvalIO)
import APL.InterpPure (runEval)
import APL.Monad
import APL.Util (captureIO)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

eval' :: Exp -> ([String], Either Error Val)
eval' = runEval . eval

evalIO' :: Exp -> IO (Either Error Val)
evalIO' = runEvalIO . eval

tests :: TestTree
tests = testGroup "Free monad interpreters" [pureTests, ioTests]

-- AI generated test from specifications.
pureTests :: TestTree
pureTests =
  testGroup
    "Pure interpreter"
    [ testCase "localEnv" $
        runEval
          ( localEnv (const [("x", ValInt 1)]) $
              askEnv
          )
          @?= ([], Right [("x", ValInt 1)]),

      testCase "Let" $
        eval' (Let "x" (Add (CstInt 2) (CstInt 3)) (Var "x"))
          @?= ([], Right (ValInt 5)),

      testCase "Let (shadowing)" $
        eval'
          ( Let
              "x"
              (Add (CstInt 2) (CstInt 3))
              (Let "x" (CstBool True) (Var "x"))
          )
          @?= ([], Right (ValBool True)),

      testCase "Print" $
        runEval (evalPrint "test")
          @?= (["test"], Right ()),

      testCase "Error" $
        runEval
          ( do
              _ <- failure "Oh no!"
              evalPrint "test"
          )
          @?= ([], Left "Oh no!"),

      testCase "Div0" $
        eval' (Div (CstInt 7) (CstInt 0))
          @?= ([], Left "Division by zero"),

      --
      -- TryCatch tests
      --

      testCase "TryCatch success" $
        eval' (TryCatch (CstInt 5) (CstInt 10))
          @?= ([], Right (ValInt 5)),

      testCase "TryCatch fallback" $
        eval' (TryCatch (Div (CstInt 1) (CstInt 0)) (CstInt 10))
          @?= ([], Right (ValInt 10)),

      testCase "TryCatch evaluates fallback only after failure" $
        eval'
          (TryCatch
            (CstInt 5)
            (Div (CstInt 1) (CstInt 0)))
          @?= ([], Right (ValInt 5)),

      testCase "TryCatch both fail" $
        eval'
          (TryCatch
            (Div (CstInt 1) (CstInt 0))
            (Div (CstInt 2) (CstInt 0)))
          @?= ([], Left "Division by zero"),

      --
      -- Key-value store tests
      --

      testCase "KvPut and KvGet" $
        runEval
          ( do
              evalKvPut (ValInt 0) (ValInt 1)
              evalKvGet (ValInt 0)
          )
          @?= ([], Right (ValInt 1)),

      testCase "KvPut overwrites existing value" $
        runEval
          ( do
              evalKvPut (ValInt 0) (ValInt 1)
              evalKvPut (ValInt 0) (ValInt 2)
              evalKvGet (ValInt 0)
          )
          @?= ([], Right (ValInt 2)),

      testCase "KvGet missing key" $
        runEval
          (evalKvGet (ValInt 99))
          @?= ([], Left "Invalid key: ValInt 99"),


      testCase "TryCatch fallback preserves successful state changes" $
        runEval
          (catch
            (failure "boom")
            (do
              evalKvPut (ValInt 1) (ValInt 42)
              pure (ValInt 0))
            >>= \_ ->
              evalKvGet (ValInt 1))
          @?= ([], Right (ValInt 42)),

      --
      -- Transaction tests
      --

      testCase "Transaction commits on success" $
        runEval
          ( do
              _ <- transaction $ do
                evalKvPut (ValInt 0) (ValInt 1)
                pure (ValInt 1)
              evalKvGet (ValInt 0)
          )
          @?= ([], Right (ValInt 1)),


      testCase "Transaction rolls back on failure" $
        runEval
          ( do
              _ <- catch
                (transaction $ do
                    evalKvPut (ValInt 0) (ValInt 1)
                    failure "failed")
                (pure (ValInt 0))
              evalKvGet (ValInt 0)
          )
          @?= ([], Left "Invalid key: ValInt 0"),


      testCase "Transaction keeps prints on failure" $
        runEval
          ( transaction $ do
              evalPrint "weee"
              failure "oh shit"
          )
          @?= (["weee"], Left "oh shit"),


      testCase "Transaction rolls back bad put" $
        eval'
          (TryCatch
            (Transaction
              (Let "_" (KvPut (CstInt 0) (CstBool False)) (Var "die")))
            (KvGet (CstInt 0)))
          @?= ([], Left "Invalid key: ValInt 0"),


      testCase "Transaction keeps good put" $
        eval'
          ( Let
              "_"
              (Transaction
                (KvPut (CstInt 0) (CstInt 1)))
              (KvGet (CstInt 0))
          )
          @?= ([], Right (ValInt 1)),

      --
      -- Break / ForLoop tests
      --

      testCase "ForLoop completes normally" $
        eval'
          (ForLoop
            ("p", CstInt 0)
            ("i", CstInt 5)
            (Add (Var "p") (CstInt 1)))
          @?= ([], Right (ValInt 5)),


      testCase "Break exits loop immediately" $
        eval'
          (ForLoop
            ("p", CstInt 0)
            ("i", CstInt 100)
            (Break (CstInt 42)))
          @?= ([], Right (ValInt 42)),


      testCase "Code after break is not executed" $
        eval'
          (ForLoop
            ("p", CstInt 0)
            ("i", CstInt 100)
            (Let "_" (Break (CstInt 10)) (CstInt 999)))
          @?= ([], Right (ValInt 10)),


      testCase "Break returns iteration variable" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("idx", CstInt 100)
            (Break (Var "idx")))
          @?= ([], Right (ValInt 0)),


      testCase "Break returns accumulator" $
        eval'
          (ForLoop
            ("acc", CstInt 5)
            ("idx", CstInt 100)
            (Break (Var "acc")))
          @?= ([], Right (ValInt 5)),


      testCase "Break outside loop fails" $
        eval'
          (Break (CstBool True))
          @?= ([], Left "Break outside loop"),


      testCase "Break at specific index using If" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("idx", CstInt 10)
            (If
              (Eql (Var "idx") (CstInt 3))
              (Break (Var "idx"))
              (Add (Var "acc") (CstInt 1))))
          @?= ([], Right (ValInt 3)),


      testCase "Break inside transaction exits loop" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("idx", CstInt 10)
            (Transaction
              (Break (CstInt 42))))
          @?= ([], Right (ValInt 42)),

      
      testCase "Break inside TryCatch exits loop" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("i", CstInt 10)
            (TryCatch
              (Break (CstInt 42))
              (CstInt 99)))
          @?= ([], Right (ValInt 42)),


      testCase "Break exits only innermost loop" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("i", CstInt 3)
            (Let
              "_"
              (ForLoop
                ("inner", CstInt 0)
                ("j", CstInt 10)
                (Break (CstInt 42)))
              (Add (Var "acc") (CstInt 1))))
          @?= ([], Right (ValInt 3)),


      testCase "Break in TryCatch fallback exits loop" $
        eval'
          (ForLoop
            ("acc", CstInt 0)
            ("i", CstInt 10)
            (TryCatch
              (Div (CstInt 1) (CstInt 0))
              (Break (CstInt 42))))
          @?= ([], Right (ValInt 42)),


      testCase "TryCatch catches break outside loop" $
        eval'
          (TryCatch
            (Break (CstInt 42))
            (CstInt 99))
          @?= ([], Right (ValInt 99))
    ]

-- AI generated test from specifications.
ioTests :: TestTree
ioTests =
  testGroup
    "IO interpreter"
    [ testCase "print" $ do
        let s1 = "Lalalalala"
            s2 = "Weeeeeeeee"
        (out, res) <-
          captureIO [] $
            runEvalIO $ do
              evalPrint s1
              evalPrint s2
        (out, res) @?= ([s1, s2], Right ()),

      testCase "print expressions" $ do
        (out, res) <-
          captureIO [] $
            evalIO' $
              Print "This is also 1" $
                Print "This is 1" $
                  CstInt 1
        (out, res)
          @?= (["This is 1: 1", "This is also 1: 1"], Right $ ValInt 1),

      --
      -- TryCatch IO tests
      --

      testCase "TryCatch IO success" $ do
        (out, res) <-
          captureIO [] $
            evalIO' $
              TryCatch
                (Print "first" (CstInt 1))
                (Print "fallback" (CstInt 2))

        (out, res)
          @?= (["first: 1"], Right (ValInt 1)),

      testCase "TryCatch IO fallback" $ do
        (out, res) <-
          captureIO [] $
            evalIO' $
              TryCatch
                (Div (CstInt 1) (CstInt 0))
                (Print "fallback" (CstInt 2))

        (out, res)
          @?= (["fallback: 2"], Right (ValInt 2)),

      --
      -- KV store IO tests
      --

      testCase "KvPut and KvGet" $ do
        res <-
          runEvalIO $ do
            evalKvPut (ValInt 1) (ValInt 42)
            evalKvGet (ValInt 1)

        res @?= Right (ValInt 42),


      testCase "KvPut overwrites existing value" $ do
        res <-
          runEvalIO $ do
            evalKvPut (ValInt 1) (ValInt 10)
            evalKvPut (ValInt 1) (ValInt 20)
            evalKvGet (ValInt 1)

        res @?= Right (ValInt 20),


      testCase "KvGet missing key uses replacement" $ do
        (out, res) <-
          captureIO ["ValInt 5"] $
            runEvalIO $
              evalKvGet (ValInt 999)

        (out, res)
          @?= ( ["Invalid key: ValInt 999. Enter a replacement: "]
              , Right (ValInt 5)
              ),


      testCase "KvGet missing key accepts booleans" $ do
        (out, res) <-
          captureIO ["ValBool True"] $
            runEvalIO $
              evalKvGet (ValInt 999)

        (out, res)
          @?= ( ["Invalid key: ValInt 999. Enter a replacement: "]
              , Right (ValBool True)
              ),


      testCase "KvGet invalid replacement input" $ do
        (out, res) <-
          captureIO ["lol"] $
            runEvalIO $
              evalKvGet (ValInt 999)

        (out, res)
          @?= ( ["Invalid key: ValInt 999. Enter a replacement: "]
              , Left "Invalid value input: lol"
              ),


      testCase "KvGet replacement is not stored" $ do
        (out, res) <-
          captureIO ["ValInt 5", "ValInt 10"] $
            runEvalIO $ do
              _ <- evalKvGet (ValInt 999)
              evalKvGet (ValInt 999)

        (out, res)
          @?=
            ( [ "Invalid key: ValInt 999. Enter a replacement: Invalid key: ValInt 999. Enter a replacement: " ]
            , Right (ValInt 10)
            ),


      testCase "TryCatch IO fallback preserves successful state changes" $ do
        res <-
          runEvalIO $
            catch
              (failure "boom")
              (do
                evalKvPut (ValInt 1) (ValInt 42)
                pure (ValInt 0))
              >>= \_ ->
                evalKvGet (ValInt 1)

        res @?= Right (ValInt 42),

      --
      -- Transaction IO tests
      --

      testCase "Transaction IO commits on success" $ do
        res <-
          runEvalIO $ do
            _ <- transaction $ do
              evalKvPut (ValInt 1) (ValInt 42)
              pure (ValInt 42)
            evalKvGet (ValInt 1)

        res @?= Right (ValInt 42),


      testCase "Transaction IO keeps print output on failure" $ do
        (out, res) <-
          captureIO [] $
            runEvalIO
              (do
                transaction $ do
                  evalPrint "before failure"
                  failure "boom")

        (out, res)
          @?= (["before failure"], Left "boom"),


      testCase "Transaction IO does not persist failed changes" $ do
        (out, res) <-
          captureIO ["ValInt 999"] $
            runEvalIO
              (do
                _ <- catch
                  (transaction $ do
                      evalKvPut (ValInt 1) (ValInt 100)
                      failure "oops")
                  (pure (ValInt 0))
                evalKvGet (ValInt 1))

        (out, res)
          @?=
            (["Invalid key: ValInt 1. Enter a replacement: "], Right (ValInt 999)),

      --
      -- Break / ForLoop IO tests
      --

      testCase "ForLoop IO completes normally" $ do
        res <-
          evalIO' $
            ForLoop
              ("p", CstInt 0)
              ("i", CstInt 5)
              (Add (Var "p") (CstInt 1))

        res @?= Right (ValInt 5),


      testCase "Break IO exits loop immediately" $ do
        res <-
          evalIO' $
            ForLoop
              ("p", CstInt 0)
              ("i", CstInt 100)
              (Break (CstInt 42))

        res @?= Right (ValInt 42),


      testCase "Break IO prevents later print" $ do
        (out, res) <-
          captureIO [] $
            evalIO' $
              ForLoop
                ("p", CstInt 0)
                ("i", CstInt 100)
                (Let
                  "_"
                  (Break (CstInt 10))
                  (Print "should not print" (CstInt 999)))

        (out, res)
          @?= ([], Right (ValInt 10)),


      testCase "Break IO at specific index" $ do
        res <-
          evalIO' $
            ForLoop
              ("acc", CstInt 0)
              ("idx", CstInt 10)
              (If
                (Eql (Var "idx") (CstInt 3))
                (Break (Var "idx"))
                (Add (Var "acc") (CstInt 1)))

        res @?= Right (ValInt 3),


      testCase "Break outside loop IO fails" $ do
        res <-
          evalIO' $
            Break (CstBool True)

        res @?= Left "Break outside loop",


      testCase "Break IO inside transaction exits loop" $ do
        res <-
          evalIO' $
            ForLoop
              ("acc", CstInt 0)
              ("idx", CstInt 10)
              (Transaction
                (Break (CstInt 42)))

        res @?= Right (ValInt 42),


      testCase "Break IO inside TryCatch exits loop" $ do
        res <-
          evalIO' $
            ForLoop
              ("acc", CstInt 0)
              ("i", CstInt 10)
              (TryCatch
                (Break (CstInt 42))
                (CstInt 99))

        res @?= Right (ValInt 42),


      testCase "Break IO exits only innermost loop" $ do
        res <-
          evalIO' $
            ForLoop
              ("acc", CstInt 0)
              ("i", CstInt 3)
              (Let
                "_"
                (ForLoop
                  ("inner", CstInt 0)
                  ("j", CstInt 10)
                  (Break (CstInt 42)))
                (Add (Var "acc") (CstInt 1)))

        res @?= Right (ValInt 3),


      testCase "Break IO in TryCatch fallback exits loop" $ do
        res <-
          evalIO' $
            ForLoop
              ("acc", CstInt 0)
              ("i", CstInt 10)
              (TryCatch
                (Div (CstInt 1) (CstInt 0))
                (Break (CstInt 42)))

        res @?= Right (ValInt 42),


      testCase "TryCatch IO catches break outside loop" $ do
        res <-
          evalIO' $
            TryCatch
              (Break (CstInt 42))
              (CstInt 99)

        res @?= Right (ValInt 99)
    ]