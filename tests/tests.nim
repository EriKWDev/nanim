
import
  unittest,
  nanim,
  tables,
  utils


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


  test "Value setters":
    var circle = newCircle()
    discard circle.setCornerRadius(25.0)
    check circle.cornerRadius ~= 25.0

    discard circle.setCornerRadius(0.0)
    check circle.cornerRadius ~= 0.0


suite "Interpolations & Easings tests":
  test "Easings":
    check linear(0.1) ~= 0.1
    check linear(1.0) ~= 1.0

    check sigmoid4(0.0) ~= 0.0
    check sigmoid4(1.0) ~= 1.0
    check sigmoid4(0.5) ~= 0.5

    check smoothOvershoot(0.0) ~= 0.0
    check smoothOvershoot(1.0) ~= 1.0


  test "Interpolations":
    check interpolate(0.0, 1.0, 0.5) ~= 0.5
    check interpolate(100.0, 150.0, 0.5) ~= 125.0
    check interpolate(-100.0, 100.0, 0.5) ~= 0.0


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


  test "Simple Tweens":
    var entity = newBestagon()

    let
      oldPosition = entity.position
      moveTween1 = entity.move(100, 200)

    check entity.position.x ~= (oldPosition.x + 100.0)
    check entity.position.y ~= (oldPosition.y + 200.0)

    moveTween1.evaluate(0.0)

    check entity.position.x ~= oldPosition.x
    check entity.position.y ~= oldPosition.y

    moveTween1.evaluate(defaultDuration)

    check entity.position.x ~= (oldPosition.x + 100.0)
    check entity.position.y ~= (oldPosition.y + 200.0)

    let
      moveTween2 = entity.move(100, 100)
      tweenTrack = newTweenTrack()

    moveTween2.startTime = defaultDuration
    tweenTrack.add(moveTween1, moveTween2)
    tweenTrack.evaluate(0)

    check entity.position.x ~= oldPosition.x
    check entity.position.y ~= oldPosition.y

    tweenTrack.evaluate(defaultDuration)

    check entity.position.x ~= (oldPosition.x + 100.0)
    check entity.position.y ~= (oldPosition.y + 200.0)

    tweenTrack.evaluate(defaultDuration*2)

    check entity.position.x ~= (oldPosition.x + 100.0 + 100.0)
    check entity.position.y ~= (oldPosition.y + 200.0 + 100.0)


