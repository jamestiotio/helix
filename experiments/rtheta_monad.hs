{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

import Control.Monad.Identity
import Control.Monad.Writer
import Test.HUnit

{- 

Structural flag is 'All': a Boolean monoid under conjunction ('&&'). 
The initial value is 'True' and values are combined using &&.

Collision flag is 'Any': A Boolean monoind under disjunction ('||').
The initial value is 'False' and values are combined using ||

F (flags) type combines structural and collision flags
-}

newtype RFlags = F (Bool, Bool)
            
instance Show RFlags where
    show (F (a,b)) = show (a,b)

instance Eq RFlags where
    (==) (F (s0, c0)) (F (s1, c1)) = s0 == s1 && c0 == c1
    (/=) (F (s0, c0)) (F (s1, c1)) = s0 /= s1 || c0 /= c1

instance Monoid RFlags where
    mempty =  F (True, False)
    (F (s0, c0)) `mappend` (F (s1, c1)) = F ((s0 && s1),
                                    (c0 || c1 || not (s0 || s1)))
 

{- Alternative "safe" Monoid: -}

newtype RSFlags = SF (Bool, Bool)

instance Monoid RSFlags where
    mempty =  SF (True, False)
    (SF (s0, c0)) `mappend` (SF (s1, c1)) = SF ((s0 && s1), (c0 || c1))
                                    
type SInt = Writer RFlags Int

struct :: Int -> SInt
struct x = return x
    
value :: Int -> SInt
value x = do (tell (F (False, False))) ; return x

runW :: SInt -> (Int, Bool, Bool)
runW x = let (v, (F (s, c))) = runWriter x in
         (v, s, c)
         
{- Union operator, which is basically (+) with collision tracking -}         
union :: SInt -> SInt -> SInt
union = liftM2 (+)

testCases :: [(String, WriterT RFlags Identity Int, (Int, Bool, Bool))]
testCases = [
 ("c1",  (union (struct 2) (struct 1)),                    (3,True,False)),
 ("c2",  (union (struct 0) (value 2)),                     (2,False,False)),
 ("c3",  (union (value 2) (struct 3)),                     (5,False,False)),
 ("c4",  (union (value 1) (value 2)),                      (3,False,True)),
 ("c5",  (union (value 0) (value 2)),                      (2,False,True)),
 ("c6",  (union (union (value 1) (value 2)) (value 2)),     (5,False,True)),
 ("c7",  (union (union (value 0) (value 2)) (struct 2)),    (4,False,True)),
 ("c8",  (union (union (struct 1) (value 2)) (value 0)),    (3,False,True)),
 ("c9",  (union (union (struct 1) (value 2)) (struct 0)),   (3,False,False)),
 ("c10", (union (union (struct 1) (struct 2)) (value 0)),   (3,False,False)),
 ("c11", (union (union (struct 1) (struct 2)) (value 0)), (3,False,False))]

runCases :: [(String, SInt, (Int, Bool, Bool))] -> [Test]
runCases l = [TestCase $ assertEqual n (runW a) b | (n,a,b) <- l]

main :: IO Counts
main = runTestTT $ TestList (runCases testCases)
