
import sequtils, math


import
  glm,
  cairo,
  ../animation/tween,
  ../animation/easings


type
  Position* = Vec3[float]
  Scale* = Vec3[float]

  Entity* = ref object of RootObj
    points*: seq[Vec3[float]]
    tension*: float
    cornerRadius*: float

    position*: Position
    rotation*: float
    scaling*: Scale


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


# Adapted from node-canvas' CanvasRenderingContext2d.cc#L2912
# which in turn was adapted from WebKit implementation
proc arcTo(context: ptr Context, x1: float, y1:float, x2: float, y2: float, radius: float) =
  var
    x0: float
    y0: float

  context.getCurrentPoint(x0, y0)

  if (x1 == x0 and y1 == y0) or (x1 == x2 and y1 == y2) or radius == 0:
    context.lineTo(x1, y1)
    return

  let
    x1x0 = x0 - x1
    y1y0 = y0 - y1

    x1x2 = x2 - x1
    y1y2 = y2 - y1

    length10 = sqrt(x1x0 * x1x0 + y1y0 * y1y0)
    length21 = sqrt(x1x2 * x1x2 + y1y2 * y1y2)

    cosPhi = (x1x0 * x1x2 + y1y0 * y1y2) / (length10 * length21)

  if cosPhi == -1:
    context.lineTo(x1, y1)
    return

  if cosPhi == 1:
    let
      maxLength = 65535.0
      maxFactor = maxLength / length10

      ex = x0 + maxFactor * x1x0
      ey = y0 + maxFactor * y1y0

    context.lineTo(ex, ey)
    return

  let
    tangent = radius / tan(arccos(cosPhi) / 2.0)
    factor10 = tangent / length10

    tx1x0 = x1 + factor10 * x1x0
    ty1y0 = y1 + factor10 * y1y0

  var
    x1x0Ortho = y1y0
    y1y0Ortho = -x1x0

  let
    length10Ortho = sqrt(x1x0Ortho * x1x0Ortho + y1y0Ortho * y1y0Ortho) # Same as length10, no?
    radiusFactor = radius / length10Ortho

    cosAlpha = (x1x0Ortho * x1x2 + y1y0Ortho * y1y2) / (length10Ortho * length21)

  if cosAlpha < 0:
    x1x0Ortho = -x1x0Ortho
    y1y0Ortho = -y1y0Ortho

  let
    pointX = tx1x0 + radiusFactor * x1x0Ortho
    pointY = ty1y0 + radiusFactor * y1y0Ortho

  x1x0Ortho = -x1x0Ortho
  y1y0Ortho = -y1y0Ortho

  var sa = arccos(x1x0Ortho / length10Ortho)

  if y1y0Ortho < 0:
    sa = 2 * PI - sa

  let
    factor12 = tangent / length21
    tx1x2 = x1 + factor12 * x1x2
    ty1y2 = y1 + factor12 * y1y2

    x1x2Ortho = tx1x2 - pointX
    y1y2Ortho = ty1y2 - pointY

    length21Ortho = sqrt(x1x2Ortho * x1x2Ortho + y1y2Ortho * y1y2Ortho)

  var
    antiClockwise = false
    ea = arccos(x1x2Ortho / length21Ortho)

  if y1y2Ortho < 0:
    ea = 2 * PI - ea

  if (sa > ea and (sa - ea < PI)) or (sa < ea and (sa - ea > PI)):
    antiClockwise = true

  context.lineTo(tx1x0, ty1y0)

  if antiClockwise and PI * 2 != radius:
    context.arcNegative(pointX, pointY, radius, sa, ea)
  else:
    context.arc(pointX, pointY, radius, sa, ea)


proc drawPointsWithTension*(context: ptr Context, points: seq[Vec], tension: float = 0.5) =
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

    context.curveTo(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)


proc drawPointsWithRoundedCornerRadius*(context: ptr Context, points: seq[Vec], cornerRadius: float = 20) =
    if len(points) < 2: return

    var p1 = points[0]

    let lastPoint = points[high(points)]
    let midPoint = vec2((p1.x + lastPoint.x) / 2.0, (p1.y + lastPoint.y) / 2.0)

    context.moveTo(midPoint.x, midPoint.y)
    for i in 1..high(points):
      let p2 = points[i]

      context.arcTo(p1.x, p1.y, p2.x, p2.y, cornerRadius)
      p1 = p2

    context.arcTo(p1.x, p1.y, midPoint.x, midPoint.y, cornerRadius)


type
  Color* = tuple
    r: float
    g: float
    b: float
    a: float


func rgba*(r, g, b, a: float = 1.0): Color =
  result = (r: r/255.0, g: g/255.0, b: b/255.0, a: a)


func rgb*(r, g, b: float): Color =
  result = rgba(r, g, b, 1.0)


proc setColor*(context: ptr Context, color: Color) =
  context.setSourceRgba(color.r, color.g, color.b, color.a)


method draw*(entity: Entity, context: ptr Context) {.base.} =
  context.newPath()
  if entity.tension > 0:
    context.drawPointsWithTension(entity.points, entity.tension)
  else:
    context.drawPointsWithRoundedCornerRadius(entity.points, entity.cornerRadius)
  context.closePath()

  context.setLineWidth(20)
  context.setColor(rgb(230, 26, 94))
  context.stroke()
  context.setColor(rgb(255, 56, 116))
  context.fill()


func init*(entity: Entity) =
  entity.points = @[]
  entity.tension = 0.0
  entity.cornerRadius = 20.0
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec3(1.0, 1.0, 1.0)


func newEntity*(points: seq[Vec3[float]]): Entity =
  new(result)
  result.init()
  result.points = points


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

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


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

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func stretch*(entity: Entity,
              dx: float = 0.0,
              dy: float = 0.0,
              dz: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = startValue * vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func scale*(entity: Entity, d: float = 0.0): Tween =
  return entity.stretch(d, d, d)


proc pscale*(entity: Entity, d: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.points.deepCopy()
    endValue = entity.points.map(proc(point: Vec3[float]): Vec3[float] = point * d)

    startCornerRadius = entity.cornerRadius.deepCopy()
    endCornerRadius: float = startCornerRadius * d

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startCornerRadius, endCornerRadius, t)
    entity.points = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.points = endValue
  entity.cornerRadius = endCornerRadius

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


type
  AngleMode* = enum
    amDegrees, amRadians


func rotate*(entity: Entity, dangle: float = 0.0, mode: AngleMode = amDegrees): Tween =
  var interpolators: seq[proc(t: float)]
  var angle: float

  case mode:
  of amDegrees: angle = math.degToRad(dangle)
  of amRadians: angle = dangle

  let
    startValue = entity.rotation.deepCopy()
    endValue = startValue + angle

  let interpolator = proc(t: float) =
    entity.rotation = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.rotation = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc setTension*(entity: Entity, tension: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.tension.deepCopy()
    endValue = tension

  let interpolator = proc(t: float) =
    entity.tension = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.tension = endValue

  result = newTween(interpolators, defaultEasing, defaultDuration)


proc setCornerRadius*(entity: Entity, cornerRadius: float = 0.0): Tween =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.cornerRadius.deepCopy()
    endValue = cornerRadius

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.cornerRadius = endValue

  result = newTween(interpolators, defaultEasing, defaultDuration)
