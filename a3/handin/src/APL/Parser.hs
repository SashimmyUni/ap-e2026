module APL.Parser (parseAPL) where

import APL.AST (Exp (..), VName)
import Control.Monad (void)
import Data.Char (isAlpha, isAlphaNum, isDigit)
import Data.Void (Void)
import Text.Megaparsec
  ( Parsec,
    choice,
    chunk,
    eof,
    errorBundlePretty,
    many,
    notFollowedBy,
    parse,
    satisfy,
    some,
    try,
  )
import Text.Megaparsec.Char (char, space)

type Parser = Parsec Void String

lexeme :: Parser a -> Parser a
lexeme p = p <* space

keywords :: [String]
keywords =
  [ "if",
    "then",
    "else",
    "true",
    "false",
    "let",
    "in",
    "try",
    "catch",
    "loop",
    "for",
    "do",
    "print",
    "put",
    "get"
  ]

lVName :: Parser VName
lVName = lexeme $ try $ do
  c <- satisfy isAlpha
  cs <- many $ satisfy isAlphaNum
  let v = c : cs
  if v `elem` keywords
    then fail "Unexpected keyword"
    else pure v

lInteger :: Parser Integer
lInteger =
  lexeme $ read <$> some (satisfy isDigit) <* notFollowedBy (satisfy isAlphaNum)

lString :: String -> Parser ()
lString s = lexeme $ void $ chunk s

lKeyword :: String -> Parser ()
lKeyword s = lexeme $ void $ try $ chunk s <* notFollowedBy (satisfy isAlphaNum)

-- String literals: "..." with no double quotes inside (no escapes).
lStringLit :: Parser String
lStringLit = lexeme $ char '"' *> many (satisfy (/= '"')) <* char '"'

pBool :: Parser Bool
pBool =
  choice $
    [ const True <$> lKeyword "true",
      const False <$> lKeyword "false"
    ]

pAtom :: Parser Exp
pAtom =
  choice
    [ CstInt <$> lInteger,
      CstBool <$> pBool,
      Var <$> lVName,
      lString "(" *> pExp <* lString ")"
    ]

-- Application is juxtaposition of atoms, left associative: a b c = (a b) c.
-- The loop stops as soon as the next token is not an atom, which is why
-- every keyword must be in the keywords list (otherwise "f x then" would
-- try to apply to a variable called "then").
pFExp :: Parser Exp
pFExp = pAtom >>= chain
  where
    chain x =
      choice
        [ do
            y <- pAtom
            chain $ Apply x y,
          pure x
        ]

-- Everything here starts with a keyword (or a backslash), so choice never
-- has to backtrack over consumed input. The trailing Exps extend as far to
-- the right as possible.
pLExp :: Parser Exp
pLExp =
  choice
    [ If
        <$> (lKeyword "if" *> pExp)
        <*> (lKeyword "then" *> pExp)
        <*> (lKeyword "else" *> pExp),
      Lambda
        <$> (lString "\\" *> lVName)
        <*> (lString "->" *> pExp),
      TryCatch
        <$> (lKeyword "try" *> pExp)
        <*> (lKeyword "catch" *> pExp),
      Let
        <$> (lKeyword "let" *> lVName)
        <*> (lString "=" *> pExp)
        <*> (lKeyword "in" *> pExp),
      ForLoop
        <$> ((,) <$> (lKeyword "loop" *> lVName) <*> (lString "=" *> pExp))
        <*> ((,) <$> (lKeyword "for" *> lVName) <*> (lString "<" *> pExp))
        <*> (lKeyword "do" *> pExp),
      Print
        <$> (lKeyword "print" *> lStringLit)
        <*> pAtom,
      KvGet <$> (lKeyword "get" *> pAtom),
      KvPut
        <$> (lKeyword "put" *> pAtom)
        <*> pAtom,
      pFExp
    ]

-- ** binds tightest and is right associative, so recurse on the right
-- instead of chaining.
pExp2 :: Parser Exp
pExp2 = do
  x <- pLExp
  choice
    [ do
        lString "**"
        y <- pExp2
        pure $ Pow x y,
      pure x
    ]

pExp1 :: Parser Exp
pExp1 = pExp2 >>= chain
  where
    chain x =
      choice
        [ do
            lString "*"
            y <- pExp2
            chain $ Mul x y,
          do
            lString "/"
            y <- pExp2
            chain $ Div x y,
          pure x
        ]

pExp0 :: Parser Exp
pExp0 = pExp1 >>= chain
  where
    chain x =
      choice
        [ do
            lString "+"
            y <- pExp1
            chain $ Add x y,
          do
            lString "-"
            y <- pExp1
            chain $ Sub x y,
          pure x
        ]

-- == has the lowest precedence and is left associative.
pExp :: Parser Exp
pExp = pExp0 >>= chain
  where
    chain x =
      choice
        [ do
            lString "=="
            y <- pExp0
            chain $ Eql x y,
          pure x
        ]

parseAPL :: FilePath -> String -> Either String Exp
parseAPL fname s = case parse (space *> pExp <* eof) fname s of
  Left err -> Left $ errorBundlePretty err
  Right x -> Right x
