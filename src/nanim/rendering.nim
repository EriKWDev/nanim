
import
  nanovg,
  staticglfw,
  opengl,
  os,
  times,
  osproc,
  streams,
  parseopt,
  strutils,
  strformat,
  tables,
  stb_image/write as stbiw,
  nanim/core,
  nanim/logging,
  nanim/animation


proc createNVGContext(): NVGContext =
  let flags = {nifStencilStrokes, nifDebug, nifAntialias}
  return nvgCreateContext(flags)


proc createWindow(resizable: bool = true, width: int = 900, height: int = 500): Window =
  let
    tag = if resizable: "(Preview, hover with mouse to jump around)" else: "(Rendering)"
    title = "Nanim " & tag

  defaultWindowHints()

  windowHint(SAMPLES, 8)

  windowHint(OPENGL_DEBUG_CONTEXT, TRUE)

  windowHint(RED_BITS, 8)
  windowHint(GREEN_BITS, 8)
  windowHint(BLUE_BITS, 8)
  windowHint(ALPHA_BITS, 8)

  windowHint(STENCIL_BITS, 8)
  windowHint(DEPTH_BITS, 16)

  windowHint(DECORATED, TRUE)

  windowHint(RESIZABLE, if resizable: TRUE else: FALSE)

  when defined(MacOS) or defined(MacOSX) or defined(compat):
    windowHint(VERSION_MAJOR, 3)
    windowHint(VERSION_MINOR, 2)
    windowHint(CONTEXT_VERSION_MAJOR, 3)
    windowHint(CONTEXT_VERSION_MINOR, 2)
    windowHint(OPENGL_ES_API, TRUE)
    windowHint(OPENGL_FORWARD_COMPAT, TRUE)
    windowHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)

  let window = createWindow(width.cint, height.cint, title, nil, nil)


  if window == nil: quit(-1)

  # Enables vsync
  # swapInterval(1)
  swapInterval(0)

  return window

proc beginFrame(scene: Scene) =
  glViewport(0, 0, scene.frameBufferWidth, scene.frameBufferHeight)
  scene.context.beginFrame(scene.width.cfloat, scene.height.cfloat, scene.pixelRatio)


proc endFrame(scene: Scene) =
  scene.context.endFrame()


func updatePixelRatio(scene: Scene) =
  scene.pixelRatio =  scene.width.float / scene.frameBufferWidth.float


var
  frameBufferSizeCallback: proc(window: Window, width: cint, height: cint) {.closure.}
  windowSizeCallBack: proc(window: Window, width: cint, height: cint) {.closure.}

proc setupCallbacks(scene: Scene) =
  frameBufferSizeCallback =
    proc(window: Window, width: cint, height: cint) {.closure.} =
      scene.frameBufferWidth = width
      scene.frameBufferHeight = height
      scene.updatePixelRatio()

  let frameBufferSizeCallbackC =
    proc(window: Window, width: cint, height: cint) {.cdecl.} =
      frameBufferSizeCallback(window, width, height)

  discard scene.window.setFramebufferSizeCallback(frameBufferSizeCallbackC)

  windowSizeCallBack =
    proc(window: Window, width: cint, height: cint) {.closure.} =
      scene.width = width
      scene.height = height
      scene.updatePixelRatio()

      scene.beginFrame()
      scene.tick(0.0)
      scene.endFrame()
      scene.window.swapBuffers()

  let windowSizeCallBackC =
    proc(window: Window, width: cint, height: cint) {.cdecl.} =
      windowSizeCallBack(window, width, height)

  discard scene.window.setWindowSizeCallback(windowSizeCallBackC)


proc setupRendering(userScene: Scene, resizable: bool = true) =
  var scene = userScene

  if init() == 0:
    raise newException(Exception, "Failed to Initialize GLFW")

  scene.window = createWindow(resizable, scene.width, scene.height)
  if resizable: scene.setupCallbacks()

  scene.window.makeContextCurrent()

  # glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  loadExtensions()

  nvgInit(getProcAddress)
  scene.context = createNVGContext()
  scene.loadFonts()

  scene.window.getFramebufferSize(scene.frameBufferWidth.addr, scene.frameBufferHeight.addr)
  scene.updatePixelRatio()


var cursorPositionCallback: proc(window: Window, x, y: cdouble) {.closure.}

