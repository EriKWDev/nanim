
import
  nanovg,
  glfw,
  opengl,
  os,
  times,
  osproc,
  streams,
  parseopt,
  strutils


import
  core,
  logging


proc createNVGContext(): NVGContext =
  let flags = {nifStencilStrokes, nifDebug}
  return nvgCreateContext(flags)


proc createWindow(resizable: bool = true, width: int = 900, height: int = 500): Window =
  var config = DefaultOpenglWindowConfig
  config.size = (w: width, h: height)
  config.title = "Nanim"
  config.resizable = resizable
  config.nMultiSamples = 8
  config.debugContext = true
  config.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)

  when defined(MacOS) or defined(MacOSX):
    config.version = glv32
    config.forwardCompat = true
    config.profile = opCoreProfile

  let window = newWindow(config)
  if window == nil: quit(-1)

  # Enables vsync
  # swapInterval(1)
  swapInterval(0)

  return window


proc setupCallbacks(scene: Scene) =
  scene.window.framebufferSizeCb = proc(w: Window, s: tuple[w, h: int32]) =
    scene.tick()

  scene.window.windowRefreshCb = proc(w: Window) =
    scene.tick()


proc setupRendering(userScene: Scene, resizable: bool = true, width: int = 1920, height: int = 1080) =
  var scene = userScene
  initialize()
  scene.window = createWindow(resizable, width, height)
  if resizable: scene.setupCallbacks()

  doAssert glInit()

  glEnable(GL_MULTISAMPLE)

  makeContextCurrent(scene.window)

  nvgInit(getProcAddress)
  scene.context = createNVGContext()

  scene.context.loadFonts()


proc beginFrame(scene: Scene) =
  var (windowWidth, windowHeight) = scene.window.size

  scene.width = windowWidth
  scene.height = windowHeight

  var (frameBufferWidth, frameBufferHeight) = scene.window.framebufferSize

  scene.frameBufferHeight = frameBufferHeight
  scene.frameBufferWidth = frameBufferWidth
  scene.pixelRatio = 1

  glViewport(0, 0, scene.frameBufferWidth, scene.frameBufferHeight)
  scene.context.beginFrame(scene.width.cfloat, scene.height.cfloat, scene.pixelRatio)


proc endFrame(scene: Scene) =
  scene.context.endFrame()


proc runLiveRenderingLoop(scene: Scene) =
  # TODO: Make scene.update loop be on a separate thread. That would allow rendering even while user is dragging/resizing window...
  while not scene.window.shouldClose:
    scene.beginFrame()
    scene.update()
    scene.endFrame()

    swapBuffers(scene.window)
    pollEvents()

  scene.window.destroy()


