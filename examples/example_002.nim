import nanim


proc rectangleScene(): Scene =
  let scene = newScene()

  var
    circle = newCircle()
    rectangle = newRectangle()

  discard circle.move(500, 500)
  discard rectangle.move(500, 500)

  scene.add(rectangle)
  scene.add(circle)

  scene.switchTrack(1)
  scene.wait(500)
  scene.play(circle.move(100, 100))
  scene.play(circle.pscale(3))
  scene.play(circle.rotate(90))
  scene.wait(500)
  scene.play(circle.rotate(90))
  scene.wait(500)


  scene.switchTrack(3)
  scene.wait(500)
  scene.play(rectangle.move(-100, -100))
  scene.play(rectangle.pscale(3))
  scene.play(rectangle.rotate(-90))
  scene.wait(1000)

  return scene


when isMainModule:
  render(rectangleScene)