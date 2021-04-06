
import
  unittest,
  nanim,
  tables,
  utils,
  nanovg


suite "Scene & Entity tests":
  test "Simple Scene with Entity.move()":
    proc simpleScene(): Scene =
      let scene = newScene()

      var circle = newCircle()
      scene.add(circle)

      let oldPosition = circle.position

      let circleMoveTween = circle.move(100, 100)
      check circle.position.x == oldPosition.x + 100.0
      check circle.position.y == oldPosition.y + 100.0

      checkpoint("move() correctly moves entity")

      check circleMoveTween.interpolators.len() > 0

      for interpolator in circleMoveTween.interpolators: interpolator(0.0)

      check circle.position.x ~= oldPosition.x
      check circle.position.y ~= oldPosition.y

      checkpoint("move() tween correctly evaluates at alpha 0.0")

      for interpolator in circleMoveTween.interpolators: interpolator(1.0)

      check circle.position.x ~= (oldPosition.x + 100.0)
      check circle.position.y ~= (oldPosition.y + 100.0)

      checkpoint("move() tween correctly evaluates at alpha 1.0")

      return scene

    discard simpleScene()


  test "Simple Scene with Entity.rotate()":
    proc simpleScene(): Scene =
      let scene = newScene()

      var bestagon = newBestagon()
      scene.add(bestagon)

      let beginningRotation = bestagon.rotation
      discard bestagon.rotate(180, amDegrees)
      check bestagon.rotation ~= (beginningRotation + PI)

      checkpoint("rotate() correctly rotates entity by degrees")

      let oldRotation = bestagon.rotation
      discard bestagon.rotate(2.0 * PI, amRadians)
      check bestagon.rotation ~= (oldRotation + 2.0 * PI)

      checkpoint("rotate() correctly rotates entity by radians")

      return scene

    discard simpleScene()


  test "Scene Initializing a Bunch of Entities":
    proc simpleScene(): Scene =
      let scene = newScene()

      var entities = @[newCircle(), newSquare(), newRectangle(), newText(), newPentagon(), newHexagon(), newHeptagon(), newEngon(100)]
      checkpoint("a bunch of entities could be initialized")

      for entity in entities:
        scene.add(entity)
      check scene.entities.len() == entities.len()
      checkpoint("entities could be added to scene one by one")

      scene.add(entities)
      check scene.entities.len() == entities.len() * 2
      checkpoint("entities could be added to scene in bulk")

      return scene

    discard simpleScene()


