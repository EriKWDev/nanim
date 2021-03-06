
import
  glm,
  hashes,
  strformat,
  staticglfw,
  tables,
  nanovg,
  sequtils,
  algorithm,
  os,
  math,
  times,
  random,
  opengl,
  nanim/animation/tween,
  nanim/animation/easings,
  nanim/logging


type
  AngleMode* = enum
    amDegrees, amRadians

  StyleMode* = enum
    smSolidColor, smPaintPattern, smBlend, smNone

  Style* = ref tuple
    fillMode: StyleMode
    fillColor: Color
    fillPattern: proc(scene: Scene): Paint
    fillColorToPatternBlend: float

    strokeMode: StyleMode
    strokeColor: Color
    strokePattern: proc(scene: Scene): Paint
    strokeWidth: float
    strokeColorToPatternBlend: float

    winding: PathWinding
    lineCap: LineCapJoin
    lineJoin: LineCapJoin
    compositeOperation: CompositeOperation
    opacity: float

  Entity* = ref object of RootObj
    closed*: bool
    points*: seq[Vec3[float]]

    tension*: float
    cornerRadius*: float
    style*: Style

    position*: Vec3[float]
    rotation*: float
    scaling*: Vec3[float]

    children*: seq[Entity]

  PEntity* = ref object of Entity
    image*: Paint

  VEntity* = ref object of Entity

  Scene* = ref object of RootObj
    window*: Window
    context*: NVGContext

    width*: int
    height*: int

    background*: proc(scene: Scene)
    foreground*: proc(scene: Scene)

    fontsToLoad*: seq[tuple[name, path: string]]

    time*: float
    restartTime*: float
    lastTickTime*: float
    deltaTime*: float
    goalFPS*: float

    frameBufferWidth*: int32
    frameBufferHeight*: int32

    currentTweenTrackId*: int
    tweenTracks*: OrderedTable[int, TweenTrack]

    entities*: seq[Entity]
    projectionMatrix*: Mat4x4[float]

    pixelRatio*: float

    done*: bool
    debug*: bool


const
  pointsPerCurve* = 3
  toleranceForPointEquality* = 1e-8
  toleranceForPointEqualitySquared* = toleranceForPointEquality*toleranceForPointEquality


func getReflectionOfLastHandle*(ventity: VEntity): Vec3[float] {.inline.} =
  return 2.0 * ventity.points[^1] - ventity.points[^2]

proc startNewPath*(ventity: VEntity, point: Vec3[float]) =
  # doAssert(len(ventity.points) mod pointsPerCurve == 0)
  ventity.points.add(point)

func hasNewPathStarted*(ventity: VEntity): bool {.inline.} =
  return len(ventity.points) mod pointsPerCurve == 1

func arePointsConsideredEqual*(points: varargs[Vec3[float]]): bool =
  if len(points) < 1: return true

  for point in points[1..^1]:
    if length(point - points[0]) > toleranceForPointEquality:
      return false

  return true

proc isPathClosed*(ventity: VEntity): bool {.inline.} =
  return arePointsConsideredEqual(ventity.points[0], ventity.points[^1])

proc addLineTo*(ventity: VEntity, point: Vec3[float]) =
  let lastPoint = ventity.points[^1]

  for i in 1..pointsPerCurve:
    let t = interpolate(0.0, 1.0, i.float/pointsPerCurve.float)
    ventity.points.add(interpolate(lastPoint, point, t))

proc closePath*(ventity: VEntity) =
  ventity.closed = true

proc addCubicBezierCurve*(ventity: VEntity, anchor1: Vec3[float], handle1: Vec3[float], handle2: Vec3[float], anchor2: Vec3[float]) {.inline.} =
  ventity.points.add([anchor1, handle1, handle2, anchor2])

proc addCubicBezierCurveTo*(ventity: VEntity, handle1: Vec3[float], handle2: Vec3[float], anchor: Vec3[float]) {.inline.} =
    ventity.points.add([handle1, handle2, anchor])

proc addSmoothBezierCurveTo*(ventity: VEntity, handle2: Vec3[float], anchor: Vec3[float]) {.inline.} =
  ventity.points.add([ventity.getReflectionOfLastHandle(), handle2, anchor])

proc addQuadraticBezierCurveTo*(ventity: VEntity, handle: Vec3[float], anchor: Vec3[float]) {.inline.} =
  ventity.points.add([ventity.points[^1], handle, anchor])

proc addShortQuadraticCurveTo*(ventity: VEntity, anchor: Vec3[float]) {.inline.} =
  ventity.addQuadraticBezierCurveTo(ventity.getReflectionOfLastHandle(), anchor)

proc addSmoothCurveTo*(ventity: Ventity, point: Vec3[float]) =
  if ventity.hasNewPathStarted():
    ventity.addLineTo(point)
  else:
    let handle = ventity.getReflectionOfLastHandle()
    ventity.addQuadraticBezierCurveTo(handle, point)

proc addSmoothCubicCurveTo*(ventity: VEntity, handle: Vec3[float], point: Vec3[float]) {.inline.} =
  ventity.points.add([ventity.getReflectionOfLastHandle(), handle, point])


func vecMag(x, y: float): float {.inline.} =
  return sqrt(x*x + y*y)


