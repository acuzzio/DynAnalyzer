import System.ShQQ
import Text.Printf
import Data.List.Split
import Data.List
import Control.Applicative
import Data.Char (isDigit)

import IntCoor
import CreateInfo
import Inputs

data DinamicV = DinamicV {
          getDynN        :: [String]
         ,getStepN       :: [String]
         ,getS1OrS2      :: [String]
         ,getHopYesNo    :: [String]
         ,getCT          :: [String]
         ,getBetaDih     :: [String]
         ,getCcccDih     :: [String]
         ,getTau         :: [String]
         ,getDeltaOp     :: [String]
         ,getBlaV        :: [String]
          } deriving Show

main = do 
     outs <- readShell $ "ls " ++ folder ++ "/*.info"
     let outputs = lines outs
     mapM_ (createDATA betaList ccccList) outputs

--createData :: FilePath -> IO DinamicV
createDATA betaList ccccList fn = do
    a             <- rdInfoFile fn
    let dataname  = (takeWhile (/= '.') fn ) ++ ".data"
        dynNum    = reverse $ takeWhile (isDigit) $ reverse $ takeWhile (/= '.') fn
        dynN      = take (length isS1) $ repeat dynNum
        stepN     = take (length isS1) $ map show [1..]
        isS1      = rootDiscov a
        atomN     = getAtomN a 
        justHop   = justHopd a
        cT        = getCharTran a
        betaV     = diHedro betaList atomN a 
        ccccV     = diHedro ccccList atomN a
        tauV      = zipWith (\x y -> (x+y)*0.5) betaV ccccV
        deltaV    = zipWith (-) ccccV betaV
        blaV      = blaD atomN a
--        st        = map show
        prt       = map (\x -> printf "%.3f" x :: String)
        pr        = printWellSpacedColumn . prt
        pw        = printWellSpacedColumn
        dynV      = DinamicV (pw dynN) (pw stepN) isS1 justHop (pr cT) (pr betaV) (pr ccccV) (pr tauV) (pr deltaV) (pr blaV)
    writeFile dataname $ printDinColumn dynV

printWellSpacedColumn xs = let 
    matchLength n str = if length str == n then str else matchLength n $ " " ++ str
    maxLength = maximum $ map length xs
    in map (matchLength maxLength) xs


--printDinColumn :: DinamicV -> String
printDinColumn dE = let trans = transposeDynV dE
                    in unlines $ map (" " ++) $ map unwords trans

transposeDynV dE = getZipList $ (\aaa aa a b c d e f g h -> aaa:aa:a:b:c:d:e:f:g:h:[]) <$> ZipList (getDynN dE) <*> ZipList (getStepN dE) <*> ZipList (getBetaDih dE) <*> ZipList (getCcccDih dE) <*> ZipList (getTau dE) <*> ZipList (getDeltaOp dE) <*> ZipList (getBlaV dE) <*> ZipList (getCT dE) <*> ZipList (getS1OrS2 dE) <*> ZipList (getHopYesNo dE) 

joinAllDATA :: IO ()
joinAllDATA = do 
    outs <- readShell $ "ls " ++ folder ++ "/*.data"
    let outputs = lines outs
    dataContent  <- mapM readFile outputs
    writeFile (folder ++ "-all.data") $ intercalate "  \n" dataContent  

tempFunction :: IO()
tempFunction = do 
    outs         <- readShell $ "ls " ++ folder ++ "/*.data"
    let outputs  = lines outs
    dataContent  <- mapM readFile outputs
    let stringZ  = map (map words) $ map lines dataContent
        getCCCC  = map (map (\a -> [a!!0,a!!1,a!!3])) stringZ
        getHOP0  = map (map (\a -> [a!!0,a!!1,a!!3])) $ filter (\x -> x /= []) $ map (filter (\x-> x!!9 == "Y0")) stringZ
        getHOP1  = map (map (\a -> [a!!0,a!!1,a!!3])) $ filter (\x -> x /= []) $ map (filter (\x-> x!!9 == "Y1")) stringZ
        getAVGD  = map (map (\a -> read (a!!3) :: Double)) $ transpose $ map (filter (\x-> x!!8 == "S1")) stringZ
        avg xs   = (sum xs)/(fromIntegral $ length xs)
        avgZip   = zip [1..] $ map avg getAVGD
        form (a,b) = [show a,show b]
        ccccAVG  = unlines $ take 100 $ map unwords $ map form avgZip
        writeF x = intercalate "  \n"$ map unlines $ map (map unwords) x
        cccc     = writeF getCCCC
        ccccHOP0 = writeF getHOP0
        ccccHOP1 = writeF getHOP1
        -- SUPER DUPER CODE   
        hopOrNot = map (all (\x -> x == "no")) $ map (map (\x-> x!!9)) stringZ
        whoNotHop    = map fst $filter (\x-> snd x == True) $ zip [0..] hopOrNot  
        countTrue xs = sum $ map (\x -> if x == True then 1 else 0) xs
        notHopped   = countTrue hopOrNot
        hopped      = (length hopOrNot) - (countTrue hopOrNot)
        longitudine = unlines $ map (unwords . form) $ zip [0..] $ map length stringZ
    putStrLn longitudine
    putStrLn $ "Hopped:     " ++ (show hopped)
    putStrLn $ "Not Hopped: " ++ (show notHopped)
    putStrLn $ unwords $ map show whoNotHop
    putStrLn "Not Isomerize:"
    putStrLn $ show $ length $ filter (\x -> x < -90 && x > -270) $ (\x -> x!!196) $ map (map (\a -> read (a!!3) :: Double)) $ transpose stringZ
    putStrLn "Isomerize:"
    putStrLn $ show $ length $ filter (\x -> x > -90) $ (\x -> x!!196)  $ map (map (\a -> read (a!!3) :: Double)) $ transpose stringZ 
        -- END OF SUPERDUPER
    writeFile "CCCC" cccc
    writeFile "CCCCHOPS0" ccccHOP0
    writeFile "CCCCHOPS1" ccccHOP1
    writeFile "CCCCS1AVG" ccccAVG

