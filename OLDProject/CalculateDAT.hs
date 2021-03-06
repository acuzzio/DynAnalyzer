module CalculateDAT where

import System.ShQQ
import System.Directory
import System.Process
import Text.Printf
import Data.List.Split
import Data.List
import Control.Applicative
import Data.Char (isDigit)

import IntCoor
import CreateInfo
import Inputs
import Mapped
import Functions
import GnuplotZ

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

reminder="\nRemember do not put POINTs in the whole filePAth, nor NUMBERS after the LABEL number\n folder/geom001.info    -> This is right!!! \n fol.der/ge.om001.info  -> those points will mess up everything !!\n folder/geom002PT2.info -> that 2 in the namefile after the right traj label (023) will mess up everything \n Alessio, just make some CHECKS !!! come on !!!\n\n"

tryCorrections = do
    outs <- readShell $ "ls " ++ folder ++ "/*.info"
    let outputs = lines outs
    a <- mapM (tryCorrection ccccList) outputs
    let stringZ = map (map words) $ map lines a
    putStrLn reminder 
    chargeTmap stringZ "TOT" [0.4,0.5,0.6]
    let sZeroOnly = map (filter (\x -> x!!8 == "S0")) stringZ
    chargeTmap sZeroOnly "S0" [0.4,0.5,0.6]
    writeFile (folder ++ "Corrected") $ unlines a

tryCorrection ccccList fn = do
    a             <- rdInfoFile fn
    let rlxR      = getStartRlxRt a
        dynNum    = reverse $ takeWhile (isDigit) $ reverse $ takeWhile (/= '.') fn
        isS1      = rootDiscov a rlxR
        dynN      = take (length isS1) $ repeat dynNum
        stepN     = take (length isS1) $ map show [1..]
        atomN     = getAtomN a 
        justHop   = justHopd a rlxR
        ccccV     = corrDihedro3 $ diHedro ccccList atomN a
        cT        = calculateCT atomN $ getCharTran a
        betaV     = corrDihedro3 $ diHedro betaList atomN a 
        tauV      = zipWith (\x y -> (x+y)*0.5) betaV ccccV
        deltaV    = zipWith (-) ccccV betaV
        blaV      = blaD atomN a
--        st        = map show
        prt       = map (\x -> printf "%.3f" x :: String)
        pr        = printWellSpacedColumn . prt
        pw        = printWellSpacedColumn
        dynV      = [(pw dynN), (pw stepN), (pr ccccV), (pr betaV), (pr tauV), (pr deltaV), (pr blaV), (pr cT), isS1, justHop]
    return $ unlines $ map unwords $ transpose dynV

corrDihedro3 :: [Double] -> [Double]
corrDihedro3 dihedList = let
   firstDih = head dihedList
   corr  x  = corrDihedro $ corrDihedro x
   in case isDihCloser firstDih 0 180 of
           0   -> corr dihedList
           180 -> if firstDih < 0 then corr dihedList else corr $ map (\x -> x-360.0) dihedList

createDATAs = do 
   outs <- readShell $ "ls " ++ folder ++ "/*.info"
   let outputs = lines outs
   mapM_ (createDATA betaList ccccList) outputs

--createData :: FilePath -> IO DinamicV
createDATA betaList ccccList fn = do
    a             <- rdInfoFile fn
    let dataname  = (takeWhile (/= '.') fn ) ++ ".data"
        rlxR      = getStartRlxRt a
        dynNum    = reverse $ takeWhile (isDigit) $ reverse $ takeWhile (/= '.') fn
        isS1      = rootDiscov a rlxR
        dynN      = take (length isS1) $ repeat dynNum
        stepN     = take (length isS1) $ map show [1..]
        atomN     = getAtomN a 
        justHop   = justHopd a rlxR
        cT        = calculateCT atomN $ getCharTran a
        betaV     = corrDihedro2 $ diHedro betaList atomN a 
        ccccV     = corrDihedro2 $ diHedro ccccList atomN a
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

readData :: FilePath -> IO [[String]]
readData fn = do 
    dataContent  <- readFile fn
    return $ map words $ lines dataContent

--rotationDirections :: IO()
rotationDirections  = do
    outs <- readShell $ "ls " ++ folder ++ "/*.info"
    let outputs = lines outs
    mapM_ rotationDirection outputs

safeLast [] = (9999.9,"toRemove") -- 9999.9 is just a Double flag... 
safeLast x  = last x -- obviously a dihedral cannot be 9999.9, so I use it as a filter

rotationDirection fn = do
    a             <- rdInfoFile fn
    let atomN     = getAtomN a 
        rlxR      = getStartRlxRt a
        ccccV     = diHedro ccccList atomN a
        justHop   = justHopd a rlxR
        zipList   = zip ccccV justHop
        firstEl   = head zipList
        hopOnly   = safeLast $ filter (\x -> snd x == "10") zipList
        lastEl    = last zipList