func vecRat(ux, uy, vx, vy: float): float {.inline.} =
  return (ux*vx + uy*vy) / (vecMag(ux,uy) * vecMag(vx,vy))


func vecAng(ux, uy, vx, vy: float): float =
  var r = vecRat(ux,uy, vx,vy)

  if r < -1:
    r = -1.0
  if r > 1:
    r = 1.0

  return (if (ux*vy < uy*vx): -1.0 else: 1.0) * arccos(r)


func xformPoint(x, y: float, t: array[6, float]): tuple[dx, dy: float] {.inline.} =
  return (x*t[0] + y*t[2] + t[4], x*t[1] + y*t[3] + t[5])

func xformVec(x, y: float, t: array[6, float]): tuple[dx, dy: float] {.inline.} =
  return (x*t[0] + y*t[2], x*t[1] + y*t[3])


proc addArcTo*(ventity: VEntity,
               radiusX: float,
               radiusY: float,
               xAxisRotation: float,
               largeArcFlag: float,
               sweepFlag: float,
               endPoint: Vec3[float]) =

  let
    startPoint = ventity.points[^1]
    delta = startPoint - endPoint
    dist = length(delta)

  var
    rx = abs(radiusX)
    ry = abs(radiusY)

  if dist < 1e-6 or rx < 1e-6 or ry < 1e-6:
    # The arc degenerates to a line
    ventity.addLineTo(endPoint)
    return

  let
    rotationX = degToRad(xAxisRotation)
    drawLargeArc = abs(largeArcFlag) > 1e-6
    sweepClockwise = abs(sweepFlag) > 1e-6
    sinrx = sin(rotationX)
    cosrx = cos(rotationX)

  # Convert to center point parameterization.
  # http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
  # 1) Compute x1', y1'
  let
    x1p = cosrx * delta.x / 2.0 + sinrx * delta.y / 2.0
    y1p = -sinrx * delta.x / 2.0 + cosrx * delta.y / 2.0
    rxSquared = rx*rx
    rySquared = ry*ry
    x1pSquared = x1p*x1p
    y1pSquared = y1p*y1p

  var d = (x1p*x1p)/(rxSquared) + (y1p*y1p)/(rySquared)

  if (d > 1):
    d = sqrt(d)
    rx *= d
    ry *= d

  # 2) Compute cx', cy'
  var
    s = 0.0
    sa = rxSquared*rySquared - rxSquared*y1pSquared - rySquared*x1pSquared
    sb = rxSquared*y1pSquared + rySquared*x1pSquared

  if sa < 0:
    sa = 0

  if sb > 0:
    s = sqrt(sa / sb)

  if drawLargeArc == sweepClockwise:
    s = -s

  let
    cxp = s * rx * y1p / ry
    cyp = s * -ry * x1p / rx

  # 3) Compute cx,cy from cx',cy'
  let
    cx = (startPoint.x + endPoint.x)/2.0 + cosrx*cxp - sinrx*cyp
    cy = (startPoint.y + endPoint.y)/2.0 + sinrx*cxp + cosrx*cyp

  # 4) Calculate theta1, and delta theta.
  let
    ux = (x1p - cxp) / rx
    uy = (y1p - cyp) / ry
    vx = (-x1p - cxp) / rx
    vy = (-y1p - cyp) / ry
    a1 = vecAng(1.0, 0.0, ux, uy)  # Initial angle

  var da = vecAng(ux, uy, vx, vy)    # Delta angle

  # if (vecRat(ux,uy,vx,vy) <= -1.0f) da = NSVG_PI;
  # if (vecRat(ux,uy,vx,vy) >= 1.0f) da = 0;

  if sweepClockwise == false and da > 0:
    da -= 2 * PI;
  elif sweepClockwise == true and da < 0:
    da += 2 * PI;

  # Approximate the arc using cubic spline segments.
  var t: array[6, float]

  t[0] = cosrx
  t[1] = sinrx
  t[2] = -sinrx
  t[3] = cosrx
  t[4] = cx
  t[5] = cy

  # Split arc into max 90 degree segments.
  # The loop assumes an iteration per end point (including start and end), this +1.
  let
    ndivsf = (abs(da) / (PI*0.5) + 1.0)
    ndivs = ndivsf.int
  var hda = (da / ndivsf) / 2.0

  # Fix for ticket #179: division by 0: avoid cotangens around 0 (infinite)
  if hda < 1e-3 and hda > -1e-3:
    hda *= 0.5
  else:
    hda = (1.0f - cos(hda)) / sin(hda)

  var kappa = abs(4.0 / 3.0 * hda)

  if da < 0.0:
    kappa = -kappa;

  var
    x: float
    y: float
    tanx: float
    tany: float
    px: float
    py: float
    ptanx: float
    ptany: float

  for i in 0..ndivs:
    let
      a = a1 + da * (i.float/ndivsf)
      dx = cos(a)
      dy = sin(a)

    (x, y) = xformPoint(dx*rx, dy*ry, t)

    (tanx, tany) = xformVec(-dy*rx * kappa, dx*ry * kappa, t) # tangent

    if i > 0:
      ventity.addCubicBezierCurveTo(vec3(px + ptanx, py + ptany, 0.0), vec3(x - tanx, y - tany, 0.0), vec3(x, y, 0.0))

    px = x
    py = y
    ptanx = tanx
    ptany = tany


