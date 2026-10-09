module APL.InterpPure (runEval) where

import APL.Monad

runEval :: EvalM a -> ([String], Either Error a)
runEval m =
  let (output, _, result) = runEval' envEmpty stateInitial m
   in (output, result)
  where
    runEval' :: Env -> State -> EvalM a -> ([String], State, Either Error a)
    runEval' _ s (Pure x) = ([], s, pure x)
    runEval' r s (Free (ReadOp k)) = runEval' r s $ k r
    runEval' r s (Free (PrintOp p m_)) =
      let (msg1, s1, r1) = runEval' r s m_
       in (p : msg1, s1, r1)
    runEval' _ s (Free (ErrorOp e)) = ([], s, Left e)
    runEval' r s (Free (TryCatchOp v1 v2 k)) =
      let (msg1, s1, r1) = runEval' r s v1
       in case r1 of
        Right x ->
          let (msg2, s2, r2) = runEval' r s1 (k x)
           in (msg1 ++ msg2, s2, r2)
        Left _ ->
          let (msg2, s2, r2) = runEval' r s v2
           in case r2 of
            Right y ->
              let (msg3, s3, r3) = runEval' r s2 (k y)
               in (msg1 ++ msg2 ++ msg3, s3, r3)
            Left err -> (msg1 ++ msg2, s2, Left err)
    runEval' r s (Free (KvGetOp v1 k)) =
      case lookup v1 s of
        Nothing -> ([], s, Left ("Invalid key: " ++ show v1))
        Just val -> runEval' r s (k val)
    runEval' r s (Free (KvPutOp v1 v2 k)) =
      runEval' r s1 k
      where
        s1 = filter (\(key, _) -> key /= v1) s ++ [(v1, v2)]
    runEval' r s (Free (TransactionOp v1 k)) =
      let (msg1, s1, r1) = runEval' r s v1
       in case r1 of
        Left err ->
          (msg1, s, Left err)
        Right x ->
          let (msg2, s2, r2) = runEval' r s1 (k x)
           in (msg1 ++ msg2, s2, r2)
    runEval' _ s (Free (BreakOp _)) = ([], s, Left ("Break outside loop"))