{-# language TypeFamilies #-}
module Numeric.Classification.Utils where

-- import qualified Data.Foldable as F (maximumBy, foldl', toList)
import qualified Data.Set as S
import qualified Data.IntMap.Strict as IM

import System.Random.MWC
import System.Random.MWC.Distributions
import Control.Monad.Primitive

import Control.Monad (foldM, replicateM)
import Data.Maybe (maybeToList)

-- import Control.Monad.Catch (MonadThrow(..))
-- import Numeric.Classification.Exceptions

-- | Sample with replacement
resample :: (Indexed f, PrimMonad m, Ix f ~ Int) =>
            Int -> f b -> Gen (PrimState m) -> m [b]
resample nsamples im gen = lookups (resampleIxs nsamples gen) im

-- | Sample without replacement : return a list of at most M unique random samples from an indexed map of size N : O(N)
sample :: (Indexed f, PrimMonad m, Ix f ~ Int) =>
          Int -> f b -> Gen (PrimState m) -> m [b]
sample nsamples im gen = lookups (sampleIxs nsamples gen) im

lookups :: (Monad m, Monoid (t b), Traversable t, Indexed f) =>
           (Int -> m (t (Ix f)))  -- ^ Sampling function
        -> f b
        -> m (t b)
lookups f im = do
  ixs <- f (length im)
  pure $ mconcat . maybeToList $ traverse (`ix` im) ixs 

resampleIxs :: PrimMonad m => Int -> Gen (PrimState m) -> Int -> m [Int]
resampleIxs nsamples gen n = replicateM nsamples (uniformR (0, n - 1) gen)

sampleIxs :: PrimMonad m => Int -> Gen (PrimState m) -> Int -> m [Int]
sampleIxs nsamples gen n = S.toList <$> sampleUniques nsamples gen n

-- | Random split based on extracting 'm' unique entries from a set of size 'n > m'
randomSplit :: PrimMonad m =>
               Int   -- ^ Number of samples
            -> Int   -- ^ Size of universe set
            -> Gen (PrimState m)
            -> m (S.Set Int, S.Set Int)
randomSplit nsamples n gen = do
  srand <- sampleUniques nsamples gen n
  let s0 = S.fromList [0 .. n - 1]
      sDiff = s0 `S.difference` srand
  pure (srand, sDiff)

-- | Stochastic random split of a set of size 'n', based on a Bernoulli trial of parameter '0 <= p <= 1'; /on average/, m = p * n samples will be inserted in the left set, and n - m will be inserted in the right one.
randomSplitBernoulli :: PrimMonad m =>
                Double  -- ^ Parameter of Bernoulli trial
             -> Int
             -> Gen (PrimState m)
             -> m (S.Set Int, S.Set Int)
randomSplitBernoulli p n gen = foldM insf (S.empty, S.empty) [0.. n-1] where
  insf (sl, sr) i = do
    c <- bernoulli p gen -- coinFlip gen
    pure $ if c then
      (S.insert i sl, sr)
      else
      (sl, S.insert i sr)



-- sampleNoReplace iml nsamples gen
--   | nsamples > n = pure $ throwM $ DimMismatchE "sampleIM" n nsamples
--   | otherwise = do


-- | Sample without replacement : choose a set S of M unique random samples from a population of size N
sampleUniques :: PrimMonad m =>
                 Int   -- ^ # of unique numbers to sample (M)
              -> Gen (PrimState m)
              -> Int   -- ^ Population size (N)
              -> m (S.Set Int)  
sampleUniques nsamples gen n = foldM sample1 S.empty [p .. n - 1] where
  p = n - nsamples + 1
  sample1 s j = do
    t <- uniformR (0, j) gen
    let set' =
          if not (S.member t s)
          then
            S.insert t s
          else
            S.insert j s
    return set'

-- stest n ntot = withSystemRandom . asGenIO $ \g -> do
--   let set = S.fromList [0..ntot - 1]
--   sampleUniques set n g




-- | Indexable containers
class Foldable f => Indexed f where
  type Ix f :: *
  ix :: Ix f -> f a -> Maybe a

instance Indexed [] where
  type Ix [] = Int
  ix = indexSafe

instance Indexed IM.IntMap where
  type Ix IM.IntMap = IM.Key
  ix = IM.lookup


indexSafe :: Int -> [a] -> Maybe a
indexSafe i ll | i < length ll = Just $ ll !! i
               | otherwise = Nothing