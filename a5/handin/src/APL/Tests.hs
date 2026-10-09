module APL.Tests
  ( properties
  )
where

import APL.AST (Exp (..), VName, printExp, subExp)
import APL.Error (isVariableError, isDomainError, isTypeError)
import APL.Check (checkExp)
import APL.Eval (eval, runEval)
import APL.Parser (parseAPL)
import Test.QuickCheck
  ( Property
  , Gen
  , Arbitrary (arbitrary, shrink)
  , property
  , cover
  , checkCoverage
  , choose
  , discardAfter
  , elements
  , frequency
  , sized
  , suchThat
  , vectorOf
  , withMaxSuccess
  )

instance Arbitrary Exp where
  arbitrary = sized (genExp [])

  shrink (Add e1 e2) =
    e1 : e2 : [Add e1' e2 | e1' <- shrink e1] ++ [Add e1 e2' | e2' <- shrink e2]
  shrink (Sub e1 e2) =
    e1 : e2 : [Sub e1' e2 | e1' <- shrink e1] ++ [Sub e1 e2' | e2' <- shrink e2]
  shrink (Mul e1 e2) =
    e1 : e2 : [Mul e1' e2 | e1' <- shrink e1] ++ [Mul e1 e2' | e2' <- shrink e2]
  shrink (Div e1 e2) =
    e1 : e2 : [Div e1' e2 | e1' <- shrink e1] ++ [Div e1 e2' | e2' <- shrink e2]
  shrink (Pow e1 e2) =
    e1 : e2 : [Pow e1' e2 | e1' <- shrink e1] ++ [Pow e1 e2' | e2' <- shrink e2]
  shrink (Eql e1 e2) =
    e1 : e2 : [Eql e1' e2 | e1' <- shrink e1] ++ [Eql e1 e2' | e2' <- shrink e2]
  shrink (If cond e1 e2) =
    e1 : e2 : [If cond' e1 e2 | cond' <- shrink cond] ++ [If cond e1' e2 | e1' <- shrink e1] ++ [If cond e1 e2' | e2' <- shrink e2]
  shrink (Let x e1 e2) =
    e1 : [Let x e1' e2 | e1' <- shrink e1] ++ [Let x e1 e2' | e2' <- shrink e2]
  shrink (Lambda x e) =
    [Lambda x e' | e' <- shrink e]
  shrink (Apply e1 e2) =
    e1 : e2 : [Apply e1' e2 | e1' <- shrink e1] ++ [Apply e1 e2' | e2' <- shrink e2]
  shrink (TryCatch e1 e2) =
    e1 : e2 : [TryCatch e1' e2 | e1' <- shrink e1] ++ [TryCatch e1 e2' | e2' <- shrink e2]
  shrink _ = []

-- The keywords of the parser. A variable cannot have one of these names.
keywords :: [String]
keywords = ["if", "then", "else", "true", "false", "let", "in", "try", "catch"]

-- Mostly names of 2-4 characters, since that is what expCoverage asks for.
genVName :: Gen VName
genVName = genName `suchThat` (`notElem` keywords)
  where
    genName = do
      n <- frequency [(1, pure 1), (8, choose (2, 4)), (1, choose (5, 8))]
      c <- elements ['a' .. 'z']
      cs <- vectorOf (n - 1) $ elements $ ['a' .. 'z'] ++ ['0' .. '9']
      pure $ c : cs

-- A variable is nearly always one of those in scope. With an empty scope it
-- is always an unknown variable, so there it gets a low weight.
genLeaf :: [VName] -> Gen Exp
genLeaf vars =
  frequency
    [ (6, CstInt <$> choose (0, 5))
    , (4, CstBool <$> arbitrary)
    , (if null vars then 1 else 12, Var <$> genVar)
    ]
  where
    genVar = frequency $ (1, genVName) : [(60, elements vars) | not (null vars)]

-- The first parameter is the variables in scope. The operators have low
-- weights, as checkExp always reports a type error for them, and otherwise
-- almost no expression is without type errors. Lambda, Apply and TryCatch
-- have high weights, so that functions are often made in one place and
-- applied in another.
genExp :: [VName] -> Int -> Gen Exp
genExp vars 0 = genLeaf vars
genExp vars size =
  frequency
    [ (7, genLeaf vars)
    , (1, Add <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, Sub <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, Mul <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, Div <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, Pow <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, Eql <$> genExp vars halfSize <*> genExp vars halfSize)
    , (1, If <$> genExp vars thirdSize <*> genExp vars thirdSize <*> genExp vars thirdSize)
    , (5, do
        v <- genVName
        Let v <$> genExp vars halfSize <*> genExp (v : vars) halfSize)
    , (8, do
        v <- genVName
        Lambda v <$> genExp (v : vars) (size - 1))
    , (6, Apply <$> genExp vars halfSize <*> genExp vars halfSize)
    , (7, TryCatch <$> genExp vars halfSize <*> genExp vars halfSize)
    ]
  where
    halfSize = size `div` 2
    thirdSize = size `div` 3

expCoverage :: Exp -> Property
expCoverage e = checkCoverage
  . cover 20 (any isDomainError (checkExp e)) "domain error"
  . cover 20 (not $ any isDomainError (checkExp e)) "no domain error"
  . cover 20 (any isTypeError (checkExp e)) "type error"
  . cover 20 (not $ any isTypeError (checkExp e)) "no type error"
  . cover 5 (any isVariableError (checkExp e)) "variable error"
  . cover 70 (not $ any isVariableError (checkExp e)) "no variable error"
  . cover 50 (or [2 <= n && n <= 4 | Var v <- subExp e, let n = length v]) "non-trivial variable"
  $ ()

parsePrinted :: Exp -> Bool
parsePrinted e = parseAPL "" (printExp e) == Right e

-- A generated program can loop forever, for example by applying a function
-- to itself, so a test that takes more than 0.1 seconds is discarded.
onlyCheckedErrors :: Exp -> Property
onlyCheckedErrors e = discardAfter 100000 $ case runEval (eval e) of
  Left err -> err `elem` checkExp e
  Right _ -> True

-- The number of tests is part of the specification of this test suite: some of
-- these properties fail only rarely.  Do not reduce it.
properties :: [(String, Property)]
properties =
  [ ("expCoverage", property $ withMaxSuccess 10000 expCoverage)
  , ("parsePrinted", property $ withMaxSuccess 10000 parsePrinted)
  , ("onlyCheckedErrors", property $ withMaxSuccess 10000 onlyCheckedErrors)
  ]