--    print $ map fst [firstEl, hopOnly, lastEl] 
    putStrLn $ wiseOrNot (fst hopOnly) fn

wiseOrNot x fn = if x == 9999.9 
                 then fn ++ " -> " ++ "This traj did non HOP" 
                 else let 
                      y = isDihCloser x (-90) 90
                      z = if y == 90 then "        Dx" else "Sx"
                      in fn ++ " -> " ++ z

-- is dihedral angle (float :: Double) closer to (first :: Int) or (second :: Int) ? 
isDihCloser :: Double -> Int -> Int -> Int
isDihCloser float first second = let
   integ      = floor float :: Int
   a          = integ - 179
   b          = integ + 180
   downward y = if y > 180 then y - 360 else y
   upward   y = if y <= (-180) then y + 360 else y
   posOrNeg   = if signum float == 1 then map downward [a..b] else map upward [a..b]
   Just fir   = elemIndex first posOrNeg
   Just sec   = elemIndex second posOrNeg
   one        = abs (179 - fir) -- integ will always be at index 179 in this array
   two        = abs (179 - sec)
   in if one < two then first else second
   
calculateCT :: Int -> [Double] -> [Double]
calculateCT a xs = let 
    dividedGeometries   = chunksOf a xs
    chargeTrFragmentI   = map pred chargeTrFragment
    sumUp4CT x          = sum $ map (x!!) chargeTrFragmentI
    in map sumUp4CT dividedGeometries

justHopd :: Dinamica -> Int -> [String]
justHopd dynam rlxD = let 
    state a         = dropWhile ('S'==) a 
    listaRoot       = rootDiscov dynam rlxD
    changE (x:[])   = "no":[]
    changE (x:xs)   = if x == (head xs) 
                        then "no" : changE xs 
                        else ((state x) ++  (state (head xs))) : changE xs
    cngTF           = changE listaRoot
    in cngTF

rootDiscov :: Dinamica -> Int -> [String]
rootDiscov dynam rlxD = let 
    energy         = getEnergies dynam
    rootS          = div (length energy - 1) 2
    [popu,ene,dyn] = chunksOf rootS energy
    startingRootS  = "S" ++ (show $ pred rlxD) -- first two steps... no tully no party
    getI ls nu     = snd $ head $ dropWhile (\x-> fst x /= nu) $ zip ls [0..]
    rightRootI     = zipWith getI (transpose ene) (head dyn)
    rightRootS     = map (\x -> "S" ++ (show x)) rightRootI 
    in startingRootS:startingRootS:rightRootS

printWellAverages :: [[Double]] -> String
printWellAverages xs = unlines $ map unwords (map (map show) $ take 200 (transpose xs))

printWellList :: [Double] -> IO()
printWellList xs = putStrLn $ unlines $ map show xs

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
corrDihedro2 xl = let shiftDown x = if x > upperLimit then x-360.0 else x
                  in map shiftDown xl

diHedro :: [Int] -> Int -> Dinamica -> [Double]
diHedro aL aN dyn = let 
    aLIndex = map pred aL
    dihedr  = chunksOf aN $ getCoordinates dyn
    dihedrV = map dihedral $ map (\x -> map ( x !!) aLIndex) dihedr
    in dihedrV

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

averageSublist :: [[[String]]] -> [Int] -> Int -> Int -> [Double]
averageSublist stringOne trajxs index thres = let
    rightTrajectories = map (stringOne !!) trajxs
    rightValue        = map (map (\x -> x!!index)) rightTrajectories
    rightFloat        = map (map (\x -> read x :: Double)) rightValue
    in map avg $ take thres $ transpose rightFloat

genTrajectory :: FilePath -> IO()
genTrajectory fn = do
  a <- rdInfoFile fn
  let dynname   = (takeWhile (/= '.') fn ) ++ ".md.xyz"
      atomT     = getAtomT a
      coords    = chunksOf atomN $ map (unwords . (map show) . runVec) $ getCoordinates a
      atomN     = getAtomN a
      header x  = (show atomN) ++ "\n \n" ++ x
      coordsAndType = zipWith (zipWith (\x y -> x ++ " " ++ y)) (repeat atomT) coords
      divided   = concat $ map (header . unlines) coordsAndType
      foldTraj  = folder ++ "/Trajectories"
  createDirectoryIfMissing True foldTraj
  writeFile dynname divided
  system $ "mv " ++ dynname ++ " " ++ foldTraj
  putStrLn $ dynname ++ ": Done"

genTrajectories :: IO()
genTrajectories = do
   outs <- readShell $ "ls " ++ folder ++ "/*.info"
   let outputs = lines outs
   mapM_ genTrajectory outputs

