
import
  nanovg,
  glfw,
  glm,
  opengl,
  os,
  times,
  algorithm,
  sequtils,
  osproc,
  math,
  streams


import
  entities/entity,

  animation/tween,
  animation/easings,

  drawing


proc createNVGContext(): Context =
  let flags = {nifStencilStrokes, nifDebug}
  return nvgCreateContext(flags)


proc loadFonts(context: Context) =
  let fontFolderPath = os.joinPath(os.getAppDir(), "fonts")

  echo "Loading fonts from: " & fontFolderPath

  let fontNormal = context.createFont("montserrat", os.joinPath(fontFolderPath, "Montserrat-Regular.ttf"))
  doAssert not (fontNormal == NoFont)

  let fontThin = context.createFont("montserrat-thin", os.joinPath(fontFolderPath, "Montserrat-Thin.ttf"))
  doAssert not (fontThin == NoFont)

  let fontLight = context.createFont("montserrat-light", os.joinPath(fontFolderPath, "Montserrat-Light.ttf"))
  doAssert not (fontLight == NoFont)

  let fontBold = context.createFont("montserrat-bold", os.joinPath(fontFolderPath, "Montserrat-Bold.ttf"))
  doAssert not (fontBold == NoFont)


proc createWindow(resizable: bool = true, width: int = 900, height: int = 500): Window =
  var config = DefaultOpenglWindowConfig
  config.size = (w: width, h: height)
  config.title = "Nanim"
  config.resizable = resizable
  config.nMultiSamples = 8
  config.debugContext = true
  config.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  config.version = glv30

  let window = newWindow(config)
  if window == nil: quit(-1)

  # Enables vsync
  swapInterval(0)

  return window


type
  Scene* = ref object of RootObj
    window: Window
    context*: Context

    width*: int
    height*: int

    time*: float
    restartTime: float
    lastUpdateTime: float
    lastTickTime: float
    deltaTime: float

    frameBufferWidth: int32
    frameBufferHeight: int32

    tweens*: seq[Tween]

    currentTweens: seq[Tween]
    oldTweens: seq[Tween]
    futureTweens: seq[Tween]

    entities*: seq[Entity]
    projectionMatrix*: Mat4x4[float]

    pixelRatio: float

    done*: bool


