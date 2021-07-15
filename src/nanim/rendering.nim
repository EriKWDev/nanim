
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
  tables,
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

  when defined(MacOS) or defined(MacOSX):
    windowHint(VERSION_MAJOR, 3)
    windowHint(VERSION_MINOR, 2)
    windowHint(CONTEXT_VERSION_MAJOR, 3)
    windowHint(CONTEXT_VERSION_MINOR, 2)
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


template get(f: untyped): bool {.dirty.} =
  var win {.inject.} = gWindowTable.getOrDefault(handle)
  var cb {.inject.} = if not win.isNil: win.f else: nil

  not cb.isNil

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
  when not defined(Windows):
    glEnable(GL_MULTISAMPLE)
    glEnable(GL_BLEND)
    glEnable(GL_STENCIL_TEST)
    glEnable(GL_BACK)

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


proc renderVideoWithPipe(scene: Scene) =
  var
    width: cint
    height: cint

  scene.window.getWindowSize(width.addr, height.addr)

  let
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize
    goalFps = 60
    goalDeltaTime = 1000.0/goalFps.float

  let
    rendersFolderPath = os.joinPath(os.getAppDir(), "renders")
    partsFolderPath = os.joinPath(rendersFolderPath, "parts")

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
    "-crf", "17",  # * Ranges 0-51 indicates lossless compression to worst compression. Sane options are 0-30
    "-tune", "animation",  # * Tunes the encoder for animation and 'cartoons'
    "-pix_fmt", "yuv444p" # * Minimal color data loss on H.264 encode
  ]

  var
    ffmpegProcess: Process
    data = alloc(bufferSize)
    partNames: seq[string]

  let
    partsFileName = os.joinPath(partsFolderPath, "parts.txt")
    partsFile = open(partsFileName, fmWrite)

  proc startFFMpeg(n: int = 0) =
    let partName = os.joinPath(partsFolderPath, "scene_" & $n & ".mp4")
    partNames.add(partName)
    partsFile.writeLine("file '" & partName & "'")
    partsFile.flushFile()

    stdout.write InfoPrefix, "Launching FFMpeg subprocess with: "
    ffmpegProcess = startProcess("ffmpeg", "", ffmpegOptions & partName, options = {poUsePath, poEchoCmd})

  proc closeFFMpeg() =
    ffmpegProcess.inputStream().flush()
    ffmpegProcess.close()
    doAssert ffmpegProcess.waitForExit() == 0

  proc restartFFMPeg(n: int = 0) =
    closeFFMpeg()
    startFFMpeg(n)

  proc writeToFFMpeg(info: pointer, size: int) =
    ffmpegProcess.inputStream().writeData(info, size)

  var
    i = 0
    n = 0

  startFFMpeg(i)

  while not scene.done:
    scene.beginFrame()
    scene.tick(goalDeltaTime)
    scene.endFrame()

    inc i
    inc n

    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glReadBuffer(GL_BACK)
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data)

    swapBuffers(scene.window)

    try:
      if n > scene.secretRenderingNumber:
        restartFFMPeg(i)
        n = 0

      writeToFFMpeg(data, bufferSize)
    except:
      let msg = getCurrentExceptionMsg()
      error msg
      scene.done = true

    if scene.done:
      scene.window.setWindowShouldClose(1)

    pollEvents()

  partsFile.flushFile()
  partsFile.close()
  dealloc(data)
  scene.window.destroyWindow()
  closeFFMpeg()

  # By sleeping just a little bit it seems that the file is really
  # closed and written. This fixes bugs with extremely short scenes.

  sleep(500)

  # ffmpeg -y -f concat -safe 0 -i './renders/parts/parts.txt' -c copy final.mp4
  let command = "ffmpeg -y -f concat -safe 0 -loglevel warning -i " & partsFileName & " -c copy " & os.joinPath(rendersFolderPath, "final_" & $times.now().getClockStr().replace(":", "_") & ".mp4")
  info "Stitching parts together with: ", command
  discard execCmd(command)
  warn "In case the final stitching command failed, you might have to execute the command manually once all ffmpeg-processes have finished. You can check this in task manager (or by listening to your fans xP)."


proc renderImpl*(userScene: Scene) =
  var
    scene = userScene
    createVideo = false

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
        scene.debug = false
      of "secret":
        scene.secretRenderingNumber = value.parseInt()
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
        echo "  --secret:VALUE"
        echo "    Sets the secret rendering value. 'Restarts FFMpeg every VALUE frame'"
        echo "    Default value is set to 60 and should work for most scenes. Lower in"
        echo "    case a complex or high resolution scene fails to render."
        echo "  --debug:true|false"
        echo "    Enables debug mode which will visualize the scene's tracks."
        echo "    Default behaviour is to show the visualization in live mode"
        echo "    but not in render mode."
        return

    of cmdEnd: discard

  scene.setupRendering(not createVideo)

  if createVideo:
    scene.renderVideoWithPipe()
  else:
    scene.runLiveRenderingLoop()

  nvgDeleteContext(scene.context)
  terminate()


proc render*(userScene: Scene) =
  renderImpl(userScene)

proc render*(userSceneCreator: proc(): Scene) =
  renderImpl(userSceneCreator())