-- those corrections are to make smooth gnuplot lines
chargeTsingle :: [[[String]]] -> String -> Double -> IO()
chargeTsingle stringZ filtername thresh = do
    let upper       = map (filter (\x -> read2 (x!!7) > thresh)) stringZ
        lower       = map (filter (\x -> read2 (x!!7) < thresh)) stringZ
        upperCorr   = map compress $ zipWith correctGaps upper stringZ
        lowerCorr   = map compress $ zipWith correctGaps lower stringZ
    writeFile (folder ++ "cT" ++ (show thresh) ++ "HI" ++ filtername) $ writeF upperCorr
    writeFile (folder ++ "cT" ++ (show thresh) ++ "LO" ++ filtername) $ writeF lowerCorr

chargeTmap :: [[[String]]] -> String -> [Double] -> IO()
chargeTmap stringZ filtername list = mapM_ (chargeTsingle stringZ filtername) list

-- I wanna make a space for each nonconsecutive point in the splot (!!1 is the STEP)
correctLines :: [[String]] -> [[String]]
correctLines  []     = []
correctLines  (x:[]) = x:[]  
correctLines  (x:xs) = let
    readI y = read (y!!1) :: Int
    a       = readI x
    b       = readI $ head xs
    in if (a+1) == b then x : correctLines xs else x : [" "] : correctLines xs 

-- I wanna fill the space between two different set in gnuplot splot lines
correctGaps :: [[String]] -> [[String]] -> [[String]]
correctGaps []    a      = []
correctGaps small (x:[]) = x : []
correctGaps small (x:xs) = if elem (head xs) small then x : correctGaps small xs else if elem x small then x : correctGaps small xs else [" "] : correctGaps small xs

readerData :: IO [[[String]]]
readerData = do
    outs            <- readShell $ "ls " ++ folder ++ "/*.data"
    let outputs     = lines outs
    dataContent     <- mapM readFile outputs
    return $ map (map words) $ map lines dataContent  

hopS :: IO ()
hopS = do
  stringZ         <- readerData 
  let nRootI      = nRoot - 1 
      allJumps    = [(show x) ++ (show y) | x <- [0.. nRootI], y <- [0.. nRootI], x/=y]
      getHOP root = filter (\x -> x /= []) $ map (filter (\x-> x!!9 == root)) stringZ
      getHOPs     = map getHOP $ allJumps
  mapM_ (\x -> writeFile (folder ++ "HOP" ++ fst x) $ writeF (getHOPs !! snd x)) $ zip allJumps [0..]

whoIsomerize :: IO()
whoIsomerize = do
    stringZ <- readerData 
    let checkLN     = zip [0..] $ map length stringZ
        filtered    = unwords $ map (show . fst) $ filter (\x -> snd x < stepCheck) checkLN
        messaGe     = if filtered == "" then "Everything OK" else "Check out short trajectories: " ++ filtered
    putStrLn messaGe
    let hopOrNot    = map (all (\x -> x /= "10")) $ map (map (\x-> x!!9)) stringZ 
        isomYorN xs = map (map (\a -> read (a!!3) :: Double)) $ map (stringZ !!) xs
        counter x   = if isomCond x then 1 else 0
        whoNotHop   = map fst $ filter (\x-> snd x == True) $ zip [0..] hopOrNot
        notHopIsoC  = sum $ map counter $ map last $ isomYorN whoNotHop
        notHopnIsoC = (length whoNotHop) - notHopIsoC
        whoHop      = map fst $ filter (\x-> snd x == False) $ zip [0..] hopOrNot
        whoHopAndIs = map fst $ filter (\x-> isomCond $ snd x) $ zip whoHop $ map last $ isomYorN whoHop
        whoHopAndNo = map fst $ filter (\x-> not . isomCond $ snd x ) $ zip whoHop $ map last $ isomYorN whoHop
        hopIsoC     = sum $ map counter $ map last $ isomYorN whoHop     
        hopNIsoC    = (length whoHop) - hopIsoC
    putStrLn $ "Hop and Iso : " ++ (show hopIsoC)
    putStrLn $ "Hop not Iso : " ++ (show hopNIsoC)
    putStrLn $ "NoHop and Iso : " ++ (show notHopIsoC)
    putStrLn $ "NoHop not Iso : " ++ (show notHopnIsoC)
    let total = hopNIsoC + hopIsoC + notHopnIsoC + notHopIsoC
    putStrLn $ "Total : " ++ (show total)
    let rateHOP = (fromIntegral (hopIsoC * 100) / (fromIntegral (hopIsoC+hopNIsoC))) :: Double
    putStrLn $ "only Hopped Iso/notIso : " ++ (printZ rateHOP) ++ "%"
    let rateNOH = (fromIntegral (notHopIsoC * 100) / (fromIntegral (notHopIsoC+notHopnIsoC))) :: Double 
    putStrLn $ "only NON Hopped Iso/notIso : " ++ (printZ rateNOH) ++ "%"
    let rateTOT = (fromIntegral (hopIsoC * 100) / fromIntegral (total)) :: Double
    putStrLn $ "Total Iso/notIso : " ++ (printZ rateTOT) ++ "%"


