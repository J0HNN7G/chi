module PPrintBase where

data Iseq = INil
          | IStr String
          | IAppend Iseq Iseq
          | IIndent Iseq
          | INewline

-- | Turn an iseq into a string
iDisplay :: Iseq -> String
iDisplay iq = flatten 0 [(iq, 0)]

-- | Concatenates all iseqs in a list as a string
flatten :: Int              -- ^ Current column; 0 for first column
        -> [(Iseq, Int)]    -- ^ Work list
        -> String
flatten _ []                                   = ""
flatten col ( (INil, _) : iqs)                 = flatten col iqs
flatten col ( (IStr s, _) : iqs)               = s ++ (flatten (col + length s)  iqs)
flatten col ( (IAppend iq1 iq2, indent) : iqs) = flatten col ( (iq1, indent) : (iq2, indent) : iqs)
flatten col ( (IIndent iq, _) : iqs)           = flatten col ( (iq, col) : iqs)
flatten col ( (INewline, indent) : iqs)        = '\n' : space indent ++ (flatten indent iqs)

-- | The empty iseq
iNil :: Iseq
iNil = INil

iStr :: String -> Iseq
iStr str
  | length str == length firstLine = IStr str
  | otherwise                      = iInterleave INewline (map iStr $ lines str)
  where
    firstLine = takeWhile (/= '\n') str

iAppend :: Iseq -> Iseq -> Iseq
iAppend INil iq = iq
iAppend iq INil = iq
iAppend iq1 iq2 = IAppend iq1 iq2

iIndent  :: Iseq -> Iseq
iIndent iq = IIndent iq

-- | New line with indentation
iNewline :: Iseq
iNewline = INewline

iNum :: Int -> Iseq
iNum = iStr.show

iSpace :: Iseq
iSpace = iStr " "

iBracL :: Iseq
iBracL = iStr "("

iBracR :: Iseq
iBracR = iStr ")"

-- | List seperator
iSep :: Iseq
iSep = iConcat [ iStr ";", iNewline ]

-- | Numbers left-padded with spaces
iFWNum :: Int -> Int -> Iseq
iFWNum width n = iStr (space (width - length digits) ++ digits)
  where
    digits = show n

iConcat :: [Iseq] -> Iseq
iConcat = foldr iAppend iNil

-- | Make a numbered list of iseqs
iLayn :: [Iseq] -> Iseq
iLayn iqs = iConcat (map lay_item (zip [1..] iqs))
  where
    lay_item (n, iq) =
      iConcat [ iFWNum 4 n, iStr ") ", iIndent iq, iNewline ]

-- | Interleave an iseq between each adjacent pair
iInterleave :: Iseq -> [Iseq] -> Iseq
iInterleave _ []         = iNil
iInterleave _ [iseq]     = iseq
iInterleave sep (iq:iqs) = iConcat [iq, sep, iInterleave sep iqs]

space :: Int -> String
space n = take n (repeat ' ')
