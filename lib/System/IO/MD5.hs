-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module System.IO.MD5(MD5CheckSum, md5File, md5Handle, md5String) where
import Primitives(primUnsafeCoerce)
import Prelude
import Data.Word
import Foreign.C.String
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Ptr

foreign import ccall "md5File"   c_md5File   :: Handle  -> Ptr Word -> IO ()
foreign import ccall "md5String" c_md5String :: CString -> Ptr Word -> IO ()

newtype MD5CheckSum = MD5 [Word]  -- either 2*64 bits or 4*32 bits

instance Eq MD5CheckSum where
  MD5 a == MD5 b  =  a == b

instance Show MD5CheckSum where
  show (MD5 ws) = "MD5" ++ show ws

md5Len :: Int
md5Len = 16   -- The MD5 checksum is 16 bytes

md5WLen :: Int  -- length in words
md5WLen = (md5Len * 8) `quot` _wordSize

chksum :: (Ptr Word -> IO ()) -> IO MD5CheckSum
chksum fn = do
  buf <- mallocArray md5WLen
  fn buf
  wmd5 <- peekArray md5WLen buf
  free buf
  return (MD5 wmd5)

md5String :: String -> IO MD5CheckSum
md5String s = withCAString s $ chksum . c_md5String

md5Handle :: Handle -> IO MD5CheckSum
md5Handle h = chksum $ c_md5File h

md5File :: FilePath -> IO (Maybe MD5CheckSum)
md5File fn = do
  mh <- openFileM fn ReadMode
  case mh of
    Nothing -> return Nothing
    Just h -> do
      cs <- md5Handle h
      hClose h
      return (Just cs)