proc runLiveRenderingLoop(scene: Scene) =
  # TODO: Make scene.update loop be on a separate thread. That would allow rendering even while user is dragging/resizing window...

  var endTime: float = -1

  for track in scene.tweenTracks.values:
    let endTween = track.getLatestTween()
    if endTween.startTime + endTween.duration > endTime:
      endTime = endTween.startTime + endTween.duration

  cursorPositionCallback =
    proc(window: Window, x, y: cdouble) {.closure.} =
      var
        width: cint
        height: cint

      window.getWindowSize(width.addr, height.addr)

      scene.time = x/width.float * endTime

  let cursorPositionCallbackC =
    proc(window: Window, x, y: cdouble) {.cdecl.} =
      cursorPositionCallback(window, x, y)

  discard scene.window.setCursorPosCallback(cursorPositionCallbackC)

  # Compensate for the time it took to get here
  scene.time = scene.time - getCurrentRealTime()

  while scene.window.windowShouldClose() == 0:
    scene.beginFrame()
    scene.update()
    scene.endFrame()

    swapBuffers(scene.window)
    pollEvents()

  scene.window.destroyWindow()

## Thanks to https://github.com/define-private-public/random-art-Nim/blob/30607d4a912b662be7a3ac1ef8e341e0a5295226/opengl_helpers.nim#L100
proc offset(some: pointer; b: int): pointer {.inline.} =
  result = cast[pointer](cast[int](some) + b)


proc renderScreenshot(scene: Scene) =
  var
    width: cint
    height: cint

  scene.window.getWindowSize(width.addr, height.addr)

  let
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize

    rendersFolderPath = os.joinPath(os.getAppDir(), "renders")
    filePath = joinPath(rendersFolderPath, "final_" & $times.now().getClockStr().replace(":", "_"))

  createDir(rendersFolderPath)
  var data = alloc(bufferSize)


  # TODO: Fix to truly initiate all entities. Should go away when a 'Scene.goToTime(t: float)'
  # proc is implemented in the future.

  scene.beginFrame()
  scene.tick(0.1)
  scene.endFrame()

  scene.beginFrame()
  scene.tick(-0.1)
  scene.endFrame()

  glPixelStorei(GL_PACK_ALIGNMENT, 1)
  glReadBuffer(GL_BACK)
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data)

  swapBuffers(scene.window)

  var pixels = newSeq[uint8](bufferSize)

  # Need to flip the pixels along the horizontal...
  for y in 0..<height:
    let
      lineSize = width * rgbaSize
      yDest = y * lineSize
      ySrc = bufferSize - yDest - lineSize
    copyMem(pixels[yDest].unsafeAddr, data.offset(ySrc), lineSize)

  dealloc(data)

  stbiw.writePNG(&"{filePath}.png", width, height, stbiw.RGBA, pixels)

  scene.done = true
  scene.window.setWindowShouldClose(1)
  pollEvents()


proc renderWithPipe(scene: Scene, createGif = false) =
  var
    width: cint
    height: cint

  scene.window.getWindowSize(width.addr, height.addr)

  let
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize
    goalFps = 60
    goalDeltaTime = 1000.0/goalFps.float

    rendersFolderPath = os.joinPath(os.getAppDir(), "renders")
    filePath = joinPath(rendersFolderPath, "final_" & $times.now().getClockStr().replace(":", "_"))

  createDir(rendersFolderPath)

  var ffmpegOptions: seq[string]

  if createGif:
    warn "Currently, the built in GIF-generation is very primitive. It is recommended to instead use --render and manually convert the render to GIF for better results."
    ffmpegOptions = @[
      "-y",
      "-f", "rawvideo",
      "-pix_fmt", "rgba",
      "-s", $width & "x" & $height,
      "-r", $goalFps,
      "-i", "-", # * Set input to pipe
      "-vf", "vflip",  # * Flips the image vertically since glReadPixels gives flipped image
      "-an",  # * Don't expect audio
      # "-loglevel", "panic",
      # TODO: Get palettegen and scales to work. Current GIFs are huge
      # "-filter_complex",
      # [0:v] split [a][b];[a] palettegen [p];[b][p] paletteuse'",
      # """[0]fps=15,scale=576:-1,setsar=1[x];[x][1:v]paletteuse""",
      filePath & ".gif"
    ]
  else:
    # * ffmpeg -y -f rawvideo -pix_fmt rgba -s 1920x1080 -r 60 -i - -vf vflip -an -c:v libx264 -preset medium -profile:v high -crf 17 -coder 1 -tune animation -pix_fmt yuv420p -movflags +faststart -g 30 -bf 2 final-mp4
    ffmpegOptions = @[
      "-y",
      "-f", "rawvideo",
      "-pix_fmt", "rgba",
      "-s", $width & "x" & $height,
      "-r", $goalFps,
      "-i", "-", # * Set input to pipe
      "-vf", "vflip", # * Flips the image vertically since glReadPixels gives flipped image
      "-an",  # * Don't expect audio
      # "-loglevel", "panic",
      "-c:v", "libx264",  # * H.264 encoding
      "-preset", "medium",  # * Should probably stay at fast/medium later
      "-profile:v", "high",
      "-crf", "17",  # * Ranges 0-51 indicates lossless compression to worst compression. Sane options are 0-30
      "-coder", "1",
      "-tune", "animation",  # * Tunes the encoder for animation and 'cartoons'
      "-pix_fmt", "yuv420p", # * Minimal color data loss on H.264 encode
      "-movflags", "+faststart",
      "-g", "30",
      "-bf", "2",
      filePath & ".mp4"
    ]


  var
    ffmpegProcess: Process
    data = alloc(bufferSize)


  proc writeToFFmpeg(info: pointer, size: int) =
    ffmpegProcess.inputStream().writeData(info, size)
    ffmpegProcess.inputStream().flush()

  stdout.write InfoPrefix, "Launching FFmpeg subprocess with: "
  ffmpegProcess = startProcess("ffmpeg", "", ffmpegOptions, options = {poUsePath, poEchoCmd, poStdErrToStdOut})

  while not scene.done:
    scene.beginFrame()
    scene.tick(goalDeltaTime)
    scene.endFrame()

    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glReadBuffer(GL_BACK)
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data)

    swapBuffers(scene.window)

    try:
      writeToFFmpeg(data, bufferSize)
    except:
      let msg = getCurrentExceptionMsg()
      error msg
      scene.done = true

    if scene.done:
      scene.window.setWindowShouldClose(1)

    pollEvents()

  dealloc(data)
  scene.window.destroyWindow()

  ffmpegProcess.inputStream().flush()
  ffmpegProcess.close()

  let code = ffmpegProcess.waitForExit()
  if code != 0:
    error &"FFmpeg could not close gracefully. Exited with code '{code}'"



