module APL.Eval
  ( Val (..),
    Env,
    envEmpty,
    eval,
  )
where

import APL.AST (Exp (..), VName)

data Val
  = ValInt Integer
  | ValBool Bool
  -- A function value is a closure: besides the parameter name and the
  -- body it also carries the environment from the point where the
  -- Lambda was evaluated.  That captured environment is what makes APL
  -- statically scoped.
  | ValFun Env VName Exp
  deriving (Eq, Show)

type Env = [(VName, Val)]

envEmpty :: Env
envEmpty = []

envExtend :: VName -> Val -> Env -> Env
envExtend v val env = (v, val) : env

envLookup :: VName -> Env -> Maybe Val
envLookup v env = lookup v env

type Error = String

evalIntBinOp :: (Integer -> Integer -> Either Error Integer) -> Env -> Exp -> Exp -> Either Error Val
evalIntBinOp f env e1 e2 =
  case (eval env e1, eval env e2) of
    (Left err, _) -> Left err
    (_, Left err) -> Left err
    (Right (ValInt x), Right (ValInt y)) -> case f x y of
      Left err -> Left err
      Right z -> Right $ ValInt z
    (Right _, Right _) -> Left "Non-integer operand"

evalIntBinOp' :: (Integer -> Integer -> Integer) -> Env -> Exp -> Exp -> Either Error Val
evalIntBinOp' f env e1 e2 =
  evalIntBinOp f' env e1 e2
  where
    f' x y = Right $ f x y

eval :: Env -> Exp -> Either Error Val
eval _env (CstInt x) = Right $ ValInt x
eval _env (CstBool b) = Right $ ValBool b
eval env (Var v) = case envLookup v env of
  Just x -> Right x
  Nothing -> Left $ "Unknown variable: " ++ v
eval env (Add e1 e2) = evalIntBinOp' (+) env e1 e2
eval env (Sub e1 e2) = evalIntBinOp' (-) env e1 e2
eval env (Mul e1 e2) = evalIntBinOp' (*) env e1 e2
eval env (Div e1 e2) = evalIntBinOp checkedDiv env e1 e2
  where
    checkedDiv _ 0 = Left "Division by zero"
    checkedDiv x y = Right $ x `div` y
eval env (Pow e1 e2) = evalIntBinOp checkedPow env e1 e2
  where
    checkedPow x y =
      if y < 0
        then Left "Negative exponent"
        else Right $ x ^ y
eval env (Eql e1 e2) =
  case (eval env e1, eval env e2) of
    (Left err, _) -> Left err
    (_, Left err) -> Left err
    (Right (ValInt x), Right (ValInt y)) -> Right $ ValBool $ x == y
    (Right (ValBool x), Right (ValBool y)) -> Right $ ValBool $ x == y
    (Right _, Right _) -> Left "Invalid operands to equality"
eval env (If cond e1 e2) =
  case eval env cond of
    Left err -> Left err
    Right (ValBool True) -> eval env e1
    Right (ValBool False) -> eval env e2
    Right _ -> Left "Non-boolean conditional."
eval env (Let var e1 e2) =
  case eval env e1 of
    Left err -> Left err
    Right v -> eval (envExtend var v env) e2
-- Task 1.  The assignment lists the steps in a definite order -- first
-- 'initial', then 'bound' -- and we follow it, so if both of them fail
-- it is the error from 'initial' that is reported.
--
-- The actual iteration lives in the 'loop' helper below.  It has to be
-- in the equation's 'where' rather than inside the 'case' alternative
-- (a 'where' attaches to the whole equation, not to an alternative),
-- which is why it takes the bound as a parameter instead of just
-- reaching for it.
eval env (ForLoop (p, initial) (i, bound) body) =
  case eval env initial of
    Left err -> Left err
    Right v ->
      case eval env bound of
        Left err -> Left err
        Right (ValInt n) -> loop 0 n v
        Right _ -> Left "Non-integral loop bound"
  where
    loop k n acc
      | k >= n = Right acc
      | otherwise =
          -- Note that we extend the *original* env each time rather
          -- than the one from the previous iteration; otherwise the
          -- environment would grow by two entries per iteration and the
          -- old bindings would just sit there forever.
          --
          -- The counter is bound first and the loop parameter second,
          -- matching steps 3 and 4 of the assignment, so in the
          -- degenerate case where p and i are the same name it is p
          -- that the body sees.
          case eval (envExtend p acc (envExtend i (ValInt k) env)) body of
            Left err -> Left err
            Right acc' -> loop (k + 1) n acc'
-- Task 2.  Evaluating a Lambda does not evaluate the body at all; it
-- just packages the body up together with the current environment.
eval env (Lambda var body) = Right $ ValFun env var body
-- The argument is evaluated even though it might not be needed, i.e.
-- APL is call-by-value.  The order of the alternatives below decides
-- which error we report when more than one thing is wrong: a failure
-- in e1 beats a failure in e2, and a failure in *either* beats the
-- "cannot apply non-function" complaint.
eval env (Apply e1 e2) =
  case (eval env e1, eval env e2) of
    (Left err, _) -> Left err
    (_, Left err) -> Left err
    -- f_env, not env: the body runs in the environment the function was
    -- *defined* in, extended with the parameter binding.
    (Right (ValFun f_env var body), Right arg) ->
      eval (envExtend var arg f_env) body
    (Right _, Right _) -> Left "Cannot apply non-function"
-- Task 3.  We deliberately look at the result of e1 first and only
-- mention e2 in the branch where e1 failed.  Haskell's laziness means
-- we could have got away with evaluating both up front, but writing it
-- this way makes the intent obvious.
eval env (TryCatch e1 e2) =
  case eval env e1 of
    Left _ -> eval env e2
    Right v -> Right v