const
  defaultTrackId* = 0
  defaultAngleMode*: AngleMode = amDegrees


func parseAngleToRad*(angle: float = 0.0, mode: AngleMode = defaultAngleMode): float =
  result = case mode:
    of amDegrees: math.degToRad(angle)
    of amRadians: angle


func parseAngleToDeg*(angle: float = 0.0, mode: AngleMode = defaultAngleMode): float =
  result = case mode:
    of amDegrees: angle
    of amRadians: math.radToDeg(angle)


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


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


proc unScaleFromUnit*(scene: Scene, fraction: float = 1000f, compensate: bool = true) =
  let n = min(scene.width, scene.height).float
  let d = max(scene.width, scene.height).float

  let unit = n / fraction
  scene.context.scale(1/unit, 1/unit)

  if compensate:
    let compensation = (d - n)/2f
    if scene.width > scene.height:
      scene.context.translate(-compensation, 0f)
    else:
      scene.context.translate(0f, -compensation)


proc clearWithColor*(color: Color = rgba(0, 0, 0, 0)) =
  glClearColor(color.r, color.g, color.b, color.a)
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT or
          GL_STENCIL_BUFFER_BIT)

{.push checks: off, optimization: speed.}
proc drawPoints*(context: NVGContext, points: seq[Vec]) =
  if len(points) < 2: return

  context.moveTo(points[0].x, points[0].y)

  for i in 1..high(points):
    let point = points[i]
    context.lineTo(point.x, point.y)


proc drawPointsWithTension*(context: NVGContext, points: seq[Vec], tension: float = 0.5) =
  if len(points) < 2: return

  context.moveTo(points[0].x, points[0].y)

  let controlScale = tension / 0.5 * 0.175
  let numberOfPoints = len(points)

  for i in 0..high(points):
    let points_before = points[(i - 1 + numberOfPoints) mod numberOfPoints]
    let point = points[i]

    let pointAfter = points[(i + 1) mod numberOfPoints]
    let pointAfter2 = points[(i + 2) mod numberOfPoints]

    let p4 = pointAfter

    let di = vec2(pointAfter.x - points_before.x, pointAfter.y - points_before.y)
    let p2 = vec2(point.x + controlScale * di.x, point.y + controlScale * di.y)

    let diPlus1 = vec2(pointAfter2.x - points[i].x, pointAfter2.y - points[i].y)

    let p3 = vec2(pointAfter.x - controlScale * diPlus1.x, pointAfter.y - controlScale * diPlus1.y)

    context.bezierTo(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)


proc drawPointsWithRoundedCornerRadius*(context: NVGContext, points: seq[Vec], cornerRadius: float = 20) =
    if len(points) < 2: return

    var p1 = points[0]

    let lastPoint = points[^1]
    let midPoint = vec2((p1.x + lastPoint.x) / 2.0, (p1.y + lastPoint.y) / 2.0)

    context.moveTo(midPoint.x, midPoint.y)
    for i in 1..high(points):
      let p2 = points[i]

      context.arcTo(p1.x, p1.y, p2.x, p2.y, cornerRadius)
      p1 = p2

    context.arcTo(p1.x, p1.y, midPoint.x, midPoint.y, cornerRadius)
{.pop.}

var
  defaultPatternColor1* = rgb(60, 60, 60)
  defaultPatternColor2* = rgb(20, 20, 20)


proc defaultPatternDrawer*(scene: Scene, width: float, height: float) =
  let context = scene.context

  context.beginPath()
  context.rect(0, 0, width, height)
  context.closePath()

  context.fillColor(defaultPatternColor2)
  context.fill()

  context.beginPath()
  context.circle(width/2, width/2, width/2.2)
  context.closePath()

  context.fillColor(defaultPatternColor1)
  context.fill()

proc stripedPatternDrawer*(scene: Scene, width: float, height: float) =
  let context = scene.context

  context.beginPath()
  context.rect(0, 0, width, height)
  context.closePath()

  context.fillColor(defaultPatternColor2)
  context.fill()

  let
    N = 20
    d = height/N.float

  context.beginPath()
  for i in 0..N:
    context.moveTo(-width, i.float * d)
    context.lineTo(width*2, i.float * d)
  context.closePath()

  context.strokeColor(defaultPatternColor1)
  context.strokeWidth(5)
  context.stroke()


proc offset(some: pointer; b: int): pointer {.inline.} =
  result = cast[pointer](cast[int](some) + b)

var patternCache = initTable[proc(scene: Scene, width: float, height: float): void, seq[Paint]]()

