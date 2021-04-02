import nanim


proc multiTrackScene(): Scene =
  let scene = newScene()

  var
    circle = newCircle()
    rectangle = newRectangle()

  discard circle.move(500, 500)
  discard rectangle.move(500, 500)

  scene.add(rectangle, circle)

  scene.wait(1000)
  scene.syncTracks(0, 1, 3, 4)

  scene.onTrack(1):
    scene.wait(500)
    scene.play(circle.move(100, 100))
    scene.play(circle.pscale(3))
    scene.play(circle.rotate(90))
    scene.wait(500)
    scene.play(circle.move(100, 100))
    scene.wait(2000)
    scene.play(circle.move(-100, -300),
               circle.rotate(90),
               circle.pscale(1/3))

  scene.onTrack(3):
    scene.wait(500)
    scene.play(rectangle.move(-200, -200))
    scene.play(rectangle.rotate(-90))
    # scene.startHere() # ! start animation here
    for i in 1..5:
        let m = if i mod 2 == 0: -1.0 else: 1.0
        scene.play(rectangle.move(100 * m, -100 * m),
                rectangle.rotate(-30.0 * i * m))

  scene.onTrack(4):
    let hexagon = newHexagon()

    discard hexagon.move(0, 300)
    scene.add(hexagon)
    scene.wait(1000)
    scene.play(hexagon.move(500, 200),
                hexagon.pscale(4))
    scene.wait(2400)
    scene.play(hexagon.pscale(1/4))

  scene.syncTracks()

  scene.onTrack(1): scene.play(circle.move(100, 100))
  scene.onTrack(3): scene.play(rectangle.move(100, 100))
  scene.onTrack(4): scene.play(hexagon.move(100, -100))

  scene.syncTracks()
  scene.switchToDefaultTrack()
  scene.wait(2000)

  return scene


when isMainModule: render(multiTrackScene)
