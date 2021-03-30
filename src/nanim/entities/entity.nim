
import sequtils, math


import
  glm,
  nanovg,
  ../animation/tween,
  ../animation/easings,
  ../drawing


type
  Position* = Vec3[float]
  Scale* = Vec3[float]

  Context* = NVGContext

  AngleMode* = enum
    amDegrees, amRadians

  Entity* = ref object of RootObj
    points*: seq[Vec3[float]]

    tension*: float
    cornerRadius*: float

    position*: Position
    rotation*: float
    scaling*: Scale

    children*: seq[Entity]


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


method draw*(entity: Entity, context: Context) {.base.} =
  context.beginPath()

  if entity.tension > 0:
    context.drawPointsWithTension(entity.points, entity.tension)
  else:
    context.drawPointsWithRoundedCornerRadius(entity.points, entity.cornerRadius)

  context.closePath()

  # context.fillColor(rgb(255, 56, 116))
  context.fillPaint(context.gridPattern())
  context.fill()

  context.strokeColor(rgb(230, 26, 94))
  context.strokeWidth(5)
  context.stroke()


func init*(entity: Entity) =
  entity.points = @[]
  entity.children = @[]
  entity.tension = 0.0
  entity.cornerRadius = 20.0
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

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func scale*(entity: Entity, d: float = 1.0): Tween =
  return entity.stretch(d, d, d)


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

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc pstretch*(entities: varargs[Entity], dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween =
  var interpolators: seq[proc(t: float)]

  for entity in entities:
    interpolators &= entity.pstretch(dx, dy, dz).interpolators

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


proc pscale*(entities: openArray[Entity], d: float = 1.0): Tween =
  return entities.pstretch(d, d, d)


proc pscale*(entity: Entity, d: float = 1.0): Tween =
  return entity.pstretch(d, d, d)


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
