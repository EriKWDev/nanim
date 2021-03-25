
import nanim


proc testScene(): Scene =
  let scene = newScene()

  var circle1 = newCircle(60)
  var circle2 = newCircle(160)
  var text = newText("Hello, World!", font="montserrat-thin")
  var rect = newSquare()

  scene.add(circle1, circle2, text, rect)

  discard circle1.move(150, 150)
  discard text.move(150, 150)

  scene.wait(500)

  scene.showAllEntities()

  scene.wait(500)

  scene.play(circle1.move(200, 200),
             circle2.move(500, 200),
             text.move(500, 500),
             rect.move(100, 500),
             rect.rotate(45))

  scene.play(circle1.pscale(5),
             circle2.scale(2),
             rect.pscale(3))

  scene.play(rect.setTension(0.6))

  scene.wait(500)

  scene.play(circle1.pscale(1/5),
             circle2.scale(1/2),
             rect.pscale(1/3))

  scene.wait(500)
  scene.play(rect.setTension(0), rect.rotate(360*2), rect.pscale(4))
  scene.play(rect.move(600))

  for i in 0..15:
    scene.play(rect.move(-20),
               rect.rotate(-300),
               rect.pscale(if i mod 2 == 0: 1.0/10.0 else: 10.0),
               rect.setCornerRadius(((i mod 2) + 0.5) * 30.0))

  scene.wait(500)

  return scene


when isMainModule:
  render(testScene, defined(video))
