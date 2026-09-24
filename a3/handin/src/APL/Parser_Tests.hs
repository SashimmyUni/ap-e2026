module APL.Parser_Tests (tests) where

import APL.AST (Exp (..))
import APL.Parser (parseAPL)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?=))

parserTest :: String -> Exp -> TestTree
parserTest s e =
  testCase s $
    case parseAPL "input" s of
      Left err -> assertFailure err
      Right e' -> e' @?= e

parserTestFail :: String -> TestTree
parserTestFail s =
  testCase s $
    case parseAPL "input" s of
      Left _ -> pure ()
      Right e ->
        assertFailure $
          "Expected parse error but received this AST:\n" ++ show e

tests :: TestTree
tests =
  testGroup
    "Parsing"
    [ testGroup
        "Constants"
        [ parserTest "123" $ CstInt 123,
          parserTest " 123" $ CstInt 123,
          parserTest "123 " $ CstInt 123,
          parserTestFail "123f",
          parserTest "true" $ CstBool True,
          parserTest "false" $ CstBool False
        ],
      testGroup
        "Basic operators"
        [ parserTest "x+y" $ Add (Var "x") (Var "y"),
          parserTest "x-y" $ Sub (Var "x") (Var "y"),
          parserTest "x*y" $ Mul (Var "x") (Var "y"),
          parserTest "x/y" $ Div (Var "x") (Var "y")
        ],
      testGroup
        "Operator priority"
        [ parserTest "x+y+z" $ Add (Add (Var "x") (Var "y")) (Var "z"),
          parserTest "x+y-z" $ Sub (Add (Var "x") (Var "y")) (Var "z"),
          parserTest "x+y*z" $ Add (Var "x") (Mul (Var "y") (Var "z")),
          parserTest "x*y*z" $ Mul (Mul (Var "x") (Var "y")) (Var "z"),
          parserTest "x/y/z" $ Div (Div (Var "x") (Var "y")) (Var "z")
        ],
      testGroup
        "Conditional expressions"
        [ parserTest "if x then y else z" $ If (Var "x") (Var "y") (Var "z"),
          parserTest "if x then y else if x then y else z" $
            If (Var "x") (Var "y") $
              If (Var "x") (Var "y") (Var "z"),
          parserTest "if x then (if x then y else z) else z" $
            If (Var "x") (If (Var "x") (Var "y") (Var "z")) (Var "z"),
          parserTest "1 + if x then y else z" $
            Add (CstInt 1) (If (Var "x") (Var "y") (Var "z"))
        ],
      testGroup
        "Function application"
        [ parserTest "x y z" $ Apply (Apply (Var "x") (Var "y")) (Var "z"),
          parserTest "x(y z)" $ Apply (Var "x") (Apply (Var "y") (Var "z")),
          parserTestFail "x if x then y else z",
          parserTest "f 1 true" $
            Apply (Apply (Var "f") (CstInt 1)) (CstBool True),
          parserTest "(f x) y" $ Apply (Apply (Var "f") (Var "x")) (Var "y"),
          parserTest "f(x)(y)" $ Apply (Apply (Var "f") (Var "x")) (Var "y"),
          parserTest "f (x + y)" $ Apply (Var "f") (Add (Var "x") (Var "y")),
          parserTest "f x + g y" $
            Add (Apply (Var "f") (Var "x")) (Apply (Var "g") (Var "y")),
          parserTest "f x * y" $ Mul (Apply (Var "f") (Var "x")) (Var "y"),
          parserTest "if f x then g y else h z" $
            If
              (Apply (Var "f") (Var "x"))
              (Apply (Var "g") (Var "y"))
              (Apply (Var "h") (Var "z")),
          parserTestFail "f x then",
          parserTestFail "f (x"
        ],
      testGroup
        "Equality and power operators"
        [ parserTest "x==y" $ Eql (Var "x") (Var "y"),
          parserTest "x**y" $ Pow (Var "x") (Var "y"),
          parserTest "x*y**z" $ Mul (Var "x") (Pow (Var "y") (Var "z")),
          parserTest "x**y*z" $ Mul (Pow (Var "x") (Var "y")) (Var "z"),
          parserTest "x+y==y+x" $
            Eql (Add (Var "x") (Var "y")) (Add (Var "y") (Var "x")),
          parserTest "x-y==z" $ Eql (Sub (Var "x") (Var "y")) (Var "z"),
          parserTest "x == y * z" $ Eql (Var "x") (Mul (Var "y") (Var "z")),
          parserTest "x**y**z" $ Pow (Var "x") (Pow (Var "y") (Var "z")),
          parserTest "(x**y)**z" $ Pow (Pow (Var "x") (Var "y")) (Var "z"),
          parserTest "x==y==z" $ Eql (Eql (Var "x") (Var "y")) (Var "z"),
          parserTest "x == (y == z)" $ Eql (Var "x") (Eql (Var "y") (Var "z")),
          parserTest "f x ** g y" $
            Pow (Apply (Var "f") (Var "x")) (Apply (Var "g") (Var "y")),
          parserTest "2 ** 3 ** 2" $ Pow (CstInt 2) (Pow (CstInt 3) (CstInt 2)),
          parserTest "x * y ** z * w" $
            Mul (Mul (Var "x") (Pow (Var "y") (Var "z"))) (Var "w"),
          parserTestFail "x = y",
          parserTestFail "x ==",
          parserTestFail "x * * y",
          parserTestFail "x ***y"
        ],
      testGroup
        "Print, put, and get"
        [ parserTest "put x y" $ KvPut (Var "x") (Var "y"),
          parserTest "get x + y" $ Add (KvGet (Var "x")) (Var "y"),
          parserTest "getx" $ Var "getx",
          parserTest "putx" $ Var "putx",
          parserTest "printx" $ Var "printx",
          parserTest "print \"foo\" x" $ Print "foo" (Var "x"),
          parserTest "print \"\" x" $ Print "" (Var "x"),
          parserTest "print \"hello world\" (x + y)" $
            Print "hello world" (Add (Var "x") (Var "y")),
          parserTest "print \"a + b == c\" 1" $ Print "a + b == c" (CstInt 1),
          parserTest "print \"foo\" x + 1" $
            Add (Print "foo" (Var "x")) (CstInt 1),
          parserTest "1 + get x" $ Add (CstInt 1) (KvGet (Var "x")),
          parserTest "get (x y)" $ KvGet (Apply (Var "x") (Var "y")),
          parserTest "put (x + 1) (get y)" $
            KvPut (Add (Var "x") (CstInt 1)) (KvGet (Var "y")),
          parserTest "put 1 2 == 3" $
            Eql (KvPut (CstInt 1) (CstInt 2)) (CstInt 3),
          parserTestFail "get",
          parserTestFail "get x y",
          parserTestFail "f get x",
          parserTestFail "put x",
          parserTestFail "print x",
          parserTestFail "print \"foo\"",
          parserTestFail "print \"foo x",
          parserTestFail "let get = 1 in get"
        ],
      testGroup
        "Lambdas"
        [ parserTest "\\x -> x + x" $ Lambda "x" (Add (Var "x") (Var "x")),
          parserTest "(\\x -> x) + x" $ Add (Lambda "x" (Var "x")) (Var "x"),
          parserTest "\\x->x" $ Lambda "x" (Var "x"),
          parserTest "(\\x -> x) y" $ Apply (Lambda "x" (Var "x")) (Var "y"),
          parserTest "\\x -> \\y -> x y" $
            Lambda "x" (Lambda "y" (Apply (Var "x") (Var "y"))),
          parserTest "\\x -> x == y" $ Lambda "x" (Eql (Var "x") (Var "y")),
          parserTest "1 + \\x -> x" $ Add (CstInt 1) (Lambda "x" (Var "x")),
          parserTest "\\x -> x - 1" $ Lambda "x" (Sub (Var "x") (CstInt 1)),
          parserTest "if x then \\y -> y else z" $
            If (Var "x") (Lambda "y" (Var "y")) (Var "z"),
          parserTestFail "\\true -> x",
          parserTestFail "\\x x",
          parserTestFail "\\ -> x",
          parserTestFail "f \\x -> x"
        ],
      testGroup
        "Let-binding"
        [ parserTest "let x = y in z" $ Let "x" (Var "y") (Var "z"),
          parserTestFail "let true = y in z",
          parserTestFail "x let v = 2 in v",
          parserTest "let x=1 in x" $ Let "x" (CstInt 1) (Var "x"),
          parserTest "let x = 1 in x + 2" $
            Let "x" (CstInt 1) (Add (Var "x") (CstInt 2)),
          parserTest "(let x = 1 in x) + 2" $
            Add (Let "x" (CstInt 1) (Var "x")) (CstInt 2),
          parserTest "let x = 1 in let y = 2 in x + y" $
            Let "x" (CstInt 1) $
              Let "y" (CstInt 2) (Add (Var "x") (Var "y")),
          parserTest "let f = \\x -> x in f 1" $
            Let "f" (Lambda "x" (Var "x")) (Apply (Var "f") (CstInt 1)),
          parserTest "let x = y == z in x" $
            Let "x" (Eql (Var "y") (Var "z")) (Var "x"),
          parserTest "let x = 1\nin x" $ Let "x" (CstInt 1) (Var "x"),
          parserTestFail "let x = 1 x",
          parserTestFail "let x == 1 in x",
          parserTestFail "let in = 1 in 2",
          parserTestFail "let 1 = x in x"
        ],
      testGroup
        "Loops"
        [ parserTest "loop x = 1 for i < n do x * 2" $
            ForLoop ("x", CstInt 1) ("i", Var "n") (Mul (Var "x") (CstInt 2)),
          parserTest "loop acc = 0 for i < 10 do acc + i" $
            ForLoop ("acc", CstInt 0) ("i", CstInt 10) (Add (Var "acc") (Var "i")),
          parserTest "loop x = f 1 for i < g n do h x i" $
            ForLoop
              ("x", Apply (Var "f") (CstInt 1))
              ("i", Apply (Var "g") (Var "n"))
              (Apply (Apply (Var "h") (Var "x")) (Var "i")),
          parserTest "(loop x = 1 for i < 3 do x) + 1" $
            Add (ForLoop ("x", CstInt 1) ("i", CstInt 3) (Var "x")) (CstInt 1),
          parserTestFail "loop x = 1 for true < n do x",
          parserTestFail "loop x = 1 for i < n x",
          parserTestFail "loop x = 1 for i = n do x",
          parserTestFail "loop x for i < n do x"
        ],
      testGroup
        "Try-catch"
        [ parserTest "try x catch y" $ TryCatch (Var "x") (Var "y"),
          parserTest "try x / 0 catch 1 + 2" $
            TryCatch (Div (Var "x") (CstInt 0)) (Add (CstInt 1) (CstInt 2)),
          parserTest "try try x catch y catch z" $
            TryCatch (TryCatch (Var "x") (Var "y")) (Var "z"),
          parserTest "try x catch try y catch z" $
            TryCatch (Var "x") (TryCatch (Var "y") (Var "z")),
          parserTest "(try x catch y) z" $
            Apply (TryCatch (Var "x") (Var "y")) (Var "z"),
          parserTestFail "try x",
          parserTestFail "try catch y"
        ],
      testGroup
        "Lexing edge cases"
        [ parserTest "2 " $ CstInt 2,
          parserTest " 2" $ CstInt 2,
          parserTest "iff" $ Var "iff",
          parserTest "letx" $ Var "letx",
          parserTest "trying" $ Var "trying",
          parserTest "x1" $ Var "x1",
          parserTest "f\n x" $ Apply (Var "f") (Var "x"),
          parserTestFail "(x",
          parserTestFail "x)",
          parserTestFail "if"
        ]
    ]
