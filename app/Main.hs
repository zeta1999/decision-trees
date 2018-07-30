-- {-# language DeriveGeneric #-}
module Main where

import Numeric.Classification
import Numeric.Datasets.Iris (Iris(..), IrisClass(..), iris)
-- import GHC.Generics
import Control.Monad.Catch (MonadThrow(..))
import qualified Data.Vector as V
import qualified Data.IntMap as IM
import Control.Monad (void)

-- main = print "hello!"

irisKV :: (MonadThrow m, Applicative f) => Iris -> m (IrisClass, f (V Double))
irisKV (Iris sl sw pl pw lab) = do
  iv <- mkV 4 $ V.fromList [sl, sw, pl, pw]
  pure (lab, pure iv)

irisDataset :: MonadThrow m => m (Dataset IrisClass [V Double])
irisDataset = do
  ivs <- traverse irisKV iris 
  pure $ fromListWith (++) ivs  

treeOptions :: TOptions
treeOptions = TOptions 4 5 LessThan


main :: IO ()
main = do 
  ivs <- traverse irisKV iris 
  let ivDs = fromListWith (++) ivs
  -- print ivDs
  -- print $ uniques round ivDs
      tr = growTree' treeOptions 0 0.5 ivDs
  -- print $ void tr
  print $ concatMap (allCuts 0 0.5) ivDs


