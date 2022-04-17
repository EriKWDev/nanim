
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
  when not defined(emscripten):
    loadExtensions()

  nvgInit(getProcAddress)
  scene.context = createNVGContext()
  scene.loadFonts()

  scene.window.getFramebufferSize(scene.frameBufferWidth.addr, scene.frameBufferHeight.addr)
  scene.updatePixelRatio()


var cursorPositionCallback: proc(window: Window, x, y: cdouble) {.closure.}

proc liveLoop(scene: Scene) =
  scene.beginFrame()
  scene.update()
  scene.endFrame()

  swapBuffers(scene.window)
  pollEvents()

when defined(emscripten):
  proc emscripten_set_main_loop(f: proc() {.cdecl.}, a: cint, b: bool) {.importc.}

  var sceneCaller: proc() {.closure.}

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

  when not defined(emscripten):
    while scene.window.windowShouldClose() == 0:
      scene.liveLoop()
  else:
    sceneCaller =
      proc() {.closure.} =
        scene.liveLoop()

    proc mainLoop() {.cdecl.} =
      sceneCaller()

    emscripten_set_main_loop(mainLoop, 0, true)

  scene.window.destroyWindow()

## Thanks to https://github.com/define-private-public/random-art-Nim/blob/30607d4a912b662be7a3ac1ef8e341e0a5295226/opengl_helpers.nim#L100
proc offset(some: pointer; b: int): pointer {.inline.} =
  result = cast[pointer](cast[int](some) + b)


proc renderScreenshot(scene: Scene, filePath: string) =
  var
    width: cint
    height: cint

  scene.window.getWindowSize(width.addr, height.addr)

  let
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize

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