proc scale*(scene: Scene, d: float = 0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.scale(vec3(d,d,d))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc rotate*(scene: Scene, angle: float = 0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.rotateZ(angle)

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc move*(scene: Scene, dx: float = 0, dy: float = 0, dz: float = 0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.translate(vec3(dx, dy, dz))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc newScene*(): Scene =
  new(result)
  result.time = cpuTime()
  result.restartTime = result.time
  result.lastUpdateTime = -100.0
  result.lastTickTime = -100.0
  result.tweens = @[]
  result.projectionMatrix = mat4x4[float](vec4[float](1,0,0,0),
                                          vec4[float](0,1,0,0),
                                          vec4[float](0,0,1,0),
                                          vec4[float](0,0,0,1))
  result.done = false


proc add*(scene: Scene, entities: varargs[Entity]) =
  scene.entities.add(@entities)


proc animate*(scene: Scene, tweens: varargs[Tween]) =
  var previousEndtime: float

  try:
    let previousTween = scene.tweens[high(scene.tweens)]
    previousEndTime = previousTween.startTime + previousTween.duration
  except IndexDefect:
    previousEndTime = 0.0


  for tween in @tweens:
    tween.startTime = previousEndTime
    scene.tweens.add(tween)


proc play*(scene: Scene, tweens: varargs[Tween]) =
    scene.animate(tweens)


proc wait*(scene: Scene, duration: float = defaultDuration) =
  var interpolators: seq[proc(t: float)]

  interpolators.add(proc(t: float) = discard)

  scene.animate(newTween(interpolators,
                         linear,
                         duration))


proc showAllEntities*(scene: Scene) =
  var tweens: seq[Tween]

  for entity in scene.entities:
    tweens.add(entity.show())

  scene.play(tweens)


proc scaleToUnit(scene: Scene, fraction: float = 1000f) =
  let n = min(scene.width, scene.height).float
  let d = max(scene.width, scene.height).float

  let compensation = (d - n)/2f

  let unit = n / fraction

  if scene.width > scene.height:
    scene.context.translate(compensation, 0f)
  else:
    scene.context.translate(0f, compensation)

  scene.context.scale(unit, unit)


proc startHere*(scene: Scene) =
  scene.time = scene.tweens[high(scene.tweens)].startTime


func project(point: Vec3[float], projection: Mat4x4[float]): Vec3[float] =
  let v4 = vec4(point.x, point.y, point.z, 1.0)
  let res = projection * v4
  result = vec3(res.x, res.y, res.z)


proc draw*(scene: Scene, entity: Entity) =
  scene.context.save()

  scene.context.translate(entity.position.x, entity.position.y)
  scene.context.scale(entity.scaling.x, entity.scaling.y)
  scene.context.rotate(entity.rotation)

  entity.draw(scene.context)

  scene.context.restore()


proc draw*(scene: Scene) =
  glViewport(0, 0, scene.frameBufferWidth, scene.frameBufferHeight)
  scene.context.beginFrame(scene.width.cfloat, scene.height.cfloat, scene.pixelRatio)

  scene.context.save()
  scene.scaleToUnit()

  clearWithColor(rgb(255, 255, 255))

  for entity in scene.entities:
    var intermediate = entity.deepCopy()

    # Apply the scene's projection matrix to every point of every entity
    intermediate.points = sequtils.map(intermediate.points,
                                       proc(point: Vec3[float]): Vec3[float] =
                                         point.project(scene.projectionMatrix))

    scene.draw(intermediate)

  scene.context.restore()
  scene.context.endFrame()


proc tick(scene: Scene) =
  var (windowWidth, windowHeight) = scene.window.size

  scene.width = windowWidth
  scene.height = windowHeight

  var (frameBufferWidth, frameBufferHeight) = scene.window.framebufferSize

  scene.frameBufferHeight = frameBufferHeight
  scene.frameBufferWidth = frameBufferWidth
  scene.pixelRatio = 1

  # By first evaluating all future tweens in reverse order, then old tweens and
  # finally the current ones, we assure that all tween's have been reset and/or
  # completed correctly.
  scene.oldTweens = @[]
  scene.currentTweens = @[]
  scene.futureTweens = @[]

  for tween in scene.tweens:
    if scene.time  > tween.startTime + tween.duration:
      scene.oldTweens.add(tween)
    elif scene.time  < tween.startTime:
      scene.futureTweens.add(tween)
    else:
      scene.currentTweens.add(tween)


  # when not defined(release):
    # let progress = (len(scene.oldTweens) + len(scene.currentTweens)) / len(scene.tweens)
    # stdout.write "\r" & $len(scene.oldTweens) & ":" & $len(scene.currentTweens) & ":" & $len(scene.futureTweens) & " --- " & $(round(progress * 100)) & "%"

  for tween in scene.oldTweens & scene.futureTweens.reversed():
    tween.evaluate(scene.time)

  for tween in scene.currentTweens:
    tween.evaluate(scene.time)

  scene.draw()

  scene.lastTickTime = cpuTime() * 1000

  if len(scene.currentTweens) == 0 and len(scene.futureTweens) == 0:
    scene.done = true


proc update*(scene: Scene) =
  let time = cpuTime() * 1000

  # Try to adhere to a max 120 fps
  # Since vsync is enabled, this should raarely ever
  let goalDelta = 1000.0/120.0
  if time - scene.lastTickTime >= goalDelta:
    scene.time = scene.time + time - scene.lastTickTime
    scene.deltaTime = time - scene.lastTickTime
    scene.tick()

    if scene.done:
      scene.time = 0
      scene.done = false

  scene.lastUpdateTime = time


proc setupCallbacks(scene: Scene) =
  scene.window.framebufferSizeCb = proc(w: Window, s: tuple[w, h: int32]) =
    scene.tick()

  scene.window.windowRefreshCb = proc(w: Window) =
    scene.tick()


proc setupRendering(scene: var Scene, resizable: bool = true, width: int = 1920, height: int = 1080) =
  initialize()
  scene.window = createWindow(resizable, width, height)
  if resizable: scene.setupCallbacks()

  doAssert glInit()

  glEnable(GL_MULTISAMPLE)

  makeContextCurrent(scene.window)

  nvgInit(getProcAddress)
  scene.context = createNVGContext()

  scene.context.loadFonts()


proc runLiveRenderingLoop(scene: Scene) =
  # TODO: Make scene.update loop be on a separate thread. That would allow rendering even while user is dragging window...
  while not scene.window.shouldClose:
    scene.update()
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
    "-preset", "fast",  # * Should probably stay at fast/medium later
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

    startProcess("ffmpeg", "", ffmpegOptions & partName, options = {poUsePath, poEchoCmd})

  proc closeFFMpeg() =
    ffmpegProcess.inputStream().flush()
    ffmpegProcess.close()

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
    i = i + 1
    n = n + 1
    pollEvents()

    scene.tick()
    scene.time = scene.time + goalDeltaTime

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
      echo msg
      scene.done = true

    if scene.done:
      scene.window.shouldClose = true

  partsFile.close()
  dealloc(data)
  scene.window.destroy()
  closeFFMpeg()

  let res = execShellCmd("ffmpeg -y -f concat -safe 0 -loglevel panic -i " & partsFileName & " -c copy " & os.joinPath(rendersFolderPath, "final.mp4"))
  doAssert res == 0


proc renderVideo(scene: Scene) =
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

  createDir(rendersFolderPath)
  # let ffmpegProcess = startProcess("ffmpeg", "", ffmpegOptions, options = {poUsePath, poEchoCmd})
  var data = alloc(bufferSize)

  let dataFilePath = os.joinPath(rendersFolderPath, "data.txt")
  var dataFile = open(dataFilePath, fmReadWrite)

  var i = 0
  while not scene.window.shouldClose:
    i = i + 1
    pollEvents()

    scene.tick()
    scene.time = scene.time + goalDeltaTime

    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glReadBuffer(GL_BACK)
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data)

    swapBuffers(scene.window)

    try:
      if i mod goalFps == 0:
        dataFile.flushFile()

      let writtenBytes = dataFile.writeBuffer(data, bufferSize)
      doAssert writtenBytes == bufferSize
    except:
      let
        msg = getCurrentExceptionMsg()
      echo msg
      scene.done = true

    if scene.done:
      scene.window.shouldClose = true

  dealloc(data)
  scene.window.destroy()
  dataFile.flushFile()
  close(dataFile)

  let outputVideoPath = os.joinPath(rendersFolderPath, "scene.mp4")

  # * ffmpeg -y -f rawvideo -pix_fmt rgba -s 1920x1080 -r 60 -i - -vf vflip -an -c:v libx264 -preset fast -crf 18 -tune animation -pix_fmt yuv444p
  let ffmpegOptions = @[
    "-y",
    "-f", "rawvideo",
    "-pix_fmt", "rgba",
    "-s", $width & "x" & $height,
    "-r", $goalFps,
    "-i", dataFilePath, # * Currently, the temporary data file si used. Would like to get pipes working but startProcess in nim is a bit clunky...
    "-vf", "vflip", # * Flips the image vertically since glReadPixels gives flipped image
    "-an",  # * Don't expect audio,
    # "-loglevel", "panic",
    "-c:v", "libx264",  # * H.264 encoding
    "-preset", "fast",  # * Should probably stay at fast/medium later
    "-crf", "18",  # * Ranges 0-51 indicates lossless compression to worst compression. Sane options are 0-30
    "-tune", "animation",  # * Tunes the encoder for animation and 'cartoons'
    "-pix_fmt", "yuv444p", # * Minimal color data loss on H.264 encode
    outputVideoPath
  ]
  # startProcess("ffmpeg", "", ffmpegOptions, options = {poUsePath, poEchoCmd})

  var command = "ffmpeg"
  for option in ffmpegOptions:
    command &= " " & option

  echo command

  let res = execShellCmd(command)
  doAssert res == 0


proc render*(userScene: Scene, createVideo: bool = false, width: int = 1920, height: int = 1080) =
  var scene = userScene.deepCopy()

  scene.setupRendering(not createVideo, width, height)

  if createVideo:
    when defined(oldRenderer): scene.renderVideo()
    else: scene.renderVideoWithPipe()
  else:
    scene.runLiveRenderingLoop()

  nvgDeleteContext(scene.context)
  terminate()


proc render*(userSceneCreator: proc(): Scene, createVideo: bool = false, width: int = 1920, height: int = 1080) =
  render(userSceneCreator(), createVideo, width, height)

template createRenderConfig(name: untyped, width: int, height: int) =
  proc name*(userScene: Scene) = render(userScene, true, width, height)
  proc name*(userSceneCreator: proc(): Scene) = render(userSceneCreator(), true, width, height)

createRenderConfig(renderFullHD, 1920, 1080)
createRenderConfig(render1080p, 1920, 1080)
createRenderConfig(render1440p, 2880, 1440)
createRenderConfig(render4K, 3840, 2160)
