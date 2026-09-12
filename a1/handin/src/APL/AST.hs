module APL.AST
  ( VName,
    Exp (..),
    printExp,
  )
where

type VName = String

data Exp
  = CstInt Integer
  | CstBool Bool
  | Add Exp Exp
  | Sub Exp Exp
  | Mul Exp Exp
  | Div Exp Exp
  | Pow Exp Exp
  | Eql Exp Exp
  | If Exp Exp Exp
  | Var VName
  | Let VName Exp Exp
  | ForLoop (VName, Exp) (VName, Exp) Exp
  | Lambda VName Exp
  | Apply Exp Exp
  | TryCatch Exp Exp
  deriving (Eq, Show)

-- Wrap a string in parentheses.  Used by every non-atomic case of
-- printExp below.
parens :: String -> String
parens s = "(" ++ s ++ ")"

-- All the binary operators are printed the same way, so we factor that
-- out instead of writing the same line six times.
binOp :: String -> Exp -> Exp -> String
binOp op e1 e2 = parens $ printExp e1 ++ " " ++ op ++ " " ++ printExp e2

-- The printing strategy is the one the assignment text recommends:
-- *atoms* (integer and boolean constants, and variables) are printed
-- bare, and *every* other expression wraps itself in parentheses.  The
-- text says it is fine to emit more parentheses than strictly needed,
-- and this way we never have to reason about operator precedence at all.
--
-- The two parenthesisations that are *mandatory* come out for free:
--
--   * "any argument in an Apply must be parenthesized unless that
--     argument is a constant or variable" -- a non-atomic argument
--     parenthesises itself, and the atomic ones are exactly the
--     constants and variables that are allowed to be bare.
--
--   * "the function part of an Apply must be parenthesized unless it is
--     a constant, variable, or another Apply" -- same argument.  We do
--     also parenthesise a nested Apply in function position, which is
--     more than required, but that is explicitly allowed.
--
-- Note that this means even a whole top-level expression comes out
-- parenthesised, e.g. printExp (Add (CstInt 1) (CstInt 2)) == "(1 + 2)".
printExp :: Exp -> String
printExp (CstInt x) = show x
-- Lowercase, as the assignment asks -- so *not* 'show b', which would
-- give "True"/"False".
printExp (CstBool b) = if b then "true" else "false"
printExp (Var v) = v
printExp (Add e1 e2) = binOp "+" e1 e2
printExp (Sub e1 e2) = binOp "-" e1 e2
printExp (Mul e1 e2) = binOp "*" e1 e2
printExp (Div e1 e2) = binOp "/" e1 e2
printExp (Pow e1 e2) = binOp "**" e1 e2
printExp (Eql e1 e2) = binOp "==" e1 e2
printExp (If e1 e2 e3) =
  parens $
    "if " ++ printExp e1 ++ " then " ++ printExp e2 ++ " else " ++ printExp e3
printExp (Let v e1 e2) =
  parens $
    "let " ++ v ++ " = " ++ printExp e1 ++ " in " ++ printExp e2
printExp (ForLoop (p, initial) (i, bound) body) =
  parens $
    "loop "
      ++ p
      ++ " = "
      ++ printExp initial
      ++ " for "
      ++ i
      ++ " < "
      ++ printExp bound
      ++ " do "
      ++ printExp body
-- The backslash has to be escaped in the Haskell string literal, so
-- this really does print a single '\'.
printExp (Lambda v body) = parens $ "\\" ++ v ++ " -> " ++ printExp body
printExp (Apply e1 e2) = parens $ printExp e1 ++ " " ++ printExp e2
printExp (TryCatch e1 e2) =
  parens $ "try " ++ printExp e1 ++ " catch " ++ printExp e2
