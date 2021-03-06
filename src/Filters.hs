module Filters where

import Data.List
import System.Directory
import System.Process
import System.ShQQ
import Text.Printf

import CalculateData
import DataTypes
import Functions
import GnuplotZ
import ParseInput

mainfilter input = do
    atd   <- readerData
    let plottable  = getListToPlot input
        folder     = getfolder input
        checkPlots = map (\x -> x `elemIndex` plottable) [CcccCorrected, Ct, Jump]
        thereSNoth = Nothing `elem` checkPlots
    case thereSNoth of 
      True  -> do putStrLn $ "You cannot use filters without Cccccorrected, Ct and Jump constructors in dataPlot variable"
      False -> do 
          let (doHop,doesNotHop)   = whoHop input atd
              (doIsom,doesNotIsom) = whoIsom input atd
              (doLeft,doRight)     = whoLeftWhoRight input $ fst doHopIsom
              (doLeftNoIso,doRightNoIso) = whoLeftWhoRight input $ fst doHopNoIsom
              allOfThem      = (atd, "all")
              doHopIsom      = (intersect doHop doIsom, "HopAndIsom")
              doHopNoIsom    = (intersect doHop doesNotIsom, "HopAndNoIsom")
              noHopIsom      = (intersect doesNotHop doIsom, "NoHopAndIsom")
              noHopNoIsom    = (intersect doesNotHop doesNotIsom, "NoHopNoIsom")
              doHopIsomLeft  = (doLeft,  "HopIsomLeft")
              doHopIsomRight = (doRight, "HopIsomRight")
              noHopIsomLeft  = (doLeftNoIso,  "HopNoIsoGoLeft")
              noHopIsomRight = (doRightNoIso, "HopNoIsoGoRight")
              listOfThem     = [allOfThem, doHopIsom,doHopNoIsom,noHopIsom,noHopNoIsom,doHopIsomLeft,doHopIsomRight,noHopIsomLeft,noHopIsomRight]
              fileN          = folder ++ "-Stats"
--          system $ "rm " ++ fileN ++ " 2> /dev/null"
          mapM_ (\x -> makeBasicGraphs input (snd x) (fst x)) listOfThem
          mapM_ (\x -> atdLogger fileN (snd x) (fst x)) listOfThem
          let lf = length . fst
              [all,yhyi,yhni,nhyi,nhni,hiL,hiR,hniL,hniR] = map lf listOfThem
              z         = "\nSTATISTICS:\n\n                  Hop/NoHop(" ++ show (yhyi+yhni) ++ "/" ++ show (nhyi+nhni) ++ ")        TOTAL(" ++ (show all) ++ ")"
              a         = "Hop and Isom:   | " ++ (printPercentage2 yhyi yhni all)
              b         = "Hop not Isom:   | " ++ (printPercentage2 yhni yhyi all)
              c         = "NoHop and Isom: | " ++ (printPercentage2 nhyi nhni all)
              d         = "NoHop not Isom: | " ++ (printPercentage2 nhni nhyi all)
              g         = "\n\nLEFT AND RIGHT SECTION:\n"
              h         = "     HOP and ISOMERIZE             just Hop                  Total"
              i         = "Left:    | " ++ printPercentage3 hiL (hiL+hiR) (hiL+hiR+hniL+hniR) all
              j         = "Right:   | " ++ printPercentage3 hiR (hiL+hiR) (hiL+hiR+hniL+hniR) all
              k         = "\n   HOP and NOT ISOMERIZE           just Hop                  Total"
              l         = "Left:    | " ++ printPercentage3 hniL (hniL+hniR) (hiL+hiR+hniL+hniR) all
              m         = "Right:   | " ++ printPercentage3 hniR (hniL+hniR) (hiL+hiR+hniL+hniR) all
              n         = "\n       TOTAL                       just Hop                  Total"
              o         = "Left:    | " ++ printPercentage3 (hiL+hniL) (hiL+hiR+hniL+hniR) (hiL+hiR+hniL+hniR) all
              p         = "Right:   | " ++ printPercentage3 (hiR+hniR) (hiL+hiR+hniL+hniR) (hiL+hiR+hniL+hniR) all
              stringToW = intercalate "\n" [z,a,b,c,d,g,h,i,j,k,l,m,n,o,p] 
          putStrLn stringToW
          appendFile fileN (stringToW ++ "\n")
          putStrLn $ "\nEverything written down into file: " ++ fileN ++ " !!\n\n"

