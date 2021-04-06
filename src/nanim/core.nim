
import
  glm,
  glfw,
  tables,
  nanovg,
  sequtils,
  os,
  math,
  times,
  nanim/animation,
  nanim/drawing,
  nanim/logging


type
  AngleMode* = enum
    amDegrees, amRadians

  StyleMode* = enum
    smSolidColor, smPaintPattern, smNone

  Style* = ref tuple
    fillMode: StyleMode
    fillColor: Color
    fillPattern: proc(context: NVGContext): Paint

    strokeMode: StyleMode
    strokeColor: Color
    strokePattern: proc(context: NVGContext): Paint
    strokeWidth: float

    winding: PathWinding
    lineCap: LineCapJoin
    lineJoin: LineCapJoin
    compositeOperation: CompositeOperation

  Entity* = ref object of RootObj
    points*: seq[Vec3[float]]

    tension*: float
    cornerRadius*: float
    style*: Style

    position*: Vec3[float]
    rotation*: float
    scaling*: Vec3[float]

    children*: seq[Entity]

  Scene* = ref object of RootObj
    window*: Window
    context*: NVGContext

    width*: int
    height*: int

    background*: proc(scene: Scene)
    foreground*: proc(scene: Scene)

    time*: float
    restartTime*: float
    lastTickTime*: float
    deltaTime*: float

    frameBufferWidth*: int32
    frameBufferHeight*: int32

    currentTweenTrackId*: int
    tweenTracks*: Table[int, TweenTrack]

    entities*: seq[Entity]
    projectionMatrix*: Mat4x4[float]

    pixelRatio*: float

    done*: bool


const
  defaultTrackId* = 0
  defaultAngleMode*: AngleMode = amDegrees


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


func newStyle*(): Style =
  new(result)
  result.fillMode = smPaintPattern
  result.fillColor = rgb(255, 56, 116)
  result.fillPattern = defaultPattern

  result.strokeMode = smSolidColor
  result.strokeColor = rgb(230, 26, 94)
  result.strokePattern = defaultPattern
  result.strokeWidth = 2.0

  result.winding = pwCCW
  result.lineCap = lcjRound
  result.lineJoin = lcjMiter
  result.compositeOperation = coSourceOver


proc setStyle*(context: NVGContext, style: Style) =
  case style.fillMode:
  of smSolidColor:
    context.fillColor(style.fillColor)
  of smPaintPattern:
    context.fillPaint(style.fillPattern(context))
  of smNone: discard

  context.strokeWidth(style.strokeWidth)
  case style.strokeMode:
  of smSolidColor:
    context.strokeColor(style.strokeColor)
  of smPaintPattern:
    context.strokePaint(style.strokePattern(context))
  of smNone: context.strokeWidth(0.0)

  context.pathWinding(style.winding)
  context.lineJoin(style.lineJoin)
  context.lineCap(style.lineCap)
  context.globalCompositeOperation(style.compositeOperation)


proc executeStyle*(context: NVGContext, style: Style) =
  case style.fillMode:
  of smSolidColor, smPaintPattern:
    context.fill()
  of smNone: discard

  case style.strokeMode:
  of smSolidColor, smPaintPattern:
    context.stroke()
  of smNone: discard


proc applyStyle*(context: NVGContext, style: Style) =
  context.setStyle(style)
  context.executeStyle(style)


method draw*(entity: Entity, scene: Scene) {.base.} =
  let context = scene.context
  context.beginPath()
  if entity.tension > 0:
    context.drawPointsWithTension(entity.points, entity.tension)
  else:
    context.drawPointsWithRoundedCornerRadius(entity.points, entity.cornerRadius)
  context.closePath()

  context.applyStyle(entity.style)


func init*(entity: Entity) =
  entity.points = @[]
  entity.children = @[]
  entity.tension = 0.0
  entity.cornerRadius = 20.0
  entity.style = newStyle()
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec3(1.0, 1.0, 1.0)


func newEntity*(points: seq[Vec3[float]]): Entity =
  new(result)
  result.init()
  result.points = points


proc add*(entity: Entity, child: Entity) =
  entity.children.add(child)


func show*(entity: Entity): Tween =
  var interpolators: seq[proc(t: float)]
  let delta = vec3(10.0, 0.0, 0.0)

  let
    startValue = entity.position.deepCopy() - delta
    endValue = entity.position.deepCopy()

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators)


func move*(entity: Entity,
           dx: float = 0.0,
           dy: float = 0.0,
           dz: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]
  let delta = vec3(dx, dy, dz)

  let
    startValue = entity.position.deepCopy()
    endValue = startValue + delta

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators)


func moveTo*(entity: Entity,
           dx: float = 0.0,
           dy: float = 0.0,
           dz: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.position.deepCopy()
    endValue = vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators)


func stretch*(entity: Entity,
              dx: float = 1.0,
              dy: float = 1.0,
              dz: float = 1.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = startValue * vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators)


func stretchTo*(entity: Entity,
              dx: float = 1.0,
              dy: float = 1.0,
              dz: float = 1.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators)


func scale*(entity: Entity, d: float = 1.0): Tween =
  return entity.stretch(d, d, d)


func scaleTo*(entity: Entity, d: float = 1.0): Tween =
  return entity.stretchTo(d, d, d)


