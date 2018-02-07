{-# LANGUAGE DeriveDataTypeable #-}

module Cacco.Ast
  ( Ast(..)
  , pureAst
  ) where

import           Cacco.Literal (Literal)
import           Data.Functor  ((<$>))
import           Data.Typeable (Typeable)

data Ast a
  -- | Undefined literal
  = Literal Literal
  -- | Symbol
  | Symbol  String
  -- | Linked List
  | List    [Ast a]
  -- | Vector
  | Vector  [Ast a]
  -- | Ast with something meta data
  | With    a (Ast a)
  deriving (Eq, Ord, Show, Typeable)

pureAst :: Ast a -> Ast a
pureAst x = case x of
  (Literal _) -> x
  (Symbol  _) -> x
  (With _  y) -> pureAst y
  (List   xs) -> List $ pureAst <$> xs
  (Vector xs) -> Vector $ pureAst <$> xs
