module Main where

import Control.Monad.IO.Class (liftIO)
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import qualified Data.HashMap.Strict as HM
import qualified Data.Map as M
import Data.Maybe (fromJust)
import Data.Monoid ((<>))
import Data.Text.Encoding (decodeUtf8)
import qualified Data.Yaml as Y
import Network.Pusher (authenticatePresence, parseChannel)
import Snap.Core (Method(GET), Snap, getParams, method, writeBS)
import Snap.Http.Server (quickHttpServe)

main :: IO ()
main = quickHttpServe $ method GET authHandler

authHandler :: Snap ()
authHandler = do
  cred <- liftIO $ Y.decodeFile "../credentials.yaml"
  params <- getParams
  let userData =
        A.Object $
        HM.fromList -- Would normally come from session data
          [ ("user_id", A.Number 10)
          , ( "user_info"
            , A.Object $ HM.singleton "name" (A.String "Mr. Pusher"))
          ]
      signature =
        authenticatePresence
          (fromJust cred)
          (decodeUtf8 $ head $ params M.! "socket_id")
          (parseChannel $ decodeUtf8 $ head $ params M.! "channel_name")
          userData
      respBody =
        A.Object $
        HM.fromList
          [ ("auth", A.String $ decodeUtf8 signature)
          , ( "channel_data"
            , A.String $ decodeUtf8 $ BL.toStrict $ A.encode userData)
          ]
  writeBS $
    head (params M.! "callback") <> "(" <> BL.toStrict (A.encode respBody) <>
    ");"