proc pstretch*(entity: Entity, dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween =

  var interpolators: seq[proc(t: float)]

  for entity in entity.children:
    interpolators &= entity.pstretch(dx, dy, dz).interpolators

  let
    startValue = entity.points.deepCopy()
    endValue = entity.points.map(proc(point: Vec3[float]): Vec3[float] = vec3(point.x * dx, point.y * dy, point.z * dz))

    startCornerRadius = entity.cornerRadius.deepCopy()
    endCornerRadius: float = startCornerRadius * max(dz, max(dx, dy))

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startCornerRadius, endCornerRadius, t)
    entity.points = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.points = endValue
  entity.cornerRadius = endCornerRadius

  result = newTween(interpolators)


proc pstretch*(entities: varargs[Entity], dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween =
  var interpolators: seq[proc(t: float)]

  for entity in entities:
    interpolators &= entity.pstretch(dx, dy, dz).interpolators

  result = newTween(interpolators)


proc pscale*(entities: openArray[Entity], d: float = 1.0): Tween =
  return entities.pstretch(d, d, d)


proc pscale*(entity: Entity, d: float = 1.0): Tween =
  return entity.pstretch(d, d, d)


func rotate*(entity: Entity, dangle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween =
  var interpolators: seq[proc(t: float)]

  let
    angle =
      case mode:
      of amDegrees: math.degToRad(dangle)
      of amRadians: dangle
    startValue = entity.rotation.deepCopy()
    endValue = startValue + angle

  let interpolator = proc(t: float) =
    entity.rotation = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.rotation = endValue

  result = newTween(interpolators)


func rotateTo*(entity: Entity, dangle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween =
  var interpolators: seq[proc(t: float)]

  let
    angle =
      case mode:
      of amDegrees: math.degToRad(dangle)
      of amRadians: dangle
    startValue = entity.rotation.deepCopy()
    endValue = angle

  let interpolator = proc(t: float) =
    entity.rotation = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.rotation = endValue

  result = newTween(interpolators)


proc setTension*(entity: Entity, tension: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.tension.deepCopy()
    endValue = tension

  let interpolator = proc(t: float) =
    entity.tension = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.tension = endValue

  result = newTween(interpolators)


proc setCornerRadius*(entity: Entity, cornerRadius: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.cornerRadius.deepCopy()
    endValue = cornerRadius

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.cornerRadius = endValue

  result = newTween(interpolators)


proc fill*(context: NVGContext, width: cfloat, height: cfloat, color: Color = rgb(255, 255, 255)) =
  context.save()
  context.fillColor(color)
  context.beginPath()
  context.resetTransform()
  context.rect(0, 0, width, height)
  context.closePath()
  context.fill()
  context.restore()


proc init(scene: Scene) =
  scene.time = 0.0
  scene.restartTime = 0.0
  scene.lastTickTime = 0.0
  scene.tweenTracks = initTable[int, TweenTrack]()
  scene.currentTweenTrackId = defaultTrackId

  scene.tweenTracks[scene.currentTweenTrackId] = newTweenTrack()
  scene.projectionMatrix = mat4x4[float](vec4[float](1,0,0,0),
                                          vec4[float](0,1,0,0),
                                          vec4[float](0,0,1,0),
                                          vec4[float](0,0,0,1))
  scene.done = false

  scene.background =
    proc(scene: Scene) =
      scene.context.fill(scene.width.cfloat, scene.height.cfloat, rgb(255, 255, 255))

  scene.foreground = proc(scene: Scene) = discard


proc newScene*(): Scene =
  new(result)
  result.init()


proc loadFonts*(context: NVGContext) =
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


proc pscale*(scene: Scene, d: float = 0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.scale(vec3(d,d,d))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators)


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

  result = newTween(interpolators)


proc pmove*(scene: Scene, dx: float = 0, dy: float = 0, dz: float = 0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.translate(vec3(dx, dy, dz))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators)


func getLatestTween*(scene: Scene): Tween =
  discard scene.tweenTracks.hasKeyOrPut(scene.currentTweenTrackId, newTweenTrack())
  return scene.tweenTracks[scene.currentTweenTrackId].getLatestTween()


proc add*(scene: Scene, entities: varargs[Entity]) =
  scene.entities.add(entities)


proc switchTrack*(scene: Scene, newTrackId: int = defaultTrackId) =
  scene.currentTweenTrackId = newTrackId
  discard scene.tweenTracks.hasKeyOrPut(newTrackId, newTweenTrack())


template onTrack*(scene: Scene, trackId: int = defaultTrackId, body: untyped): untyped =
  let oldTrackId = scene.currentTweenTrackId
  scene.switchTrack(trackId)

  body

  scene.switchTrack(oldTrackId)


proc switchToDefaultTrack*(scene: Scene) =
  scene.switchTrack(defaultTrackId)


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


proc show*(scene: Scene, entity: Entity) =
  scene.play(entity.show())


proc showAllEntities*(scene: Scene) =
  var tweens: seq[Tween]

  for entity in scene.entities:
    tweens.add(entity.show())

  scene.play(tweens)


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

  entity.draw(scene)

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
  scene.context.save()
  scene.scaleToUnit()
  scene.background(scene)

  for entity in scene.entities:
    var intermediate = entity.deepCopy()

    # TODO: Decide what to do with projection of entity.children here...
    # Apply the scene's projection matrix to every point of every entity
    intermediate.points = sequtils.map(intermediate.points,
                                       proc(point: Vec3[float]): Vec3[float] =
                                         point.project(scene.projectionMatrix))

    scene.draw(intermediate)

  scene.foreground(scene)

  scene.context.restore()
  scene.visualizeTracks()


proc tick*(scene: Scene, deltaTime: float = 1000.0/120.0) =
  scene.deltaTime = deltaTime
  scene.time += scene.deltaTime

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
    scene.tick(time - scene.lastTickTime)

    if scene.done:
      scene.time = scene.restartTime