proc renderVideoWithPipe(scene: Scene) =
  let
    (width, height) = scene.window.size
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize
    goalFps = 60
    goalDeltaTime = 1000.0/goalFps.float

  # ? Maybe reset time here. It is probably unexpected through
  # ? if the scene explicitly has a startHere() call...
  # scene.time = 0.0
  scene.deltaTime = goalDeltaTime

  let rendersFolderPath = os.joinPath(os.getAppDir(), "renders")
  let partsFolderPath = os.joinPath(rendersFolderPath, "parts")
  createDir(partsFolderPath)

  # * ffmpeg -y -f rawvideo -pix_fmt rgba -s 1920x1080 -r 60 -i - -vf vflip -an -c:v libx264 -preset fast -crf 18 -tune animation -pix_fmt yuv444p
  let ffmpegOptions = @[
    "-y",
    "-f", "rawvideo",
    "-pix_fmt", "rgba",
    "-s", $width & "x" & $height,
    "-r", $goalFps,
    "-i", "-", # * Set input to pipe
    "-vf", "vflip", # * Flips the image vertically since glReadPixels gives flipped image
    "-an",  # * Don't expect audio,
    # "-loglevel", "panic",
    "-c:v", "libx264",  # * H.264 encoding
    "-preset", "medium",  # * Should probably stay at fast/medium later
    "-crf", "18",  # * Ranges 0-51 indicates lossless compression to worst compression. Sane options are 0-30
    "-tune", "animation",  # * Tunes the encoder for animation and 'cartoons'
    "-pix_fmt", "yuv444p" # * Minimal color data loss on H.264 encode
  ]

  var
    ffmpegProcess: Process
    data = alloc(bufferSize)

  let
    partsFileName = os.joinPath(partsFolderPath, "parts.txt")
    partsFile = open(partsFileName, fmWrite)

  proc startFFMpeg(n: int = 0): Process =
    let partName = os.joinPath(partsFolderPath, "scene_" & $n & ".mp4")
    partsFile.writeLine("file '" & partName & "'")
    partsFile.flushFile()

    stdout.write InfoPrefix, "Launching FFMpeg subprocess with "
    startProcess("ffmpeg", "", ffmpegOptions & partName, options = {poUsePath, poEchoCmd})

  proc closeFFMpeg() =
    ffmpegProcess.inputStream().flush()
    ffmpegProcess.close()
    discard ffmpegProcess.waitForExit()

  proc restartFFMPeg(n: int = 0) =
    closeFFMpeg()
    ffmpegProcess = startFFMpeg(n)

  proc writeToFFMpeg(info: pointer, size: int) =
    ffmpegProcess.inputStream().writeData(info, size)

  var
    i = 0
    n = 0

  ffmpegProcess = startFFMpeg(i)

  while not scene.done:
    scene.beginFrame()
    scene.tick()
    scene.time = scene.time + goalDeltaTime
    scene.endFrame()

    inc i
    inc n

    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glReadBuffer(GL_BACK)
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data)

    swapBuffers(scene.window)

    try:
      if bufferSize * n > 4000000000:
        restartFFMPeg(i)
        n = 0

      writeToFFMpeg(data, bufferSize)
    except:
      let msg = getCurrentExceptionMsg()
      error msg
      scene.done = true

    if scene.done:
      scene.window.shouldClose = true

    pollEvents()

  partsFile.flushFile()
  partsFile.close()
  dealloc(data)
  scene.window.destroy()
  closeFFMpeg()

  # By sleeping just a little bit it seems that the file is really
  # closed and written. This fixes bugs with extremely short scenes.

  sleep(300)
  # ffmpeg -y -f concat -safe 0 -i './renders/parts/parts.txt' -c copy final.mp4
  let command = "ffmpeg -y -f concat -safe 0 -loglevel warning -i " & partsFileName & " -c copy " & os.joinPath(rendersFolderPath, "final.mp4")
  info "Stitching parts together with ", command

  let res = execShellCmd(command)
  doAssert res == 0


proc render*(userScene: Scene) =
  var scene = userScene.deepCopy()

  var
    width = 1920
    height = 1080
    createVideo = false

  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      discard

    of cmdLongOption, cmdShortOption:
      case key
      of "r", "run":
        createVideo = false
        break
      of "v", "video", "render":
        createVideo = true
      of "w", "width":
        width = value.parseInt()
      of "h", "height":
        height = value.parseInt()
      of "1080p", "fullhd":
        createVideo = true
        width = 1920
        height = 1080
      of "1440p", "2k":
        createVideo = true
        width = 2880
        height = 1440
      else:
        echo "Nanim (c) Copyright 2021 Erik Wilhem Gren"
        echo ""
        echo "  <filename_containing_scene> [options]"
        echo ""
        echo "Options:"
        echo "  -r, --run"
        echo "    Opens a window with the scene rendered in realtime."
        echo "  -v, --video, --render"
        echo "    Enables video rendering mode. Will output video to renders/final.mp4"
        echo "  -fullhd, --1080p"
        echo "    Enables video rendering mode with 1080p settings"
        echo "  -2k, --1440p"
        echo "    Enables video rendering mode with 1440p settings"
        echo "  -4k, --2160p"
        echo "    Enables video rendering mode with 2160p settings"
        echo "  -w:WIDTH, --width:WIDTH"
        echo "    Sets width to WIDTH"
        echo "  -h:HEIGHT, --height:HEIGHT"
        echo "    Sets height to HEIGHT"
        return

    of cmdEnd: discard

  scene.setupRendering(not createVideo, width, height)

  if createVideo:
    scene.renderVideoWithPipe()
  else:
    # Compensate for the time it took to get here
    scene.time = scene.time - (cpuTime() * 1000.0)
    scene.runLiveRenderingLoop()

  nvgDeleteContext(scene.context)
  terminate()


proc render*(userSceneCreator: proc(): Scene) =
  render(userSceneCreator())