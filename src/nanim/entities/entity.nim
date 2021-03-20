
import
  options


import
  glm,
  nanovg,
  ../animation/tween,
  ../animation/easings


type
  EntityPoints* = seq[Vec3[float]]
  Position* = Vec3[float]
  Rotation* = float
  Scale* = Vec2[float]

  Context* = NVGContext

  Entity* = ref object of RootObj
    points*: EntityPoints
    position*: Position
    rotation*: Rotation
    scaling*: Scale


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  position: " & $(entity.position) & "\n" &
    "  rotation: " & $(entity.rotation)


proc init(entity: Entity, points: EntityPoints) =
  entity.points = points
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scaling = vec2(1.0, 1.0)


func newEntity*(points: EntityPoints): Entity =
  new(result)
  result.init(points)


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
              dy: float = 0.0): Tween =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = startValue * vec2(dx, dy)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators,
                    defaultEasing,
                    defaultDuration)


func scale*(entity: Entity, d: float = 0.0): Tween =
  return entity.stretch(d, d)


func rotate*(entity: var Entity, dangle: SomeNumber = 0f) =
  entity.transformMatrix = rotateZ(entity.transformMatrix, dangle)


proc drawPointsWithTension(context: Context, points: seq[Vec], tension: float = 0.5) =
  context.moveTo(points[0].x, points[0].y)

  let control_scale = tension / 0.5 * 0.175
  let num_points = len(points)

  for i in 0..len(points) - 1:
    let points_before = points[(i - 1 + num_points) mod num_points]
    let point = points[i]
    let points_after = points[(i + 1) mod num_points]
    let points_after2 = points[(i + 2) mod num_points]

    let p4 = points_after

    let di = vec2(points_after.x - points_before.x, points_after.y - points_before.y)
    let p2 = vec2(point.x + control_scale * di.x, point.y + control_scale * di.y)

    let diPlus1 = vec2(points_after2.x - points[i].x, points_after2.y - points[i].y)

    let p3 = vec2(points_after.x - control_scale * diPlus1.x, points_after.y - control_scale * diPlus1.y)

    context.bezierTo(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)


proc draw*(entity: Entity, context: Context) =
  context.fillColor(rgb(255, 50, 150))
  context.strokeColor(rgb(240, 28, 130))
  context.strokeWidth(20)
  context.beginPath()

  context.drawPointsWithTension(entity.points)

  context.closePath()
  context.stroke()
  context.fill()


proc draw*(context: Context, entity: Entity) =
  context.save()

  context.translate(entity.position.x, entity.position.y)
  context.scale(entity.scaling.x, entity.scaling.y)
  context.rotate(entity.rotation)

  entity.draw(context)

  context.restore()
