module Main where
import Control.Concurrent
import Test.Hspec
import Test.Hspec.Core.Runner
import Debug.Trace (traceShowM)
import Test.Hspec.Core.Spec
import Control.Monad.IO.Class
import GHC.Base (breakpoint)

logThrId :: MonadIO m => String -> m ()
logThrId ctx = do
   thr <- liftIO myThreadId
   traceShowM $ ctx <> " " <> show thr

spec :: Spec
spec =
  describe "oopsie woopsie" $ do
   it "florbs" $ do
     putStrLn "nyanya"
     logThrId "inside test"

testMain :: IO ()
testMain = main

main :: IO ()
main = do
  let theSpec = mapSpecItem_ (wrapExampleInSpan . mkParallel) spec
  logThrId "main"

  hspecWith defaultConfig theSpec

  where
    wrapExampleInSpan :: Item a -> Item a
    wrapExampleInSpan item@Item {itemExample = ex, itemRequirement = req} =
      item
        { itemExample = \params aroundAction pcb -> breakpoint $ do
            -- we need to reattach the context, since we are on a forked thread
            logThrId $ "wrapper " <> req
            let pcb' p = traceShowM p >> pcb p
            ex params aroundAction pcb'
        }

    mkParallel item = item {itemIsParallelizable = Just True}