proc renderImpl*(userScene: Scene) =
  var
    scene = userScene
    createVideo = false
    createGif = false
    createScreenshot = false

  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      discard

    of cmdLongOption, cmdShortOption:
      case key
      of "r", "run":
        createVideo = false
        scene.debug = true
        break
      of "v", "video", "render":
        createVideo = true
        createGif = false
        scene.debug = false
      of "gif":
        createVideo = false
        createGif = true
        scene.debug = false
      of "s", "size":
        scene.width = value.parseInt()
        scene.height = value.parseInt()
      of "w", "width":
        scene.width = value.parseInt()
      of "h", "height":
        scene.height = value.parseInt()
      of "1080p", "fullhd":
        createVideo = true
        scene.debug = false
        scene.width = 1920
        scene.height = 1080
      of "1440p", "2k":
        createVideo = true
        scene.debug = false
        scene.width = 2880
        scene.height = 1440
      of "2560p", "4k":
        createVideo = true
        scene.debug = false
        scene.width = 3840
        scene.height = 2160
      of "debug":
        scene.debug = value.parseBool()
      of "snap", "screenshot", "image", "picture", "png":
        createScreenshot = true
        createVideo = false
        createGif = false
        scene.debug = false
      else:
        echo "Nanim (c) Copyright 2021 Erik Wilhem Gren"
        echo ""
        echo "  <filename_containing_scene> [options]"
        echo ""
        echo "Options:"
        echo "  -r, --run"
        echo "    Opens a window with the scene rendered in realtime."
        echo "  -v, --video, --render"
        echo "    Enables video rendering mode. Will output video to renders/<name>.mp4"
        echo "  --gif"
        echo "    WARNING: Huge files. Please use with --size:400 or, preferrably, manually convert"
        echo "             the mp4 from --render to a GIF."
        echo "    Enables gif rendering mode. Will output gif to renders/<name>.gif"
        echo "  --snap, --screenshot, --image, --picture, --png"
        echo "    Will create a PNG screenshot of the Scene. Will output to renders/<name>.png"
        echo "  --fullhd, --1080p"
        echo "    Enables video rendering mode with 1080p settings"
        echo "  --2k, --1440p"
        echo "    Enables video rendering mode with 1440p settings"
        echo "  --4k, --2160p"
        echo "    Enables video rendering mode with 2160p settings"
        echo "  -w:WIDTH, --width:WIDTH"
        echo "    Sets width to WIDTH"
        echo "  -h:HEIGHT, --height:HEIGHT"
        echo "    Sets height to HEIGHT"
        echo "  -s:SIZE, --size:SIZE"
        echo "    Sets both width andd height to SIZE"
        echo "  --debug:true|false"
        echo "    Enables debug mode which will visualize the scene's tracks."
        echo "    Default behaviour is to show the visualization in live mode"
        echo "    but not in render mode."
        return

    of cmdEnd: discard

  scene.setupRendering(not createVideo)

  if createScreenshot:
    scene.renderScreenshot()
  else:
    if createVideo or createGif:
      scene.renderWithPipe(createGif)
    else:
      scene.runLiveRenderingLoop()

  nvgDeleteContext(scene.context)
  terminate()


proc render*(userScene: Scene) =
  renderImpl(userScene)

proc render*(userSceneCreator: proc(): Scene) =
  renderImpl(userSceneCreator())