proc gridPattern*(scene: Scene,
                  patternDrawer: proc(scene: Scene, width: float, height: float) = defaultPatternDrawer,
                  width: cint = 10,
                  height: cint = 10,
                  cache: bool = true,
                  numberOfCaches: int = 1): Paint =

  # Impure, but worth it for the performance benefit...
  if cache == true and
    patternCache.hasKey(patternDrawer) and
    patternCache[patternDrawer].len >= numberOfCaches:

    return patternCache[patternDrawer][rand(0..high(patternCache[patternDrawer]))]

  let
    bufferSize = width * height * 4
    tempContext = nvgCreateContext({nifStencilStrokes, nifDebug})

  var imageData = alloc0(bufferSize)

  # clear the region
  glDrawPixels(width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)

  # draw the pattern
  let (frameBufferWidth, frameBufferHeight) = (scene.frameBufferWidth, scene.frameBufferHeight)

  tempContext.beginFrame(frameBufferWidth.cfloat, frameBufferHeight.cfloat, 1)
  clearWithColor()
  tempContext.translate(0, frameBufferHeight.float - height.float)
  let tempScene = scene.deepCopy()
  tempScene.context = tempContext
  patternDrawer(tempScene, width.float, height.float)
  tempContext.endFrame()

  # read the region
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)

  var pixels = newSeq[uint8](bufferSize)

  # Flip the image
  for y in 0..<height:
    let
      lineSize = width * 4
      yDest = y * lineSize
      ySrc = bufferSize - yDest - lineSize
    copyMem(pixels[yDest].unsafeAddr, imageData.offset(ySrc), lineSize)

  # create an image from pixels
  let image = scene.context.createImageRGBA(width, height, {ifRepeatX, ifRepeatY, ifFlipY}, pixels)

  # create and cache a pattern from the image
  let patternPaint = scene.context.imagePattern(0, 0, width.cfloat, height.cfloat, 0, image, 1.0)
  if cache:
    var cacheSeq = patternCache.mgetOrPut(patternDrawer, @[])
    cacheSeq.add(patternPaint)
    patternCache[patternDrawer] = cacheSeq

  # return the pattern
  result = patternPaint

  dealloc(imageData)


proc randomColor*(greyScale: bool = false): Color =
  if greyScale:
    let v = rand(0..255)
    return rgb(v, v, v)
  else:
    let
      r = rand(0..255)
      g = rand(0..255)
      b = rand(0..255)

    return rgb(r, g, b)

proc randomNoiseDrawer*(scene: Scene, width: float, height: float) =
  let
    parts = 40.0 * 5
    pw = width/parts
    ph = width/parts

  var
    x = 0.0
    y = 0.0

  while y < height:
    while x < width:
      scene.context.beginPath()
      scene.context.rect(x, y, pw, ph)
      scene.context.closePath()
      scene.context.fillColor(randomColor(true))
      scene.context.fill()

      x += pw
    y += ph
    x = 0.0

proc randomize*(scene: Scene, seed: int): int {.discardable.} =
  randomize(seed)
  info "Random seed is: " & $seed
  result = seed

proc randomize*(scene: Scene): int {.discardable.} =
  randomize()
  result = rand(0..100000000)
  scene.randomize(result)


proc defaultPattern*(scene: Scene): Paint =
  scene.gridPattern(defaultPatternDrawer, 10, 10)

proc noisePattern*(scene: Scene): Paint =
  scene.gridPattern(randomNoiseDrawer, 500, 500, cache = true, 50)

proc stripedPattern*(scene: Scene): Paint =
  scene.gridPattern(stripedPatternDrawer, 300, 300)

proc gradient*(scene: Scene, c1: Color = rgb(255, 0, 255), c2: Color = rgb(0, 0, 100)): Paint =
  result = scene.context.linearGradient(0, 0, 100, 100, c1, c2)


func newStyle*(fillMode = smSolidColor,
               fillColor = rgb(255, 56, 116),
               fillPattern = defaultPattern,

               strokeMode = smSolidColor,
               strokeColor = rgb(230, 26, 94),
               strokePattern = defaultPattern,
               strokeWidth = 2.0,

               winding = pwCCW,
               lineCap = lcjRound,
               lineJoin = lcjMiter,
               opacity = 1.0,
               compositeOperation = coSourceOver): Style =
  new(result)
  result.fillMode = fillMode
  result.fillColor = fillColor
  result.fillPattern = fillPattern
  result.fillColorToPatternBlend = if fillMode == smSolidColor: 0.0 else: 1.0

  result.strokeMode = strokeMode
  result.strokeColor = strokeColor
  result.strokePattern = strokePattern
  result.strokeWidth = strokeWidth
  result.strokeColorToPatternBlend = if strokeMode == smSolidColor: 0.0 else: 1.0

  result.winding = winding
  result.lineCap = lineCap
  result.lineJoin = lineJoin
  result.opacity = opacity
  result.compositeOperation = compositeOperation

func copyWith*(base: Style,
               fillMode: StyleMode = base.fillMode,
               fillColor: Color = base.fillColor,
               fillPattern = base.fillPattern,
               strokeMode: StyleMode = base.strokeMode,
               strokeColor: Color = base.strokeColor,
               strokePattern = base.strokePattern,
               strokeWidth: float = base.strokeWidth,
               winding = base.winding,
               lineCap = base.lineCap,
               lineJoin = base.lineJoin,
               opacity = base.opacity,
               compositeOperation = base.compositeOperation): Style =
  new(result)
  result.fillMode = fillMode
  result.fillColor = fillColor
  result.fillPattern = fillPattern
  result.fillColorToPatternBlend = if fillMode == smSolidColor: 0.0 else: 1.0

  result.strokeMode = strokeMode
  result.strokeColor = strokeColor
  result.strokePattern = strokePattern
  result.strokeWidth = strokeWidth
  result.strokeColorToPatternBlend = if strokeMode == smSolidColor: 0.0 else: 1.0

  result.winding = winding
  result.lineCap = lineCap
  result.lineJoin = lineJoin
  result.opacity = opacity
  result.compositeOperation = compositeOperation