printPercentage2 :: Int -> Int -> Int -> String
printPercentage2 x y all = let
    percentage a b = printZ((fromIntegral2 a / fromIntegral2 b)*100.0) ++ "%"
    goodString a b = (printf "%7s" (percentage a b) :: String) ++ " " ++ (printf "%-9s" ("(" ++ show a ++ "/" ++ show b ++ ")") :: String)
    in (intercalate " | " [goodString x (x+y), goodString x all]) ++ " |"

printPercentage3 :: Int -> Int -> Int -> Int -> String
printPercentage3 x y allS allB = let 
    percentage a b = printZ((fromIntegral2 a / fromIntegral2 b)*100.0) ++ "%"
    goodString a b = (printf "%7s" (percentage a b) :: String) ++ " " ++ (printf "%-9s" ("(" ++ show a ++ "/" ++ show b ++ ")") :: String)
    in (intercalate " | " [goodString x y, goodString x allS, goodString x allB]) ++ " |"

atdLogger filN lab atd = do
          let trajNum x   = map (\x -> x!!0!!0) x
          appendFile filN $ "\n" ++ lab ++ " " 
          appendFile filN $ show $ length $ trajNum atd
          appendFile filN $ ":\n" ++ (unwords $ trajNum atd)
          appendFile filN "\n"

makeBasicGraphs input lab atd = do
    let folder      = getfolder input
        label       = folder ++ lab 
        nRoot       = getnRoot input
        nRootI      = pred nRoot
        allJumps    = [(show x) ++ (show y) | x <- [0.. nRootI], y <- [0.. nRootI], x/=y]
        plottable   = getListToPlot input
        rightIndex  = findInd Jump plottable
        getHOP root = filter (\x -> x /= []) $ map (filter (\x-> x!!rightIndex == root)) atd
        getHOPs     = map getHOP allJumps
    case length atd of
       0 -> do putStrLn $ "No trajectories are " ++ lab
       otherwise -> do
          writeFile label $ unlines $ map unlines $ map (map unwords) atd
          mapM_ (\x -> writeFile (label ++ fst x) $ writeF (getHOPs !! snd x)) $ zip allJumps [0..]
          mapM (\x -> gnuplotG input lab x atd) [CcccCorrected,BetaCorrected,Tau]
          createDirectoryIfMissing True "Graphics"
          system $ "mv " ++ label ++ "* Graphics"
          return ()
               
extractJust :: Maybe Int -> Int
extractJust a = case a of
   Just x  -> x
   Nothing -> 0

whoIsom :: Inputs -> AllTrajData -> (AllTrajData,AllTrajData)
whoIsom input atd = partition ( isoOrNot input ) atd

isoOrNot :: Inputs -> SingleTrajData -> Bool
isoOrNot input std = let
   listPlot  = getListToPlot input 
   index     = findInd CcccCorrected listPlot
   lastPoint = last std
   lastValue = read2 $ lastPoint !! index
   isomCond  = snd $ getUpperAndIsomCond $ getisomType input 
   in isomCond lastValue

whoHop :: Inputs -> AllTrajData -> (AllTrajData,AllTrajData)
whoHop input atd = let
   listPlot      = getListToPlot input
   indeX         = findInd Jump listPlot
   in partition ( doThisHopOrNot indeX ) atd

doThisHopOrNot :: Int -> SingleTrajData -> Bool
doThisHopOrNot index std = let
   jumpColumn = map (\x-> x!!index) std  
   in any (\x -> x == "10") jumpColumn

whoLeftWhoRight :: Inputs-> AllTrajData -> (AllTrajData,AllTrajData)
whoLeftWhoRight input atd = partition (leftRight input) atd

-- this DOES NOT WORK IN CASE OF 20 (from S2 to S0) last hop correct plz
leftRight :: Inputs -> SingleTrajData -> Bool
leftRight input std = let
   listPlot  = getListToPlot input
   indexC    = findInd CcccCorrected listPlot
   indexJ    = findInd Jump listPlot
   hoppingCC = read2 $ (last $ filter (\x -> x!!indexJ == "10") std ) !! indexC -- here is why it will not work. It just looks for "10" transitions
   in case getisomType input of
           Cis   -> if hoppingCC >  0   then True else False
           Trans -> if hoppingCC > -180 then True else False
   
filterHoppingPointsAll :: AllTrajData -> AllTrajData
filterHoppingPointsAll atd = map filterHoppingPoints atd

filterHoppingPoints :: SingleTrajData -> SingleTrajData
filterHoppingPoints std = undefined

filterCTHigherOrLowerAll :: Double -> AllTrajData -> AllTrajData
filterCTHigherOrLowerAll thresh atd = map (filterCTHigherOrLower thresh) atd

filterCTHigherOrLower :: Double -> SingleTrajData -> SingleTrajData
filterCTHigherOrLower thresh std = undefined 

-- Charge Transfer part

