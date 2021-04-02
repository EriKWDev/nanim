
import
  nanovg,
  glfw,
  glm,
  opengl,
  os,
  times,
  sequtils,
  osproc,
  math,
  streams,
  tables,
  parseopt,
  strutils


import
  entities/entity,

  animation/tween,
  animation/easings,

  drawing,
  logging


proc createNVGContext(): NVGContext =
  let flags = {nifStencilStrokes, nifDebug}
  return nvgCreateContext(flags)


proc loadFonts(context: NVGContext) =
  let fontFolderPath = os.joinPath(os.getAppDir(), "fonts")

  info "Loading fonts from: " & fontFolderPath

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


const DefaultTrackId = 0

type
  Scene* = ref object of RootObj
    window: Window
    context*: NVGContext

    width*: int
    height*: int

    background*: proc(scene: Scene)
    foreground*: proc(scene: Scene)

    time*: float
    restartTime: float
    lastTickTime: float
    deltaTime: float

    frameBufferWidth: int32
    frameBufferHeight: int32

    currentTweenTrackId*: int
    tweenTracks*: Table[int, TweenTrack]

    entities*: seq[Entity]
    projectionMatrix*: Mat4x4[float]

    pixelRatio: float

    done*: bool


proc pscale*(scene: Scene, d: float = 0): Tween =
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


proc protate*(scene: Scene, dangle: float = 0, mode: AngleMode = defaultAngleMode): Tween =
  var interpolators: seq[proc(t: float)]

  let
    angle = case mode:
      of amDegrees: degToRad(dangle)
      of amRadians: dangle

    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.rotateZ(angle)

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc pmove*(scene: Scene, dx: float = 0, dy: float = 0, dz: float = 0): Tween =
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
  result.time = 0.0
  result.restartTime = result.time
  result.lastTickTime = 0.0
  result.tweenTracks = initTable[int, TweenTrack]()
  result.currentTweenTrackId = DefaultTrackId

  result.tweenTracks[result.currentTweenTrackId] = newTweenTrack()
  result.projectionMatrix = mat4x4[float](vec4[float](1,0,0,0),
                                          vec4[float](0,1,0,0),
                                          vec4[float](0,0,1,0),
                                          vec4[float](0,0,0,1))
  result.done = false
  result.background = proc(scene: Scene) = clearWithColor(rgb(255, 255, 255))
  result.foreground = proc(scene: Scene) = discard


func getLatestTween*(scene: Scene): Tween =
  discard scene.tweenTracks.hasKeyOrPut(scene.currentTweenTrackId, newTweenTrack())
  return scene.tweenTracks[scene.currentTweenTrackId].getLatestTween()


proc add*(scene: Scene, entities: varargs[Entity]) =
  scene.entities.add(entities)


proc switchTrack*(scene: Scene, newTrackId: int = DefaultTrackId) =
  scene.currentTweenTrackId = newTrackId
  discard scene.tweenTracks.hasKeyOrPut(newTrackId, newTweenTrack())


template onTrack*(scene: Scene, trackId: int = DefaultTrackId, body: untyped): untyped =
  let oldTrackId = scene.currentTweenTrackId
  scene.switchTrack(trackId)

  body

  scene.switchTrack(oldTrackId)


proc switchToDefaultTrack*(scene: Scene) =
  scene.switchTrack(DefaultTrackId)


proc animate*(scene: Scene, tweens: varargs[Tween]) =
  var previousEndtime: float

  try:
    let previousTween = scene.getLatestTween()
    previousEndTime = previousTween.startTime + previousTween.duration
  except IndexDefect:
    previousEndTime = 0.0

  for tween in tweens:
    tween.startTime = previousEndTime

  discard scene.tweenTracks.hasKeyOrPut(scene.currentTweenTrackId, newTweenTrack())
  scene.tweenTracks[scene.currentTweenTrackId].add(tweens)


proc play*(scene: Scene, tweens: varargs[Tween]) =
  scene.animate(tweens)


proc wait*(scene: Scene, duration: float = defaultDuration) =
  scene.animate(newTween(@[], linear, duration))


proc syncTracks*(scene: Scene, trackIds: varargs[int]) =
  var ids: seq[int]

  for id in trackIds:
      ids &= id

  if len(ids) == 0:
    for key in scene.tweenTracks.keys:
      ids &= key

  var waitEndTime = 0.0

  for id in ids:
    discard scene.tweenTracks.hasKeyOrPut(id, newTweenTrack())

    let
      lastTweenOnTrack = scene.tweenTracks[id].getLatestTween()
      lastTweenEndTime = lastTweenOnTrack.startTime + lastTweenOnTrack.duration

    if lastTweenEndTime > waitEndTime:
      waitEndTime = lastTweenEndTime

  let oldId = scene.currentTweenTrackId

  for id in ids:
    scene.switchTrack(id)
    let
      latestTween = scene.getLatestTween()
      waitDuration = waitEndTime - (latestTween.startTime + latestTween.duration)

    if waitDuration > 0:
      scene.wait(waitDuration)

  scene.switchTrack(oldId)


proc show*(scene: Scene, entity: Entity) =
  scene.play(entity.show())


proc showAllEntities*(scene: Scene) =
  var tweens: seq[Tween]

  for entity in scene.entities:
    tweens.add(entity.show())

  scene.play(tweens)


proc scaleToUnit(scene: Scene, fraction: float = 1000f, compensate: bool = true) =
  let n = min(scene.width, scene.height).float
  let d = max(scene.width, scene.height).float

  let unit = n / fraction

  if compensate:
    let compensation = (d - n)/2f
    if scene.width > scene.height:
      scene.context.translate(compensation, 0f)
    else:
      scene.context.translate(0f, compensation)

  scene.context.scale(unit, unit)