proc renderWithPipe(scene: Scene, filePath: string, createGif = false) =
  var
    width: cint
    height: cint

  scene.window.getFramebufferSize(width.addr, height.addr)

  let
    rgbaSize = sizeof(cint)
    bufferSize: int = width * height * rgbaSize
    goalDeltaTime = 1000.0/scene.goalFPS

  var ffmpegOptions: seq[string]

  if createGif:
    warn "Currently, the built in GIF-generation is very primitive. It is recommended to instead use --render and manually convert the render to GIF for better results."

    if scene.goalFps > 20.0:
      warn "You are rendering a GIF at a high framerate. Consider using --fps:15"

    if scene.width > 1000 or scene.height > 1000:
      warn "You are rendering a GIF at a larger than optimal size. Consider shrinking it down with --width:W, --height:H or --size:S"

    ffmpegOptions = @[
      "-y",
      "-f", "rawvideo",
      "-pix_fmt", "rgba",
      "-s", $width & "x" & $height,
      "-r", $scene.goalFps,
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
      "-r", $scene.goalFps,
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


func defaultOptions: RenderOptions =
    result.debug = true
    result.createVideo = false
    result.createGif = false
    result.createScreenshot = false

    result.width = -1
    result.height = -1

    result.ratioVertical = 1.0
    result.ratioHorizontal = 1.0

    result.goalFps = -1

const allowedExtensions = [".mp4", ".gif", ".png"]

proc update*(options: var RenderOptions) =
  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      discard
    of cmdLongOption, cmdShortOption:
      case key
      of "r", "run":
        options.createVideo = false
        options.debug = true
        warn "Deprecated option '-r/--run'. This is default behaviour, no need to specify."
      of "v", "video", "render":
        options.createVideo = true
        options.createGif = false
        options.debug = false
      of "gif":
        options.createVideo = false
        options.createGif = true
        options.debug = false
      of "s", "size":
        options.width = value.parseInt()
        options.height = value.parseInt()
      of "w", "width":
        options.width = value.parseInt()
      of "h", "height":
        options.height = value.parseInt()
      of "ratio":
        let ratios = value.split(":")
        if len(ratios) == 2:
          options.ratioHorizontal = ratios[0].parseFloat()
          options.ratioVertical = ratios[1].parseFloat()
      of "square":
        options.width = 1000
        options.height = 1000
      of "1080p", "fullhd":
        options.width = 1920
        options.height = 1080
      of "1440p", "2k":
        options.width = 2880
        options.height = 1440
      of "fps", "rate":
        options.goalFPS = value.parseFloat()
      of "shorts":
        options.width = 1440
        options.height = 2560
      of "2560p", "4k":
        options.width = 3840
        options.height = 2160
      of "debug":
        options.debug = value.parseBool()
      of "snap", "screenshot", "image", "picture", "png":
        options.createScreenshot = true
        options.createVideo = false
        options.createGif = false
        options.debug = false
      of "folder", "folderPath":
        options.folderPath = value
      of "file", "fileName":
        options.fileName = value
      else:
        echo "Nanim (c) Copyright 2021 Erik Wilhem Gren"
        echo ""
        echo "  <filename_containing_scene> [options]"
        echo ""
        echo "Options:"
        echo "  -v, --video, --render"
        echo "    Enables video rendering mode. Will output video to renders/<name>.mp4"
        echo "  --gif"
        echo "    WARNING: Huge files. Please use with --size:400 --fps:15 or, preferably,"
        echo "             manually convert the mp4 from --render to a GIF."
        echo "    Enables gif rendering mode. Will output gif to renders/<name>.gif"
        echo "  --snap, --screenshot, --image, --picture, --png"
        echo "    Will create a PNG screenshot of the Scene. Will output to renders/<name>.png"
        echo "  --fullhd, --1080p"
        echo "    width 1920, height 1080 (16:9)"
        echo "  --2k, --1440p"
        echo "    width 2880, height 2560 (18:9)"
        echo "  --4k, --2160p"
        echo "    width 3840, height 2160 (18:9)"
        echo "  --shorts"
        echo "    width 1440, height 2560 (9:16)"
        echo "  --square"
        echo "    width 1000, height 1000 (1:1)"
        echo "  --ratio:W:H"
        echo "    Sets the ratio between width and height. Example: --ratio:16:9 --width:1920"
        echo "    will set width to 1920 and height to 1080"
        echo "  -w:WIDTH, --width:WIDTH"
        echo "    Sets width to WIDTH"
        echo "  -h:HEIGHT, --height:HEIGHT"
        echo "    Sets height to HEIGHT"
        echo "  -s:SIZE, --size:SIZE"
        echo "    Sets both width and height to SIZE"
        echo "  --fps:FPS, --rate:FPS"
        echo "    Sets the desired framerate to FPS"
        echo "  --debug:true|false"
        echo "    Enables debug mode which will visualize the scene's tracks."
        echo "    Default behaviour is to show the visualization in live mode"
        echo "    but not in render mode."
        echo "  --folder:PATH, --folderPath:PATH"
        echo "    Sets folder path to PATH"
        echo "    Default is 'renders'"
        echo "  --file:NAME.EXT, --fileName:NAME.EXT"
        echo "    Sets file name to NAME.EXT"
        echo "    EXT must be one of " & allowedExtensions.join(", ")
        echo "    Default is 'final_HH_MM_SS'"
        return

    of cmdEnd: discard

  # TODO: Refactor? I was tired when I did this, but it works.
  if options.width > 0 or options.height > 0:
    let ratio = options.ratioVertical / options.ratioHorizontal
    if options.width >= options.height:
      options.width = options.width
      options.height = int(options.width.float * ratio)
    else:
      options.width = int(options.height.float * ratio)
      options.height = options.height


proc setFilePath(folderPath, fileName: string): string =
  var
    folderPath = folderPath
    fileName = fileName
  if folderPath == "":
    folderPath = os.joinPath(getCurrentDir(), "renders")
  createDir(folderPath)

  if fileName == "":
    fileName = "final_" & $times.now().getClockStr().replace(":", "_")
  result = joinPath(folderPath, fileName)


proc renderImpl*(userScene: Scene, options: RenderOptions = defaultOptions(), updateOptions: bool = true) =
  var
    scene = userScene
    options = options

  if updateOptions:
    update options

  scene.debug = options.debug
  if options.goalFPS > 0:
    scene.goalFPS = options.goalFPS
  if options.height > 0:
    scene.height = options.height
  if options.width > 0:
    scene.width = options.width

  info &"Width: {scene.width}, Height: {scene.height} (ratio: {scene.width.float/scene.height.float:.2f}:1.00), FPS: {scene.goalFPS}"

  scene.setupRendering(not options.createVideo)

  if options.createScreenshot or options.createVideo or options.createGif:
    let filePath = setFilePath(options.folderPath, options.fileName)
    if options.createScreenshot:
      scene.renderScreenshot(filePath)
    else:
      scene.renderWithPipe(filePath, options.createGif)
  else:
    scene.runLiveRenderingLoop()

  nvgDeleteContext(scene.context)
  terminate()

proc render*(userScene: Scene, options: RenderOptions = defaultOptions(), updateOptions: bool = true) =
  renderImpl(userScene, options, updateOptions)

proc render*(userSceneCreator: proc(): Scene, options: RenderOptions = defaultOptions(), updateOptions: bool = true) =
  renderImpl(userSceneCreator(), options, updateOptions)

proc render*(userScene: Scene | proc(): Scene, url: string; debug = false, width, height = -1; ratioHorizontal, ratioVertical = 1.0) =
  let (dir, name, ext) = splitFile(url)
  doAssert ext in allowedExtensions, ext & " is not a valid extension, must be one of " & allowedExtensions.join(", ")
  let options = RenderOptions(
    debug: debug,
    createVideo: if ext == ".mp4": true else: false,
    createGif: if ext == ".gif": true else: false,
    createScreenshot: if ext == ".png": true else: false,
    width: width,
    height: height,
    ratioHorizontal: ratioHorizontal,
    ratioVertical: ratioVertical,
    folderPath: dir,
    fileName: name,
  )
  render(userScene, options, updateOptions=false)