proc apply*(base: Style, style: Style) =
  base.fillMode = style.fillMode
  base.fillColor = style.fillColor
  base.fillPattern = style.fillPattern
  base.fillColorToPatternBlend = style.fillColorToPatternBlend

  base.strokeMode = style.strokeMode
  base.strokeColor = style.strokeColor
  base.strokePattern = style.strokePattern
  base.strokeWidth = style.strokeWidth
  base.strokeColorToPatternBlend = style.strokeColorToPatternBlend

  base.winding = style.winding
  base.lineCap = style.lineCap
  base.lineJoin = style.lineJoin
  base.opacity = style.opacity
  base.compositeOperation = style.compositeOperation


let
  defaultPaint*: Style = newStyle().copyWith(fillMode=smSolidColor, strokeMode=smNone, strokeWidth=0.0)
  bluePaint*: Style = defaultPaint.copyWith(fillColor=rgb(55, 100, 220), strokeColor=rgb(75, 80, 223), strokeWidth=30.0)
  noisePaint*: Style = defaultPaint.copyWith(fillPattern=noisePattern, fillMode=smPaintPattern)
  gradientPaint*: Style = noisePaint.copyWith(fillPattern = proc(scene: Scene): Paint = gradient(scene))


proc setStyle*(scene: Scene, style: Style) =
  let context = scene.context
  if style.fillMode != smNone:
    if style.fillColorToPatternBlend >= 1.0:
      style.fillMode = smPaintPattern
      if style.fillColor.a == 0:
        style.fillMode = smNone
    elif style.fillColorToPatternBlend <= 0.0:
      style.fillMode = smSolidColor
    else:
      style.fillMode = smBlend

  case style.fillMode:
  of smSolidColor:
    context.fillColor(style.fillColor)
  of smPaintPattern:
    context.fillPaint(style.fillPattern(scene))
  of smBlend:
    context.fillColor(style.fillColor.withAlpha(1.0 - style.fillColorToPatternBlend))
  of smNone: discard
  else: discard

  if style.strokeMode != smNone:
    if style.strokeColorToPatternBlend >= 1.0:
      style.strokeMode = smPaintPattern
    elif style.strokeColorToPatternBlend <= 0.0:
      style.strokeMode = smSolidColor
      if style.strokeColor.a == 0:
        style.strokeMode = smNone
    else:
      style.strokeMode = smBlend

    context.strokeWidth(abs(style.strokeWidth))

  case style.strokeMode:
  of smSolidColor:
    context.strokeColor(style.strokeColor)
  of smPaintPattern:
    context.strokePaint(style.strokePattern(scene))
  of smBlend:
    context.strokeColor(style.strokeColor.withAlpha(1.0 - style.strokeColorToPatternBlend))
  of smNone: context.strokeWidth(0.0)
  else: discard

  context.pathWinding(style.winding)
  context.lineJoin(style.lineJoin)
  context.lineCap(style.lineCap)
  context.globalCompositeOperation(style.compositeOperation)
  context.globalAlpha(style.opacity)

proc executeStyle*(scene: Scene, style: Style, doFill=true, doStroke=true) =
  let context = scene.context

  if doFill:
    case style.fillMode:
    of smSolidColor, smPaintPattern:
      context.fill()
    of smBlend:
      context.fillPaint(style.fillPattern(scene))
      context.fill()
      context.fillColor(style.fillColor.withAlpha(1.0 - style.fillColorToPatternBlend))
      context.fill()
    of smNone: discard
    else: discard

  if doStroke:
    case style.strokeMode:
    of smSolidColor, smPaintPattern:
      context.stroke()
    of smBlend:
      context.fillPaint(style.strokePattern(scene))
      context.stroke()
      context.fillColor(style.strokeColor.withAlpha(1.0 - style.fillColorToPatternBlend))
      context.stroke()
    of smNone: discard
    else: discard

proc applyStyle*(scene: Scene, style: Style, doFill=true, doStroke=true) =
  scene.setStyle(style)
  scene.executeStyle(style, doFill, doStroke)


method draw*(entity: Entity, scene: Scene) {.base.} =
  let context = scene.context

  context.beginPath()

  if entity.tension <= 0 and entity.cornerRadius <= 0:
    context.drawPoints(entity.points)
  elif entity.tension > 0:
    context.drawPointsWithTension(entity.points, entity.tension)
  else:
    context.drawPointsWithRoundedCornerRadius(entity.points, entity.cornerRadius)

  if entity.closed:
    context.closePath()

  scene.applyStyle(entity.style)

{.push checks: off, optimization: speed.}
proc drawCubicBezierPoints*(context: NVGContext, points: seq[Vec3[float]]) =
  context.moveTo(points[0].x, points[0].y)

  for i in countup(1, high(points) - 2, pointsPerCurve):
    let (a, b, c) = (points[i + 0], points[i + 1], points[i + 2])
    context.bezierTo(a.x, a.y, b.x, b.y, c.x, c.y)
{.pop.}