proc startHere*(scene: Scene, forceUseInReleaseMode: bool = false) =
  when defined(release):
    if forceUseInReleaseMode:
      let latestTween = scene.getLatestTween()
      scene.time = latestTween.startTime + latestTween.duration
      scene.restartTime = scene.time

  else:
    if not forceUseInReleaseMode:
      warn "scene.startHere() utilized. Will be ignored if compiled using '-d:release'. Call scene.startHere(true) if it is intended to be left even in release mode."

    let latestTween = scene.getLatestTween()
    scene.time = latestTween.startTime + latestTween.duration
    scene.restartTime = scene.time


func project(point: Vec3[float], projection: Mat4x4[float]): Vec3[float] =
  let v4 = vec4(point.x, point.y, point.z, 1.0)
  let res = projection * v4
  result = vec3(res.x, res.y, res.z)


proc draw*(scene: Scene, entity: Entity) =
  scene.context.save()

  scene.context.translate(entity.position.x, entity.position.y)
  scene.context.scale(entity.scaling.x, entity.scaling.y)
  scene.context.rotate(entity.rotation)

  for child in entity.children:
    scene.draw(child)

  entity.draw(scene.context)

  scene.context.restore()


proc visualizeTracks(scene: Scene) =
  scene.context.save()
  scene.scaleToUnit(compensate=true)
  let
    numberOfTracks = scene.tweenTracks.len()
    trackHeight = min(100.0/numberOfTracks.float, 30)

  var endTime: float = -1

  for track in scene.tweenTracks.values:
    let endTween = track.getLatestTween()
    if endTween.startTime + endTween.duration > endTime:
      endTime = endTween.startTime + endTween.duration

  let unit = 1000.0

  var i = 0
  for id, track in scene.tweenTracks.pairs:
    scene.context.fillColor(rgb(100, 100, 200))
    scene.context.textAlign(haLeft, vaMiddle)
    discard scene.context.text(-80, (i.float + 0.7) * trackHeight, "Track #" & $(id))

    for tween in track.tweens:
      scene.context.fillColor(rgb(100, 100, 200))
      if tween.interpolators.len() == 0:
        scene.context.strokeColor(rgb(100, 200, 100))

      scene.context.beginPath()
      scene.context.roundedRect(tween.startTime/endTime * unit + 5,
                                i.float * trackHeight + 5,
                                tween.duration/endTime * unit - 5,
                                trackHeight - 5,
                                10)
      scene.context.closePath()

      if tween.interpolators.len() == 0:
        scene.context.strokeWidth(2)
        scene.context.stroke()
      else:
        scene.context.fill()

    i = i + 1

  if scene.restartTime > 0:
    let x = scene.restartTime/endTime * unit

    let gradient = scene.context.linearGradient(x, 2.5, x + 200, 2.5, rgb(256, 100, 130), rgba(256, 100, 130, 0))

    scene.context.beginPath()
    scene.context.roundedRect(x + 2.5, 2.5, 1 * unit, trackHeight * numberOfTracks.float, 10)
    scene.context.closePath()
    scene.context.strokePaint(gradient)
    scene.context.stroke()

  scene.context.fillColor(rgb(100, 200, 200))
  scene.context.beginPath()
  let x = scene.time/endTime * unit
  scene.context.circle(x, 5, 5)
  scene.context.rect(x, 5, 2, trackHeight * numberOfTracks.float)
  scene.context.closePath()
  scene.context.fill()

  scene.context.restore()


proc draw*(scene: Scene) =
  glViewport(0, 0, scene.frameBufferWidth, scene.frameBufferHeight)
  scene.context.beginFrame(scene.width.cfloat, scene.height.cfloat, scene.pixelRatio)

  scene.context.save()
  scene.scaleToUnit()
  scene.background(scene)

  for entity in scene.entities:
    var intermediate = entity.deepCopy()

    # TODO: Decide what to do with entity.children here...
    # Apply the scene's projection matrix to every point of every entity
    intermediate.points = sequtils.map(intermediate.points,
                                       proc(point: Vec3[float]): Vec3[float] =
                                         point.project(scene.projectionMatrix))

    scene.draw(intermediate)

  scene.foreground(scene)

  scene.context.restore()
  scene.visualizeTracks()

  scene.context.endFrame()


proc tick(scene: Scene) =
  var (windowWidth, windowHeight) = scene.window.size

  scene.width = windowWidth
  scene.height = windowHeight

  var (frameBufferWidth, frameBufferHeight) = scene.window.framebufferSize

  scene.frameBufferHeight = frameBufferHeight
  scene.frameBufferWidth = frameBufferWidth
  scene.pixelRatio = 1

  scene.done = true

  for track in scene.tweenTracks.values:
    track.evaluate(scene.time)
    if not track.done:
      scene.done = false

  scene.draw()

  scene.lastTickTime = cpuTime() * 1000


proc update*(scene: Scene) =
  let time = cpuTime() * 1000.0

  # Try to adhere to a max 120 fps
  let goalDelta = 1000.0/120.0

  if time - scene.lastTickTime >= goalDelta:
    scene.deltaTime = time - scene.lastTickTime
    scene.time = scene.time + scene.deltaTime
    scene.tick()

    if scene.done:
      scene.time = scene.restartTime


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


proc runLiveRenderingLoop(scene: Scene) =
  # TODO: Make scene.update loop be on a separate thread. That would allow rendering even while user is dragging/resizing window...
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
      error msg
      scene.done = true

    if scene.done:
      scene.window.shouldClose = true

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


