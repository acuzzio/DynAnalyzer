module Functions where

import Data.List.Split
import Data.List
import Text.Printf

read2 :: String -> Double
read2 x = read x :: Double

fromIntegral2 :: Int -> Double
fromIntegral2 x = fromIntegral x :: Double

writeF :: [[[String]]] -> String
writeF x  = intercalate "  \n"$ map unlines $ map (map unwords) x

avgListaListe :: [[Double]] -> [Double]
avgListaListe xss = map avg $ transpose xss

avg xs   = (sum xs)/(fromIntegral $ length xs)

printZ x    = (printf "%.2f" x) :: String

compress :: Eq a => [a] -> [a] 
compress = map head . group