chargeTmap :: Inputs -> IO()
chargeTmap input = do
  atd   <- readerData
  let plottable  = getListToPlot input
      folder     = getfolder input
      checkPlots = map (\x -> x `elemIndex` plottable) [CcccCorrected, Ct, Jump]
      thereSNoth = Nothing `elem` checkPlots
  case thereSNoth of
    True  -> do putStrLn $ "You cannot use filters without Cccccorrected, Ct and Jump constructors in dataPlot variable"
    False -> do
      let (doHop,doesNotHop)   = whoHop input atd 
          (doIsom,doesNotIsom) = whoIsom input atd 
          allOfThem     = (atd, "all")
          doHopIsom     = (intersect doHop doIsom, "HopAndIsom")
          doHopNoIsom   = (intersect doHop doesNotIsom, "HopAndNoIsom")
          noHopIsom     = (intersect doesNotHop doIsom, "NoHopAndIsom")
          noHopNoIsom   = (intersect doesNotHop doesNotIsom, "NoHopNoIsom")
          (doHopIsomS1,doHopIsomS0)     = divideS0S1 input doHopIsom
          (doHopNoIsomS1,doHopNoIsomS0) = divideS0S1 input doHopNoIsom
          listOfThem    = [allOfThem,doHopIsom,doHopNoIsom,noHopIsom,noHopNoIsom,doHopIsomS1,doHopIsomS0,doHopNoIsomS1,doHopNoIsomS0]
          listOfNonEmpt = filter (\x -> (length $ fst x) > 0 ) listOfThem
          thresh = getchargeTrThresh input
      mapM_ (\x -> chargeTMultiple input (fst x) (snd x) thresh) listOfNonEmpt 

divideS0S1 :: Inputs -> (AllTrajData,String) -> ((AllTrajData,String),(AllTrajData,String))
divideS0S1 input x = let 
   label   = snd x
   labelS1 = label ++ "S1"
   labelS0 = label ++ "S0"
   atdTOT  = fst x
   (atdS0, atdS1) = divideATDS0S1 input atdTOT
   in ((atdS0,labelS0),(atdS1,labelS1))

divideATDS0S1 :: Inputs -> AllTrajData -> (AllTrajData,AllTrajData)
divideATDS0S1 input atd = let
   plottable   = getListToPlot input
   rightIndex  = findInd Root plottable
   inS0        = map (filter (\x -> x!!rightIndex=="S0")) atd
   inS1        = map (filter (\x -> x!!rightIndex=="S1")) atd
   in (inS0,inS1)

chargeTMultiple :: Inputs -> AllTrajData -> String -> [Double] -> IO()
chargeTMultiple input atd filtername thresh = mapM_ (\x -> chargeTsingle input atd filtername x ) thresh

chargeTsingle :: Inputs -> AllTrajData -> String -> Double -> IO()
chargeTsingle input atd filtername thresh = do
    let folder      = getfolder input
        plottable   = getListToPlot input
        rightIndex  = findInd Ct plottable
        nRootI      = pred $ getnRoot input
        allJumps    = [(show x) ++ (show y) | x <- [0.. nRootI], y <- [0.. nRootI], x/=y]
        rightIndHop = findInd Jump plottable
        getHOP root = filter (\x -> x /= []) $ map (filter (\x-> x!!rightIndHop == root)) atd
        getHOPs     = map getHOP allJumps
        upper       = map (filter (\x -> read2 (x!!rightIndex) > thresh)) atd
        lower       = map (filter (\x -> read2 (x!!rightIndex) < thresh)) atd
        upperCorr   = map compress $ zipWith correctGaps upper atd
        lowerCorr   = map compress $ zipWith correctGaps lower atd
        fileName    = "chargeTr" ++ folder ++ (show thresh) ++ filtername 
    mapM_ (\x -> writeFile (fileName ++ fst x) $ writeF (getHOPs !! snd x)) $ zip allJumps [0..]
    writeFile (fileName ++ "HI") $ writeF upperCorr
    writeFile (fileName ++ "LO") $ writeF lowerCorr
    mapM (\x -> gnuplotCT input filtername x atd thresh) [CcccCorrected,BetaCorrected,Tau,Delta,Bla]
    createDirectoryIfMissing True "ChargeTranfData"
    system $ "mv " ++ fileName ++ "* ChargeTranfData"
    return ()

-- I wanna fill the space between two different set in gnuplot splot lines
correctGaps :: [[String]] -> [[String]] -> [[String]]
correctGaps []    a      = []
correctGaps small (x:[]) = x : []
correctGaps small (x:xs) = if elem (head xs) small then x : correctGaps small xs else if elem x small then x : correctGaps small xs else [" "] : correctGaps small xs


