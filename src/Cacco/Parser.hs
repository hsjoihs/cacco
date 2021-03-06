{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes        #-}
module Cacco.Parser
  ( parseTopLevel
  , parseExpr
  , parseAst
  , numeric
  ) where

import           Control.Applicative ((*>), (<*))
import           Data.Functor        (Functor)
import           Data.Text           (Text)
import           Data.Void           (Void)
import           Text.Megaparsec     (ParsecT, Token, choice, eof, many, parse,
                                      sepEndBy, try, (<?>), (<|>))
import qualified Text.Megaparsec     as Megaparsec

import           Cacco.Ann           (AnnF (AnnF))
import qualified Cacco.Ann           as Ann
import           Cacco.Expr          (Ast, AstF (..), Expr)
import           Cacco.Fix           (Fix (..))
import           Cacco.Lexer         (Parser, brackets, lexeme, parens,
                                      spaceConsumer, withLocation)
import qualified Cacco.Lexer         as Lexer
import           Cacco.Literal       (Literal (..))
import           Cacco.Location      (Location)

contents :: Parser a -> Parser a
contents parser = spaceConsumer *> parser <* eof

fixParser :: Functor f
          => (forall a. ParsecT e s m a -> ParsecT e s m (f a))
          -> ParsecT e s m (Fix f)
fixParser f = Fix <$> f (fixParser f)

addLocation :: Parser (f a) -> Parser (AnnF Location f a)
addLocation p = AnnF <$> withLocation p

undef :: Parser Literal
undef = Lexer.symbol "undefined" >> return Undef <?> "undefined"

-- decimal :: Parser Literal
-- decimal = Flonum <$> Lexer.decimal <?> "decimal literal"

numeric :: Parser Literal
numeric = try Lexer.flonum <|> Lexer.integer

text :: Parser Literal
text = Text <$> Lexer.stringLiteral

literal :: Parser Literal
literal = undef <|> Lexer.bool <|> text <|> numeric

astF :: Parser a -> Parser (AstF a)
astF p = lexeme $ choice
    [ LitF <$> try literal
    , SymF <$> Lexer.identifier
    , LisF <$> parens (elements p)
    , VecF <$> brackets (elements p)
    ]
  where
    elements :: Parser a -> Parser [a]
    elements = (`sepEndBy` spaceConsumer)

expr :: Parser (Expr Location)
expr = fixParser $ addLocation . astF

topLevel :: Parser [Expr Location]
topLevel = many expr

type SourceName = String
type SourceCode = Text

type ParseError = Megaparsec.ParseError (Token Text) Void

type FontendParser a = SourceName -> SourceCode -> Either ParseError a

frontend :: Parser a -> FontendParser a
frontend p []   = frontend p "<stdin>"
frontend p name = parse (contents p) name

parseAst :: FontendParser Ast
parseAst = frontend $ Ann.remove <$> expr

parseExpr :: FontendParser (Expr Location)
parseExpr = frontend expr

parseTopLevel :: FontendParser [Expr Location]
parseTopLevel = frontend topLevel
