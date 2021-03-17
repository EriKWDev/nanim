
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
    scale*: Scale


proc `$`*(entity: Entity): string =
  result =
    "entity\n" &
    "  position: " & $(entity.position) & "\n" &
    "  rotation: " & $(entity.rotation)



proc init(entity: Entity, points: EntityPoints) =
  entity.points = points
  entity.position = vec3(0.0, 0.0, 0.0)
  entity.rotation = 0.0
  entity.scale = vec2(1.0, 1.0)

func newEntity*(points: EntityPoints): Entity =
  new(result)
  result.init(points)


func move*(entity: Entity, dx = 0.0, dy = 0.0, dz: float = 0.0): Tween[Entity, Position] =

  result = newTween(entity,
                    entity.position,
                    entity.position + vec3(dx, dy, dz),
                    proc(e: Entity, v: Position) =
                      e.position = v,
                    linear)

  entity.position = entity.position + vec3(dx, dy, dz)


func rotate*(entity: var Entity, dangle: SomeNumber = 0f) =
  entity.transformMatrix = rotateZ(entity.transformMatrix, dangle)



proc draw*(context: Context, entity: Entity) =
  context.save()

  context.translate(entity.position.x, entity.position.y)
  context.scale(entity.scale.x, entity.scale.y)
  context.rotate(entity.rotation)

  context.fillColor(rgb(255, 50, 150))
  context.beginPath()

  let points = entity.points

  context.moveTo(points[0].x, points[0].y)

  for i in 1..len(points) - 2:
    let xc = (points[i].x + points[i + 1].x) / 2
    let yc = (points[i].y + points[i + 1].y) / 2
    context.quadTo(points[i].x, points[i].y, xc, yc)

  context.quadTo(points[len(points)-2].x,
                 points[len(points)-2].y,
                 points[len(points)-1].x,
                 points[len(points)-1].y)

  context.quadTo(points[len(points)-1].x,
                 points[len(points)-1].y,
                 points[0].x,
                 points[0].y)

  context.closePath()
  context.stroke()
  context.fill()
  context.restore()