method draw*(entity: VEntity, scene: Scene) =
  let context = scene.context
  context.beginPath()
  context.drawCubicBezierPoints(entity.points)

  if entity.closed:
    context.closePath()

  scene.applyStyle(entity.style)


proc init*(entity: Entity) =
  entity.points = @[]
  entity.closed = true
  entity.children = @[]
  entity.tension = 0.0
  entity.cornerRadius = 20.0
  entity.style = defaultPaint
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec3(1.0, 1.0, 1.0)


proc newEntity*(points: seq[Vec3[float]] = @[]): Entity =
  new(result)
  result.init()
  result.points = points

import re, strutils


type
  EntityExtents* = ref tuple
    width: float
    height: float

    topLeft: Vec3[float]
    topRight: Vec3[float]
    bottomLeft: Vec3[float]
    bottomRight: Vec3[float]

    center: Vec3[float]


func extents*(entity: Entity): EntityExtents =
  new(result)
  result.topLeft = vec3[float](0, 0, 0)
  result.topRight = vec3[float](0, 0, 0)
  result.bottomLeft = vec3[float](0, 0, 0)
  result.bottomRight = vec3[float](0, 0, 0)
  result.center = vec3[float](0, 0, 0)

  for point in entity.points:
    result.center += point

    if point.x > result.bottomRight.x:
      result.bottomRight.x = point.x
      result.topRight.x = point.x

    if point.x < result.bottomLeft.x:
      result.bottomLeft.x = point.x
      result.topLeft.x = point.x

    if point.y > result.bottomLeft.y:
      result.bottomLeft.y = point.y
      result.bottomRight.y = point.y

    if point.y < result.topLeft.y:
      result.topLeft.y = point.y
      result.topRight.y = point.y

  result.center /= len(entity.points).float
  result.width = result.bottomRight.x - result.bottomLeft.x
  result.height = result.bottomLeft.y - result.topLeft.y


let pathPointCache = newTable[string, seq[Vec3[float]]]()


proc add*(entity: Entity, children: varargs[Entity]) =
  entity.children.add(children)

proc flatten*(entity: Entity): seq[Entity] =
  for child in entity.children:
    result &= flatten(child)

  entity.children = @[]
  result.insert(entity, 0)


let
  pathRegex = re("[a-z][^a-z]*", {reIgnoreCase})
  pathIgnoreRegex = re(",")
  pathMinusRegex = re("-")
  mmRegex = re("mm")

