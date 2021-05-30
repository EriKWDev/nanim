import
  glm,
  nanovg,
  math,
  sequtils,
  nanim/core,
  nanim/animation/tween,
  nanim/animation/easings


proc show*(entity: Entity): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]
  let delta = vec3(10.0, 0.0, 0.0)

  let
    startValue = entity.position.deepCopy() - delta
    endValue = entity.position.deepCopy()
    endOpacity = entity.style.opacity.deepCopy()

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)
    entity.style.opacity = interpolate(0.0, endOpacity, t)

  interpolators.add(interpolator)
  result = newTween(interpolators)

proc show*(entities: openArray[Entity]): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].show())

proc show*(scene: Scene, entity: Entity) =
  scene.play(entity.show())

proc show*(scene: Scene, entities: openArray[Entity]) =
  scene.play(entities.show())

proc showAllEntities*(scene: Scene) =
  var tweens: seq[Tween]

  for entity in scene.entities:
    tweens.add(entity.show())

  scene.play(tweens)



proc pscale*(scene: Scene, d: float = 0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.scale(vec3(d,d,d))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators)


proc protate*(scene: Scene, dangle: float = 0, mode: AngleMode = defaultAngleMode): Tween {.discardable.} =
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

proc pmove*(scene: Scene, dx: float = 0, dy: float = 0, dz: float = 0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = scene.projectionMatrix.deepCopy()
    endValue = startValue.translate(vec3(dx, dy, dz))

  let interpolator = proc(t: float) =
    scene.projectionMatrix = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  scene.projectionMatrix = endValue

  result = newTween(interpolators)

proc move*(entity: Entity, dx: float = 0.0, dy: float = 0.0, dz: float = 0.0): Tween {.discardable.} =
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


proc move*(entities: openArray[Entity], dx: float = 0.0, dy: float = 0.0, dz: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].move(dx, dy, dz))


proc moveX*(entity: Entity, dx: float = 0.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.position.x.deepCopy()
    endValue = startValue + dx

  let interpolator = proc(t: float) =
    entity.position.x = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position.x = endValue

  result = newTween(interpolators)

proc moveX*(entities: openArray[Entity], dx: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].moveX(dx))

proc moveY*(entity: Entity, dy: float = 0.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.position.y.deepCopy()
    endValue = startValue + dy

  let interpolator = proc(t: float) =
    entity.position.y = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position.y = endValue

  result = newTween(interpolators)

proc moveY*(entities: openArray[Entity], dy: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].moveY(dy))

proc moveZ*(entity: Entity, dz: float = 0.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.position.z.deepCopy()
    endValue = startValue + dz

  let interpolator = proc(t: float) =
    entity.position.z = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position.z = endValue

  result = newTween(interpolators)

proc moveZ*(entities: openArray[Entity], dz: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].moveY(dz))


proc moveLeft*(entity: Entity, d: float = 0.0): Tween {.discardable, inline.} = entity.moveX(-d)

proc moveLeft*(entities: openArray[Entity], d: float = 0.0): seq[Tween] {.discardable, inline.} = entities.moveX(-d)

proc moveRight*(entity: Entity, d: float = 0.0): Tween {.discardable, inline.} = entity.moveX(d)

proc moveRight*(entities: openArray[Entity], d: float = 0.0): seq[Tween] {.discardable, inline.} = entities.moveX(d)

proc moveUp*(entity: Entity, d: float = 0.0): Tween {.discardable, inline.} = entity.moveY(-d)

proc moveUp*(entities: openArray[Entity], d: float = 0.0): seq[Tween] {.discardable, inline.} = entities.moveY(-d)

proc moveDown*(entity: Entity, d: float = 0.0): Tween {.discardable, inline.} = entity.moveY(d)

proc moveDown*(entities: openArray[Entity], d: float = 0.0): seq[Tween] {.discardable, inline.} = entities.moveY(d)


proc moveTo*(entity: Entity, x: float = 0.0,  y: float = 0.0, z: float = 0.0): Tween {.discardable.} =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.position.deepCopy()
    endValue = vec3(x, y, z)

  let interpolator = proc(t: float) =
    entity.position = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.position = endValue

  result = newTween(interpolators)

proc moveTo*(entities: openArray[Entity], dx: float = 0.0, dy: float = 0.0, dz: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].moveTo(dx, dy, dz))