energyDiff :: Dinamica -> [Double]
energyDiff dyn = let (pop1,pop2,s0,s1,dynDyn) = getEnergies dyn
                 in zipWith (-) s1 s0

justHopd :: Dinamica -> [String]
justHopd dyn = let (pop1,pop2,s0,s1,dynDyn) = getEnergies dyn
                   changed (x:[]) = "no":[]
                   changed (x:xs) = if x==(head xs) 
                                       then "no" : changed xs 
                                       else if x == True then "Y0" : changed xs else "Y1" : changed xs
                   truefalse = zipWith (==) s1 dynDyn
                   cngTF     = changed truefalse
               in "no":"no":cngTF

rootDiscov :: Dinamica -> [String]
rootDiscov dyn = let (pop1,pop2,s0,s1,dynDyn) = getEnergies dyn
                     first = zipWith (\x y -> if x==y then "S1" else "S0") s1 dynDyn                      
                 in "S1":"S1":first

printWellAverages :: [[Double]] -> String
printWellAverages xs = unlines $ map unwords (map (map show) $ take 200 (transpose xs))

printWellList :: [Double] -> IO()
printWellList xs = putStrLn $ unlines $ map show xs

avgListaListe :: [[Double]] -> [Double]
avgListaListe xss = let avg xs = (sum xs)/(fromIntegral $ length xs) 
                    in map avg $ transpose xss

hoppedYesNo :: Dinamica -> Bool
hoppedYesNo dyn = let
  (_,_,_,s1Energies,dynEnergies) = getEnergies dyn
  in if s1Energies/=dynEnergies then True else False
  
correct :: Double -> Double -> Double
correct x y = let
              a = abs $ x - y
              b = abs $ x - (y + 360)
              c = abs $ x - (y - 360)
              f = minimum [a,b,c]
              in if a == f
                 then y else if b == f then (y + 360) else (y - 360) 

corrDihedro :: [Double] -> [Double]
corrDihedro (a:b:[]) = a : (correct a b) : []
corrDihedro (a:b:xs) = a : corrDihedro ((correct a b) : xs)

corrDihedro2 :: [Double] -> [Double]
corrDihedro2 xl = let shiftDown x = if x > 90.0 then x-360.0 else x
                  in map shiftDown xl

diHedro :: [Int] -> Int -> Dinamica -> [Double]
diHedro aL aN dyn = let 
    aLIndex = map pred aL
    dihedr  = chunksOf aN $ getCoordinates dyn
    dihedrV = map dihedral $ map (\x -> map ( x !!) aLIndex) dihedr
    in corrDihedro2 dihedrV

bonD :: [Int] -> Int -> Dinamica -> [Double]
bonD aL aN dyn = let
    bonds   = chunksOf aN $ getCoordinates dyn
    bondV   = map bond $ map (\x -> map ( x !!) aL) bonds
    in bondV

blaD :: Int -> Dinamica -> [Double]
blaD aN dyn = let
    blaDs = chunksOf aN $ getCoordinates dyn
    blaDV = map (blaPSB3 blaList) blaDs
    in blaDV

blaPSB3 :: [[(Int,Int)]] -> [Vec Double] -> Double
blaPSB3 blaList list = let
        (a:b:c:[])      = blaList !! 0 
        (d:e:[])        = blaList !! 1
        blaBond (fS,sN) = bond [list!!(pred fS),list!!(pred sN)]
        doubles         = (blaBond a + blaBond b + blaBond c) / 3
        singles         = (blaBond d + blaBond e) / 2
        res             = singles - doubles
        in res

