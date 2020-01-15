module Language.Lua.Typed.Composer where

import qualified Data.ByteString.Lazy.Char8 as BSL
import           Data.List.Split
import           System.Directory
import           System.Environment
import           System.Process             hiding (shell)
import           System.Process.Typed       hiding (readProcess)

getFirstArgument :: IO String
getFirstArgument = getArgs >>= \case
    (firstArg:_) -> pure firstArg
    _            -> pure "src-lua"

compileLua :: String -> String -> IO ()
compileLua srcPath modulePath = doesFileExist (srcPath ++ "/" ++ modulePath ++ ".tl") >>= \case
    True  -> callCommand $ concat
        [
        -- Create a module's folder
          "mkdir -p build/", modulePath, "\n"
        , "echo 'Compiled: ", modulePath, ".lua'\n"
        -- Compile
        , "cd ", srcPath, "\n"
        , "tlc -s -o ../build/", modulePath, ".lua ", modulePath, ".tl"
        ]
    False -> putStrLn $ "There is no " ++ srcPath ++ "/" ++ modulePath ++ ".tl"

compose :: IO ()
compose = do
    src <- getFirstArgument

    doesMainExist <- doesFileExist $ src ++ "/Main.tl"

    if not doesMainExist
    then putStrLn $ "There is no " ++ src ++ "/Main.tl"
    else do
        callCommand "mkdir -p build"

        modules <-
                map (reverse . drop 3 . reverse . drop 2)
            .   filter (/= "")
            .   splitOn "\n"
            .   BSL.unpack
            <$> readProcessStdout_ (shell $ concat [ "cd ", src, "; find . -type f" ])

        mapM_ (compileLua src) modules

        callCommand "find build/ -type d -empty -delete"