proc stretch*(entity: Entity, dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween {.discardable.} =

  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = startValue * vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators)

proc stretch*(entities: openArray[Entity], dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].stretch(dx, dy, dz))


proc stretchTo*(entity: Entity, dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.scaling.deepCopy()
    endValue = vec3(dx, dy, dz)

  let interpolator = proc(t: float) =
    entity.scaling = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.scaling = endValue

  result = newTween(interpolators)

proc stretchTo*(entities: openArray[Entity], dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].stretchTo(dx, dy, dz))


proc scale*(entity: Entity, d: float = 1.0): Tween {.discardable, inline.} =
  return entity.stretch(d, d, d)

proc scale*(entities: openArray[Entity], d: float = 1.0): seq[Tween] {.discardable, inline.} =
  return entities.stretch(d, d, d)


proc scaleTo*(entity: Entity, d: float = 1.0): Tween {.discardable.} =
  return entity.stretchTo(d, d, d)

proc scaleTo*(entities: openArray[Entity], d: float = 1.0):  seq[Tween] {.discardable.} =
  return entities.stretchTo(d, d, d)


proc pstretch*(entity: Entity, dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): Tween {.discardable.} =

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

proc pstretch*(entities: openArray[Entity], dx: float = 1.0, dy: float = 1.0, dz: float = 1.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].pstretch(dx, dy, dz))


proc pscale*(entities: openArray[Entity], d: float = 1.0): seq[Tween] {.discardable, inline.} =
  return entities.pstretch(d, d, d)

proc pscale*(entity: Entity, d: float = 1.0): Tween {.discardable, inline.} =
  return entity.pstretch(d, d, d)


proc rotate*(entity: Entity, dangle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween {.discardable.} =
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

proc rotate*(entities: openArray[Entity], dangle: float = 0.0, mode: AngleMode = defaultAngleMode): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].rotate(dangle, mode))


proc fill*(entity: Entity, fillColor: Color): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.style.fillColor.deepCopy()
    endValue = fillColor
    startBlend = entity.style.fillColorToPatternBlend.deepCopy()

  let interpolator = proc(t: float) =
    entity.style.fillColor = interpolate(startValue, endValue, t)
    entity.style.fillColorToPatternBlend = interpolate(startBlend, 0.0, t)

  interpolators.add(interpolator)

  entity.style = entity.style.copyWith(fillColor=endValue, fillMode=smSolidColor)

  result = newTween(interpolators)

proc fill*(entities: openArray[Entity], fillColor: Color): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].fill(fillColor))

proc fill*(entity: Entity, fillPattern: proc(scene: Scene): Paint): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.style.fillPattern.deepCopy()
    endValue = fillPattern
    startBlend = entity.style.fillColorToPatternBlend.deepCopy()

  let interpolator = proc(t: float) =
    entity.style.fillColorToPatternBlend = interpolate(startBlend, 1.0, t)
    entity.style.fillPattern = eitherOrInterpolation(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.style = entity.style.copyWith(fillPattern=endValue, fillMode=smPaintPattern)

  result = newTween(interpolators)

proc fill*(entities: openArray[Entity], fillPattern: proc(scene: Scene): Paint): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].fill(fillPattern))


proc stroke*(entity: Entity, strokeColor: Color, strokeWidth: float = entity.style.strokeWidth): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.style.strokeColor.deepCopy()
    endValue = strokeColor
    startBlend = entity.style.strokeColorToPatternBlend.deepCopy()
    startStrokeWidth = entity.style.strokeWidth.deepCopy()

  let interpolator = proc(t: float) =
    entity.style.strokeColor = interpolate(startValue, endValue, t)
    entity.style.strokeColorToPatternBlend = interpolate(startBlend, 0.0, t)
    entity.style.strokeWidth = interpolate(startStrokeWidth, strokeWidth, t)

  interpolators.add(interpolator)

  entity.style = entity.style.copyWith(strokeColor=endValue, strokeMode=smSolidColor, strokeWidth=strokeWidth)

  result = newTween(interpolators)

proc stroke*(entities: openArray[Entity], strokeColor: Color, strokeWidth: float = entities[0].style.strokeWidth): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].stroke(strokeColor, strokeWidth))


