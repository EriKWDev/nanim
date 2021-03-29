
import
  unittest,
  nanim


const Tolerance = 1e-8


proc `~=`(a, b: float): bool =
  ## Check if "a" and "b" are close.
  ## We use a relative tolerance to compare the values.

  result = abs(a - b) <= max(abs(a), abs(b)) * Tolerance

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

