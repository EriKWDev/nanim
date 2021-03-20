
import
  nanovg,
  glfw,
  opengl,
  os,
  times,
  algorithm


import
  entities/entity,
  animation/tween,
  animation/easings


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


proc createWindow(): Window =
  var config = DefaultOpenglWindowConfig
  config.size = (w: 900, h: 500)
  config.title = "Testing NanoVG"
  config.resizable = true
  config.nMultiSamples = 8
  config.debugContext = true
  config.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  config.version = glv30

  let window = newWindow(config)
  if window == nil: quit(-1)

  when defined(vsync):
    swapInterval(1)
  else:
    swapInterval(0)

  return window


type
  Scene* = ref object of RootObj
    window: Window
    context: Context

    width: int
    height: int

    time: float
    lastUpdateTime: float

    frameBufferWidth: int32
    frameBufferHeight: int32

    tweens: seq[Tween]
    entities: seq[Entity]

    pixelRatio: float


proc newScene*(): Scene =
  initialize()

  new(result)
  result.window = createWindow()
  result.time = cpuTime()
  result.lastUpdateTime = -100.0
  result.tweens = @[]

  doAssert glInit()

  glEnable(GL_MULTISAMPLE)

  makeContextCurrent(result.window)

  nvgInit(getProcAddress)
  result.context = createNVGContext()

  result.context.loadFonts()


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


proc clearWithColor(color: Color = black(1f)) =
  glClearColor(color.r, color.g, color.b, color.a)
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT or
          GL_STENCIL_BUFFER_BIT)


proc draw*(scene: Scene) =
  let context = scene.context

  # discard context.currentTransform()

  glViewport(0, 0, scene.frameBufferWidth, scene.frameBufferHeight)
  context.beginFrame(scene.width.cfloat, scene.height.cfloat, scene.pixelRatio)

  scene.scaleToUnit()

  clearWithColor(rgb(255, 255, 255))

  for entity in scene.entities:
    context.draw(entity)

  context.endFrame()


proc tick(scene: Scene) =
  var (windowWidth, windowHeight) = scene.window.size

  scene.width = windowWidth
  scene.height = windowHeight

  var (frameBufferWidth, frameBufferHeight) = scene.window.framebufferSize

  scene.frameBufferHeight = frameBufferHeight
  scene.frameBufferWidth = frameBufferWidth
  scene.pixelRatio = 1


  var oldTweens: seq[Tween] = @[]
  var currentTweens: seq[Tween] = @[]
  var futureTweens: seq[Tween] = @[]

  let currentTime = scene.time * 1000

  for tween in scene.tweens:
    if currentTime > tween.startTime + tween.duration: oldTweens.add(tween)
    elif currentTime < tween.startTime: futureTweens.add(tween)
    else: currentTweens.add(tween)

  for tween in oldTweens & futureTweens.reversed():
    tween.evaluate(currentTime)

  for tween in currentTweens:
    tween.evaluate(currentTime)

  scene.draw()

  swapBuffers(scene.window)

  scene.lastUpdateTime = cpuTime()


proc update*(scene: Scene) =
  scene.time = cpuTime()

  if scene.time - scene.lastUpdateTime > 1/120:
    scene.tick()

  pollEvents()


proc setupCallbacks(scene: Scene) =
  scene.window.framebufferSizeCb = proc(w: Window, s: tuple[w, h: int32]) =
    scene.update()

  scene.window.windowRefreshCb = proc(w: Window) =
    scene.draw()
    w.swapBuffers()


proc render*(scene: Scene) =
  scene.setupCallbacks()

  while not scene.window.shouldClose:
    scene.update()

  nvgDeleteContext(scene.context)
  terminate()