proc paint*(entity: Entity, style: Style): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startStyle = entity.style.deepCopy()
    endStyle = style.deepCopy()

  let interpolator = proc(t: float) =
    entity.style.fillColor = interpolate(startStyle.fillColor, endStyle.fillColor, t)
    entity.style.fillColorToPatternBlend = interpolate(startStyle.fillColorToPatternBlend, endStyle.fillColorToPatternBlend, t)

    if startStyle.fillPattern != endStyle.fillPattern:
      entity.style.fillPattern = endStyle.fillPattern
    else:
      entity.style.fillPattern = eitherOrInterpolation(startStyle.fillPattern, endStyle.fillPattern, t)

    entity.style.strokeColor = interpolate(startStyle.strokeColor, endStyle.strokeColor, t)
    entity.style.strokeColorToPatternBlend = interpolate(startStyle.strokeColorToPatternBlend, endStyle.strokeColorToPatternBlend, t)
    entity.style.strokePattern = eitherOrInterpolation(startStyle.strokePattern, endStyle.strokePattern, t)
    entity.style.strokeWidth = interpolate(startStyle.strokeWidth, endStyle.strokeWidth, t)
    entity.style.opacity = interpolate(startStyle.opacity, endStyle.opacity, t)

  interpolators.add(interpolator)
  entity.style.apply(endStyle)

  result = newTween(interpolators)

proc paint*(entities: openArray[Entity], style: Style): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].paint(style))


proc fadeTo*(entity: Entity, opacity=1.0): Tween {.discardable.} =
  entity.paint(entity.style.copyWith(opacity=opacity))

proc fadeTo*(entities: openArray[Entity], opacity=1.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].fadeTo(opacity))


proc fadeIn*(entity: Entity): Tween {.discardable.} = entity.fadeTo(1.0)

proc fadeIn*(entities: openArray[Entity]): seq[Tween] {.discardable.} = entities.fadeTo(1.0)


proc fadeOut*(entity: Entity): Tween {.discardable.} = entity.fadeTo(0.0)

proc fadeOut*(entities: openArray[Entity]): seq[Tween] {.discardable.} = entities.fadeTo(0.0)


proc rotateTo*(entity: Entity, dangle: float = 0.0, mode: AngleMode = defaultAngleMode): Tween {.discardable.} =
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

proc rotateTo*(entities: openArray[Entity], dangle: float = 0.0, mode: AngleMode = defaultAngleMode): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].rotateTo(dangle, mode))


proc setTension*(entity: Entity, tension: float = 0.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.tension.deepCopy()
    endValue = tension

  let interpolator = proc(t: float) =
    entity.tension = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.tension = endValue

  result = newTween(interpolators)

proc setTension*(entities: openArray[Entity], tension: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].setTension(tension))


proc morphPoints*(entity: Entity, points: seq[Vec3[float]]): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.points.deepCopy()
    endValue = points.deepCopy()

  let interpolator = proc(t: float) =
    entity.points = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)
  entity.points = endValue
  result = newTween(interpolators)

proc morphPoints*(entities: openArray[Entity], points: seq[Vec3[float]]): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].morphPoints(points))


proc pmove*(entity: Entity, dx: float = 0, dy: float = 0, dz: float = 0): Tween {.discardable.} =
  let endValue = entity.points.map(proc(point: Vec3[float]): Vec3[float] = point + vec3(dx, dy, dz))

  result = entity.morphPoints(endValue)

proc pmove*(entities: openArray[Entity], dx: float = 0, dy: float = 0, dz: float = 0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].pmove(dx, dy, dz))


proc setCornerRadius*(entity: Entity, cornerRadius: float = 0.0): Tween {.discardable.} =
  var interpolators: seq[proc(t: float)]

  let
    startValue = entity.cornerRadius.deepCopy()
    endValue = cornerRadius

  let interpolator = proc(t: float) =
    entity.cornerRadius = interpolate(startValue, endValue, t)

  interpolators.add(interpolator)

  entity.cornerRadius = endValue

  result = newTween(interpolators)

proc setCornerRadius*(entities: openArray[Entity], cornerRadius: float = 0.0): seq[Tween] {.discardable.} =
  for i in 0..high(entities):
    result.add(entities[i].setCornerRadius(cornerRadius))