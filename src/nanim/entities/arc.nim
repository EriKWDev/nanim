
import
  math,
  nanovg,
  nanim/core,
  nanim/animation


type
  Arc* = ref object of Entity
    radius: float
    startAngle: float
    endAngle: float
    direction: PathWinding


proc init*(arc: Arc) =
  init(arc.Entity)
  arc.tension = 0
  arc.radius = 0
  arc.startAngle = 0.0
  arc.direction = pwCW


proc newArc*(radius: float = 200.0, startAngle: float = 0.0, endAngle: float = 180.0, clockWise: bool = true, mode: AngleMode = defaultAngleMode): Arc =
  new(result)
  result.init()
  result.radius = radius
  result.startAngle = parseAngleToRad(startAngle, mode)
  result.endAngle = parseAngleToRad(endAngle, mode)
  result.direction = if clockWise: pwCW else: pwCCW


method draw*(arcEntity: Arc, scene: Scene) =
  let context = scene.context
  context.beginPath()
  context.arc(0, 0, arcEntity.radius, arcEntity.startAngle, arcEntity.endAngle, arcEntity.direction)
  # context.closePath()
  scene.applyStyle(arcEntity.style)


proc endAngleTo*(arc: Arc, endAngle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    angle =
      case mode:
      of amDegrees: math.degToRad(endAngle)
      of amRadians: endAngle
    startValue = arc.endAngle.deepCopy()
    endValue = angle

  let interpolator = proc(t: float) =
    arc.endAngle = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  arc.endAngle = endValue

  result = newTween(interpolators)

proc endAngleTo*(entities: openArray[Arc], endAngle: float = 0.0, mode: AngleMode = defaultAngleMode): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].endAngleTo(endAngle, mode))


proc startAngleTo*(entity: Arc, startAngle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    angle =
      case mode:
      of amDegrees: math.degToRad(startAngle)
      of amRadians: startAngle
    startValue = entity.startAngle.deepCopy()
    endValue = angle

  let interpolator = proc(t: float) =
    entity.startAngle = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)
  entity.startAngle = endValue
  result = newTween(interpolators)

proc startAngleTo*(entities: openArray[Arc], startAngle: float = 0.0, mode: AngleMode = defaultAngleMode): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].startAngleTo(startAngle, mode))