proc newVEntityFromPathString*(path: string): VEntity =
  new(result)
  init(result.Entity)
  result.closed = path.toUpperAscii().contains("Z")

  if pathPointCache.hasKey(path):
    result.points = pathPointCache[path].deepCopy()
    return

  let cleanPath = path.replace(pathIgnoreRegex, " ").replace(pathMinusRegex, " -")

  var
    relativePoint = vec3(0.0, 0.0, 0.0)
    stop = false
    commandStrings = cleanPath.findAll(pathRegex)

  for i in 0..high(commandStrings):
    if stop:
      break

    let
      commandString = commandStrings[i]
      command = commandString[0]
      commandUpper = command.toUpperAscii()
      argString = commandString[1..^1].strip().splitWhitespace()
      isRelative = command.isLowerAscii()

    var args: seq[float]

    for arg in argString:
      args.add(arg.parseFloat())

    case commandUpper:
      of 'M': # Move
        # info "M: Move " & $args
        let point = vec3(args[0], args[1], 0.0)

        if isRelative:
          relativePoint += point
        else:
          relativePoint = point


        if len(result.points) > 0:
          # stop = true
          let
            rest = commandStrings[i..^1].join("")
            child = newVEntityFromPathString(rest)

          child.style = result.style

          for i in 0..high(child.points):
            child.points[i] -= relativePoint/2

          result.add(child)
          break


        result.startNewPath(relativePoint)

      of 'L': # Lines
        # info command & ": Line " & $args
        let point = vec3(args[0], args[1], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addLineTo(relativePoint)

      of 'H': # Horizontal Lines
        # info command & ": Horizontal Line " & $args
        let point = vec3(args[0], result.points[^1].y, result.points[^1].z)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addLineTo(relativePoint)

      of 'V': # Vertical Lines
        # info command & ": Vertical Line " & $args
        let point = vec3(result.points[^1].x, args[0], result.points[^1].z)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addLineTo(relativePoint)

      of 'C': # Bezier
        # info command & ": Cubic Bezier Curve " & $args
        let point = vec3(args[4], args[5], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addCubicBezierCurveTo(vec3(args[0], args[1], 0.0), vec3(args[2], args[3], 0.0), relativePoint)

      of 'S': # Smooth
        # info command & ": Smooth Bezier Curve " & $args
        let point = vec3(args[2], args[3], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addSmoothBezierCurveTo(vec3(args[0], args[1], 0.0), relativePoint)

      of 'Q': # Quad
        # info command & ": Quadratic Curve " & $args
        let point = vec3(args[2], args[3], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addQuadraticBezierCurveTo(vec3(args[0], args[1], 0.0), relativePoint)

      of 'T': # Short Quad
        # info command & ": Short Quadratic Curve " & $args
        let point = vec3(args[0], args[1], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addShortQuadraticCurveTo(relativePoint)

      of 'A': # Arc
        # info command & ": Arc " & $args
        let point = vec3(args[5], args[6], 0.0)
        if isRelative:
          relativePoint += point
        else:
          relativePoint = point

        result.addArcTo(args[0], args[1], args[2], args[3], args[4], relativePoint)

      of 'Z': # Close path
        # info command & ": End "
        result.closePath()

      else:
        warn command & ": Not Supported Yet"

  let e = extents(result)

  for i in 0..high(result.points):
    result.points[i] += vec3(-e.width/2, -e.height/2, 0.0)

  pathPointCache[path] = result.points.deepCopy()


proc fill*(context: NVGContext, width: cfloat, height: cfloat, color: Color = rgb(255, 255, 255)) =
  context.fillColor(color)
  context.beginPath()
  context.rect(0, 0, width, height)
  context.closePath()
  context.fill()

proc fill*(scene: Scene, color: Color = rgb(255, 255, 255)) =
  scene.context.save()
  scene.unScaleFromUnit()
  scene.context.fillColor(color)
  scene.context.beginPath()
  scene.context.rect(0, 0, scene.width.float, scene.height.float)
  scene.context.closePath()
  scene.context.fill()
  scene.context.restore()

proc setBackgroundColor*(scene: Scene, color: Color = rgb(255, 255, 255)) =
  scene.background = proc(scene: Scene) = scene.fill(color)


var numberOfFontsLoaded* = 0
proc loadFont*(context: NVGContext, name: string, path: string) =
  info "Loading font '", path, "' (" & name & ")"
  let font = context.createFont(name, path)
  doAssert not (font == NoFont)
  inc numberOfFontsLoaded

proc loadFont*(scene: Scene, name: string, path: string) {.inline.} =
  scene.fontsToLoad.add((name, path))

proc loadFonts*(context: NVGContext, fonts: seq[tuple[name, path: string]]) =
  for (name, path) in fonts:
    context.loadFont(name, path)

proc loadDefaultFonts*(scene: Scene) {.inline.} =
  let fontFolderPath = os.joinPath(os.getAppDir(), "fonts")

  var fonts: seq[tuple[name, path: string]]

  for (kind, path) in fontFolderPath.walkDir():
    let (_, name, ext) = path.splitFile()
    case ext
    of ".ttf":
      fonts.add((name.toLowerAscii(), path))
    else:
      discard

  scene.fontsToLoad.add(fonts)

proc loadFonts*(scene: Scene) {.inline.} =
  scene.context.loadFonts(scene.fontsToLoad)


proc init(scene: Scene) =
  scene.time = 0.0
  scene.restartTime = 0.0
  scene.lastTickTime = 0.0
  scene.tweenTracks = initOrderedTable[int, TweenTrack]()
  scene.currentTweenTrackId = defaultTrackId
  scene.width = 1200
  scene.height = 900
  scene.goalFPS = 60.0

  scene.tweenTracks[scene.currentTweenTrackId] = newTweenTrack()
  scene.projectionMatrix = mat4x4[float](vec4[float](1,0,0,0),
                                         vec4[float](0,1,0,0),
                                         vec4[float](0,0,1,0),
                                         vec4[float](0,0,0,1))
  scene.done = false
  scene.debug = true

  scene.background = proc(scene: Scene) = scene.fill(rgb(10, 10, 10))
  scene.foreground = proc(scene: Scene) = discard
  scene.loadDefaultFonts()

proc newScene*(): Scene =
  new(result)
  result.init()

func getLatestTween*(scene: Scene): Tween =
  discard scene.tweenTracks.hasKeyOrPut(scene.currentTweenTrackId, newTweenTrack())
  return scene.tweenTracks[scene.currentTweenTrackId].getLatestTween()


proc add*(scene: Scene, entities: varargs[Entity]) =
  scene.entities.add(entities)


proc switchTrack*(scene: Scene, newTrackId: int = defaultTrackId) =
  scene.currentTweenTrackId = newTrackId
  discard scene.tweenTracks.hasKeyOrPut(newTrackId, newTweenTrack())

template onTrack*(scene: Scene, trackId: int = defaultTrackId, body: untyped): untyped =
  block:
    let oldTrackId = scene.currentTweenTrackId
    scene.switchTrack(trackId)
    body
    scene.switchTrack(oldTrackId)

template ignoreTrack*(scene: Scene, trackId: int = defaultTrackId, body: untyped): untyped =
  when defined(release):
    scene.onTrack(trackId, body)
  else:
    discard

proc switchToDefaultTrack*(scene: Scene) =
  scene.switchTrack(defaultTrackId)


proc getPreviousEndTime*(scene: Scene): float =
  try:
    let previousTween = scene.getLatestTween()
    result = previousTween.startTime + previousTween.duration
  except IndexDefect:
    result = 0.0


proc addTweens*(scene: Scene, tweens: varargs[Tween]) =
  discard scene.tweenTracks.hasKeyOrPut(scene.currentTweenTrackId, newTweenTrack())
  scene.tweenTracks[scene.currentTweenTrackId].add(tweens)


proc animate*(scene: Scene, tweens: varargs[Tween]) =
  let
    previousEndtime = scene.getPreviousEndTime()
    sortedTweens = tweens.toSeq().sortedByIt(it.duration)

  for i in 0..high(sortedTweens):
    sortedTweens[i].startTime = previousEndTime

  scene.addTweens(sortedTweens)

proc animate*(scene: Scene, args: varargs[seq[seq[Tween]]]) =
  var tweens: seq[Tween]
  for arg in args:
    for tween in arg:
      tweens.add(tween)
  scene.animate(tweens)

proc play*(scene: Scene, tweens: varargs[Tween]) = scene.animate(tweens)

proc play*(scene: Scene, args: varargs[seq[seq[Tween]]]) = scene.animate(args)

proc stagger*(scene: Scene, staggering: float, tweens: varargs[Tween]) =
  let previousEndtime = scene.getPreviousEndTime()

  for i in 0..high(tweens):
    tweens[i].startTime = previousEndTime + i.float * staggering

  scene.addTweens(tweens)


proc wait*(scene: Scene, duration: float = defaultDuration) =
  scene.animate(newTween(@[], linear, duration))

proc sleep*(scene: Scene, duration: float = defaultDuration) = scene.wait(duration)


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

  entity.draw(scene)

  for i in 0..high(entity.children):
    scene.draw(entity.children[i])


  scene.context.restore()


let
  vizBlue = rgb(100, 100, 200)
  vizGreen = rgb(100, 200, 100)
  vizRed = rgb(256, 100, 130)
  vizLightBlue = rgb(100, 200, 200)
  invizible = rgba(256, 100, 130, 0)


{.push checks: off, optimization: speed.}
proc visualizeTracks(scene: Scene) =
  scene.context.save()
  scene.scaleToUnit(compensate=true)
  let
    numberOfTracks = scene.tweenTracks.len()
    totalTrackHeight = 180.0
    trackHeight = min(totalTrackHeight/numberOfTracks.float, 30)

  var endTime: float = -1

  for track in scene.tweenTracks.values:
    let endTween = track.getLatestTween()
    if endTween.startTime + endTween.duration > endTime:
      endTime = endTween.startTime + endTween.duration

  let unit = 1000.0

  scene.context.fillColor(vizBlue)
  scene.context.textAlign(haLeft, vaMiddle)
  discard scene.context.text(-160.0, 10.0, &"FPS: {1000.0/scene.deltaTime:0f}")

  var i = 0
  for id, track in scene.tweenTracks.pairs:
    scene.context.fillColor(vizBlue)
    scene.context.textAlign(haLeft, vaMiddle)
    scene.context.globalAlpha(1.0)
    discard scene.context.text(-80, (i.float + 0.7) * trackHeight, "Track #" & $(id))
    scene.context.globalAlpha(0.3)

    for tween in track.tweens:
      scene.context.fillColor(vizBlue)
      if tween.interpolators.len() == 0:
        scene.context.strokeColor(vizGreen)

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

  scene.context.globalAlpha(1.0)

  if scene.restartTime > 0:
    let x = scene.restartTime/endTime * unit

    let gradient = scene.context.linearGradient(x, 2.5, x + 200, 2.5, vizRed, invizible)

    scene.context.beginPath()
    scene.context.roundedRect(x + 2.5, 2.5, 1 * unit, trackHeight * numberOfTracks.float, 10)
    scene.context.closePath()
    scene.context.strokePaint(gradient)
    scene.context.stroke()

  scene.context.fillColor(vizLightBlue)
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

  for i in 0..high(scene.entities):
    let entity = scene.entities[i]
    #[var intermediate = entity.deepCopy()

    # TODO: Decide what to do with projection of entity.children here...
    # Apply the scene's projection matrix to every point of every entity
    intermediate.points = sequtils.map(intermediate.points,
                                       proc(point: Vec3[float]): Vec3[float] =
                                         point.project(scene.projectionMatrix))]#

    if (entity.scaling.x == 0 and entity.scaling.y == 0) or len(entity.children) == 0 and (entity.style.opacity <= 0 or (entity.style.fillMode == smNone and entity.style.strokeMode == smNone) or (entity.position.x > 3000.0 or entity.position.x < -3000.0) or (entity.position.y > 3000.0 or entity.position.y < -3000.0)):
      continue

    scene.draw(entity)

  scene.foreground(scene)
  scene.context.restore()

  if scene.debug:
    scene.visualizeTracks()

{.pop.}


proc getCurrentRealTime*(): float =
  epochTime() * 1000.0


proc tick*(scene: Scene, deltaTime: float = 1000.0/120.0) =
  scene.deltaTime = deltaTime
  scene.time += scene.deltaTime

  scene.done = true

  for track in scene.tweenTracks.values:
    track.evaluate(scene.time)
    if not track.done:
      scene.done = false

  scene.draw()

  scene.lastTickTime = getCurrentRealTime()


proc update*(scene: Scene) =
  let
    time = getCurrentRealTime()
    goalDelta = 1000.0/scene.goalFPS
    delta = time - scene.lastTickTime

  if delta >= goalDelta:
    scene.tick(delta)

    if scene.done:
      scene.time = scene.restartTime
