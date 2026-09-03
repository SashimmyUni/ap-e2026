module APL.AST
  (
    Exp(..)
    Val(..)
  )
where

data Exp
  = CstInt Integer
  deriving (Eq, Show)

data Val
  = ValInt Integer
  deriving (Eq, Show)

eval :: Exp -> Val
eval (CstInt n) = ValInt n

