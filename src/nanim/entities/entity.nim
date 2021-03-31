
import sequtils, math


import
  glm,
  nanovg,
  ../animation/tween,
  ../animation/easings,
  ../drawing


type
  AngleMode* = enum
    amDegrees, amRadians

  Entity* = ref object of RootObj
    points*: seq[Vec3[float]]

    tension*: float
    cornerRadius*: float

    position*: Vec3[float]
    rotation*: float
    scaling*: Vec3[float]

    children*: seq[Entity]


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  points:   " & $(entity.points.len) & "\n" &
    "  position: " & $(entity.position) & "\n" &
    "  scale:    " & $(entity.scaling) & "\n" &
    "  rotation: " & $(entity.rotation) & "\n" &
    "  tension:  " & $(entity.tension)


method draw*(entity: Entity, context: NVGContext) {.base.} =
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
  let endValue = entity.position.deepCopy()

  simpleSingleValueTween(entity, endValue - vec3(10.0, 0.0, 0.0), endValue, position)


func move*(entity: Entity, dx: float = 0.0, dy: float = 0.0, dz: float = 0.0): Tween =
  let startValue = entity.position.deepCopy()

  simpleSingleValueTween(entity, startValue, startValue + vec3(dx, dy, dz), position)


func stretch*(entity: Entity, dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween =
  let startValue = entity.scaling.deepCopy()

  simpleSingleValueTween(entity, startValue, startValue * vec3(dx, dy, dz), position)


func scale*(entity: Entity, d: float = 1.0): Tween =
  return entity.stretch(d, d, d)


func scaleTo*(entity: Entity, newScale: float = 1.0): Tween =
  simpleSingleValueTween(entity, entity.scaling.deepCopy(), vec3(newScale, newScale, newScale), scaling)


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


proc pscale*(entities: varargs[Entity], d: float = 1.0): Tween =
  return entities.pstretch(d, d, d)


const defaultAngleMode*: AngleMode = amDegrees


func rotate*(entity: Entity, dangle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween =
  let
    angle = case mode:
      of amDegrees: math.degToRad(dangle)
      of amRadians: dangle

    startValue = entity.rotation.deepCopy()

  simpleSingleValueTween(entity, startValue, startValue + angle, rotation)


func rotateTo*(entity: Entity, newAngle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween =
  let newRotation = case mode:
    of amDegrees: degToRad(newAngle)
    of amRadians: newAngle

  simpleSingleValueTween(entity, entity.rotation.deepCopy(), newRotation, rotation)


proc setTension*(entity: Entity, newTension: float = 0.0): Tween =
  simpleSingleValueTween(entity, entity.tension.deepCopy(), newTension, tension)


proc setCornerRadius*(entity: Entity, newCornerRadius: float = 0.0): Tween =
  simpleSingleValueTween(entity, entity.cornerRadius.deepCopy(), newCornerRadius, cornerRadius)
