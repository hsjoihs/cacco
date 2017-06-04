{-# LANGUAGE OverloadedStrings #-}

module Cacco.ParserSpec where

import           Data.Scientific  (fromFloatDigits)
import           Test.Tasty.Hspec

import qualified Cacco.Expr       as Expr
import           Cacco.Location
import           Cacco.Parser

spec_parseExpr :: Spec
spec_parseExpr = describe "Cacco.Parser" $ do
  let testParse = parseExpr "test"
  it "can parse \"+1.0\"" $
    testParse "+1.0" `shouldBe` Right (
      Expr.Decimal (Location "test" 1 1) $ fromFloatDigits (1.0 :: Double))

  it "can parse \"(foo true false\\n undefined 2)\"" $
    testParse "(foo true false\n undefined \"hello\" 2)" `shouldBe` Right (
      Expr.List (Location "test" 1 1) [
        Expr.Atom    (Location "test" 1  2) "foo",
        Expr.Boolean (Location "test" 1  6) True,
        Expr.Boolean (Location "test" 1 11) False,
        Expr.Undef   (Location "test" 2  2),
        Expr.String  (Location "test" 2 12) "hello",
        Expr.Integer (Location "test" 2 20) 2
      ]
    )

  it "can parse expression with ignoreing line comments" $
    testParse ";; if this comments didn't ignore, this test case was failed.\ntrue" `shouldBe` Right (
      Expr.Boolean (Location "test" 2 1) True
    )

  it "can parse expression with ignoreing block comments" $
    testParse ";/ if this comments didn't ignore, this test case was failed. /;\ntrue" `shouldBe` Right (
      Expr.Boolean (Location "test" 2 1) True
    )