suite "Easings, Tweens and Interpolations":
  test "Easings":
    check linear(0.1) ~= 0.1
    check linear(1.0) ~= 1.0

    check sigmoid4(0.0) ~= 0.0
    check sigmoid4(1.0) ~= 1.0
    check sigmoid4(0.5) ~= 0.5

    check smoothOvershoot(0.0) ~= 0.0
    check smoothOvershoot(1.0) ~= 1.0

    let easings = @[linear, sigmoid2, sigmoid3, sigmoid4, sigmoid5, smoothOvershoot, inQuad, outQuad, inExpo, outExpo]
    for easingFunction in easings:
      check easingFunction(0.0) ~= 0.0
      check easingFunction(1.0) ~= 1.0


  test "Interpolations":
    check interpolate(0.0, 1.0, 0.5) ~= 0.5
    check interpolate(100.0, 150.0, 0.5) ~= 125.0
    check interpolate(-100.0, 100.0, 0.5) ~= 0.0

    check interpolate(1.0, -1.0, 1.0) ~= -1.0
    check interpolate(-1.0, 1.0, 1.0) ~= 1.0

    check interpolate(false, true, 1.0) == true
    check interpolate(false, true, 0.2) == false
    check interpolate(false, true, 0.7) == true
    check interpolate(false, true, 0.0) == false

    let
      fromColor = rgb(0,0,0)
      toColor = rgb(255,255,255)
      interpolatedColor00 = interpolate(fromColor, toColor, 0.0)
      interpolatedColor10 = interpolate(fromColor, toColor, 1.0)

    check interpolatedColor00.r ~= fromColor.r
    check interpolatedColor00.g ~= fromColor.g
    check interpolatedColor00.b ~= fromColor.b
    check interpolatedColor00.a ~= fromColor.a

    check interpolatedColor10.r ~= toColor.r
    check interpolatedColor10.g ~= toColor.g
    check interpolatedColor10.b ~= toColor.b
    check interpolatedColor10.a ~= toColor.a

    var
      points1 = @[vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0)]
      points2 = @[vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0)]

      interpolatedPoints00 = interpolate(points1, points2, 0.0)
      interpolatedPoints05 = interpolate(points1, points2, 0.5)
      interpolatedPoints10 = interpolate(points1, points2, 1.0)

    check interpolatedPoints00[0] ~= vec3(0.0, 0.0, 0.0)
    check interpolatedPoints00[1] ~= vec3(1.0, 1.0, 1.0)
    check interpolatedPoints00[2] ~= vec3(0.0, 0.0, 0.0)

    check interpolatedPoints05[0] ~= vec3(0.5, 0.5, 0.5)
    check interpolatedPoints05[1] ~= vec3(0.5, 0.5, 0.5)
    check interpolatedPoints05[2] ~= vec3(0.5, 0.5, 0.5)

    check interpolatedPoints10[0] ~= vec3(1.0, 1.0, 1.0)
    check interpolatedPoints10[1] ~= vec3(0.0, 0.0, 0.0)
    check interpolatedPoints10[2] ~= vec3(1.0, 1.0, 1.0)


  test "Simple Tracks":
    let scene = newScene()
    check scene.tweenTracks.len() == 1

    var
      circle = newCircle()
      rectangle = newRectangle()

    scene.add(circle, rectangle)
    scene.play(circle.move(100))
    scene.wait(2500)

    scene.switchTrack(2)
    scene.play(rectangle.move(100))
    check scene.tweenTracks.len() == 2

    scene.wait(1500)

    scene.syncTracks()
    check scene.getLatestTween().duration ~= 1000.0


  test "Discarded Tweens Should Still Set Values":
    var entity = newPentagon()
    discard entity.setCornerRadius(25.0)
    check entity.cornerRadius ~= 25.0

    discard entity.setCornerRadius(0.0)

    check entity.cornerRadius ~= 0.0


  test "Simple Tweens 1":
    var entity = newBestagon()

    let
      oldPosition = entity.position
      moveTween1 = entity.move(100, 200)

    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    moveTween1.evaluate(0.0)
    check entity.position ~= oldPosition

    moveTween1.evaluate(defaultDuration)
    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    let
      moveTween2 = entity.move(100, 100)
      tweenTrack = newTweenTrack()

    check entity.position ~= (oldPosition + vec3(100.0 + 100.0, 200.0 + 100.0, 0.0))

    moveTween2.startTime = defaultDuration
    tweenTrack.add(moveTween1, moveTween2)

    tweenTrack.evaluate(0)
    check entity.position ~= oldPosition

    tweenTrack.evaluate(defaultDuration)
    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    tweenTrack.evaluate(defaultDuration*2)
    check entity.position ~= (oldPosition + vec3(100.0 + 100.0, 200.0 + 100.0, 0.0))


  test "Simple Tweens 2":
    var entity = newRectangle()

    discard entity.moveTo(100, 100)
    check entity.position ~= vec2(100.0, 100.0)

    let tween1 = entity.moveTo(500, 500)
    check entity.position ~= vec2(500.0, 500.0)

    tween1.evaluate(0)
    check entity.position ~= vec2(100.0, 100.0)

    tween1.execute(1)
    check entity.position ~= vec2(500.0, 500.0)
    tween1.execute(0)
    check entity.position ~= vec2(100.0, 100.0)
    tween1.execute(1)
    check entity.position ~= vec2(500.0, 500.0)
    tween1.execute(0)
    check entity.position ~= vec2(100.0, 100.0)


  test "Track Evaluation":
    var
      track = newTweenTrack()
      entity = newCircle()

    discard entity.moveTo(0, 0)
    check entity.position ~= vec2(0.0, 0.0)

    let tween1 = entity.move(100, 100)
    check entity.position ~= vec2(100.0, 100.0)
    tween1.startTime = 0.0
    tween1.duration = 1000.0
    track.add(tween1)

    let tween2 = entity.moveTo(500, 500)
    check entity.position ~= vec2(500.0, 500.0)
    tween2.startTime = 1000.0
    tween2.duration = 1000.0
    track.add(tween2)

    let tween3 = entity.moveTo(1000, 1000)
    check entity.position ~= vec2(1000.0, 1000.0)
    tween3.startTime = 2000.0
    tween3.duration = 1000.0
    track.add(tween3)


    track.evaluate(0.0)
    check entity.position ~= vec2(0.0, 0.0)
    track.evaluate(1000.0)
    check entity.position ~= vec2(100.0, 100.0)
    track.evaluate(2000.0)
    check entity.position ~= vec2(500.0, 500.0)
    track.evaluate(3000.0)
    check entity.position ~= vec2(1000.0, 1000.0)
