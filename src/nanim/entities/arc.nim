
import
  math,
  nanovg,
  nanim/core


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
