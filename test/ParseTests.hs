module ParseTests (parseTests) where

import Lexer
import ParserBase

import Test.Hspec
import Test.QuickCheck

parseTests :: IO ()
parseTests = hspec $ do
  describe "Lexer" $ do
    describe "clex" $ do
      it "can identify digits, variables and exclude whitespaces." $ do
        (clex ex1Str 0) `shouldBe` ex1

      it "can ignore comments." $ do
        (clex comStr 0) `shouldBe` comToks

      it "can identify two-char operations." $ do
        (clex eqStr 0) `shouldBe` eqToks

  describe "ParserBase" $ do
    describe "pThen" $ do
      it "can partially parse a BNF greeting." $ do
        (pGreeting $ clex greetingStr 0) `shouldBe` greetingP

    describe "pThen3" $ do
      it "can completely parse a BNF greeting." $ do
        (pGreeting3 $ clex greetingStr 0) `shouldBe` greetingP3

    describe "pZeroOrMore" $ do
      it "can use a greeting BNF to parse zero or more greetings." $ do
        (pGreetingNo $ clex noGreetingStr 0) `shouldBe` noGreetingP
        (pGreetingNo $ clex greetingStr 0) `shouldBe` oneGreetingP

    describe "pOneOrMore" $ do
      it "can use a greeting BNF to parse multiple greetings." $ do
        (pGreetingMult $ clex multGreetingStr 0) `shouldBe` multGreetingP

    describe "pApply" $ do
      it "can apply a function to the results of the parse." $ do
        (pGreetingN $ clex multGreetingStr 0) `shouldBe` nGreetingP

-- | Check if lexer can digits, variables and spaces (1.6.1)

ex1Str :: String
ex1Str = "123ab  c_de"

ex1 :: [Token]
ex1 = [ (0, "123"), (0, "ab"), (0, "c_de") ]

-- | Check if the lexer can ignore comments and handle multiple lines (EX 1.9, 1.11).

comStr :: String
comStr = "123ab  -- HELLLOOOOOOO\nc_de"

comToks :: [Token]
comToks = [ (0 , "123"), (0, "ab"), (1, "c_de") ]

-- | Check if the lexer can identify 'twoCharOps' (EX 1.10)

eqStr :: String
eqStr = "123ab  ==c_de"

eqToks :: [Token]
eqToks = [ (0 , "123"), (0, "ab"), (0, "=="), (0, "c_de") ]

-- | Check if the 'pThen' can partially parse a greeting (basic BNF) (1.6.2)

pHelloOrGoodbye :: Parser String
pHelloOrGoodbye = (pLit "hello") `pAlt` (pLit "goodbye")

pGreeting :: Parser (String, String)
pGreeting = pThen mk_pair pHelloOrGoodbye pVar
  where
    mk_pair hg name = (hg, name)

greetingStr :: String
greetingStr = "goodbye James!"

greetingP :: [ ( ( String, String ), [ Token ] ) ]
greetingP = [ ( ( "goodbye", "James" ), [(0, "!")] ) ]

-- | Check if 'pThen3' can parse a greeting (basic BNF) (1.6.3)

pGreeting3 :: Parser (String, String)
pGreeting3 = pThen3 mk_greeting pHelloOrGoodbye pVar (pLit "!")
    where
      mk_greeting hg name exclamation = (hg, name)

greetingP3 :: [ ( ( String, String ), [ Token ] ) ]
greetingP3 = [ ( ( "goodbye", "James" ), [] ) ]

-- | Check if 'pZeroOrMore' can parse a greeting BNF with no greeting (EX 1.13)

noGreetingStr :: String
noGreetingStr = " "

pGreetingNo :: Parser [(String, String)]
pGreetingNo = pZeroOrMore $ pThen3 mk_greeting pHelloOrGoodbye pVar (pLit "!")
    where
      mk_greeting hg name exclamation = (hg, name)

noGreetingP :: [ ( [ ( String, String ) ], [Token] ) ]
noGreetingP = [ ( [], [] ) ]

oneGreetingP :: [ ( [ ( String, String ) ], [Token] ) ]
oneGreetingP = [ ( [( "goodbye", "James" )], [] ), ( [], [(0,"goodbye"), (0,"James"), (0,"!")] ) ]

-- | Check if 'pOneOrMore' can parse a greeting BNF with multiple greetings (EX 1.13)

multGreetingStr :: String
multGreetingStr = "goodbye James! hello Jerry!"

pGreetingMult :: Parser [(String, String)]
pGreetingMult = pOneOrMore $ pThen3 mk_greeting pHelloOrGoodbye pVar (pLit "!")
    where
      mk_greeting hg name exclamation = (hg, name)

multGreetingP :: [ ( [ ( String, String ) ], [Token] ) ]
multGreetingP = [ ([("goodbye","James"),("hello","Jerry")], []), ([("goodbye","James")], [(0,"hello"),(0,"Jerry"),(0,"!")]) ]

-- | Check if 'pApply' can count number of greetings in a greeting BNF with multiple greetings (EX 1.14)

pGreetingN :: Parser Int
pGreetingN = ( pOneOrMore $ pThen3 mk_greeting pHelloOrGoodbye pVar (pLit "!") ) `pApply` length
    where
      mk_greeting hg name exclamation = (hg, name)

nGreetingP :: [ ( Int, [Token] ) ]
nGreetingP = [ (2, []), (1, [(0,"hello"),(0,"Jerry"),(0,"!")]) ]