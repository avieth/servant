{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE TypeSynonymInstances  #-}
{-# OPTIONS_GHC -fno-warn-orphans  #-}
module Servant.DocsSpec where

import           Control.Lens
import           Data.Aeson
import           Data.Monoid
import           Data.Proxy
import           Data.String.Conversions (cs)
import           GHC.Generics
import           Test.Hspec

import           Servant.API
import           Servant.Docs.Internal

spec :: Spec
spec = describe "Servant.Docs" $ do

  describe "markdown" $ do
    let md = markdown (docs (Proxy :: Proxy TestApi1))
    tests md

  describe "markdown with extra info" $ do
    let
      extra = extraInfo
              (Proxy :: Proxy (Get '[JSON, PlainText] Int))
              (defAction & notes <>~ [DocNote "Get an Integer" ["get an integer in Json or plain text"]])
              <>
              extraInfo
              (Proxy :: Proxy (ReqBody '[JSON] String :> Post '[JSON] Datatype1))
              (defAction & notes <>~ [DocNote "Post data" ["Posts some Json data"]])
      md = markdown (docsWith [] extra (Proxy :: Proxy TestApi1))
    tests md
    it "contains the extra info provided" $ do
      md `shouldContain` "Get an Integer"
      md `shouldContain` "Post data"
      md `shouldContain` "get an integer in Json or plain text"
      md `shouldContain` "Posts some Json data"

 where
   tests md = do
    it "mentions supported content-types" $ do
      md `shouldContain` "application/json"
      md `shouldContain` "text/plain;charset=utf-8"

    it "mentions status codes" $ do
      md `shouldContain` "Status code 200"
      md `shouldContain` "Status code 201"

    it "mentions methods" $ do
      md `shouldContain` "POST"
      md `shouldContain` "GET"

    it "contains response samples" $
      md `shouldContain` "{\"dt1field1\":\"field 1\",\"dt1field2\":13}"
    it "contains request body samples" $
      md `shouldContain` "17"

-- * APIs

data Datatype1 = Datatype1 { dt1field1 :: String
                           , dt1field2 :: Int
                           } deriving (Eq, Show, Generic)

instance ToJSON Datatype1

instance ToSample Datatype1 Datatype1 where
  toSample _ = Just $ Datatype1 "field 1" 13

instance ToSample String String where
  toSample _ = Just "a string"

instance ToSample Int Int where
  toSample _ = Just 17

instance MimeRender PlainText Int where
  mimeRender _ = cs . show


type TestApi1 = Get '[JSON, PlainText] Int
           :<|> ReqBody '[JSON] String :> Post '[JSON] Datatype1

