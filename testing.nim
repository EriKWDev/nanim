
import
  os,
  osproc,
  streams


let rendersFolderPath = os.joinPath(os.getAppDir(), "renders")

createDir(rendersFolderPath)

let outputVideoPath = os.joinPath(rendersFolderPath, "scene.mp4")


let
  width = 1920.cint
  height = 1080.cint
  rgbaSize = sizeof(cint)
  bufferSize: int = width * height * rgbaSize
  goalFps = 60.0



let ffmpegOptions = @[
  "-y",
  "-f", "rawvideo",
  "-pix_fmt", "rgba",
  "-s", $width & "x" & $height,
  "-r", $goalFps.int,
  "-i", "-",  # Sets input to pipe

  "-an",  # Don't expect audio,
  # "-loglevel", "panic",  # Only log if something crashes
  "-c:v", "libx264",  # H.264 encoding
  "-preset", "slow",  # Should probably stay at fast/medium later
  "-crf", "18",  # Ranges 0-51 indicates lossless compression to worst compression. Sane options are 0-30
  "-tune", "animation",  # Tunes the encoder for animation and 'cartoons'
  "-pix_fmt", "yuv444p",
  outputVideoPath
]

let ffmpegProcess = startProcess("ffmpeg", "", ffmpegOptions, options = {poUsePath, poEchoCmd})
var data = alloc(bufferSize)

for i in 0..100000:
  try:
    ffmpegProcess.inputStream().writeData(data, bufferSize)
  except:
    let
      e = getCurrentException()
      msg = getCurrentExceptionMsg()
    echo "Got exception ", repr(e), " with message ", msg

ffmpegProcess.inputStream().flush()
dealloc(data)
close(ffmpegProcess)