
import nanim


when isMainModule:
  let scene = newScene()

  var circle = newCircle()

  scene.add(circle)

  scene.show(circle)
  scene.wait(500)
  scene.play(circle.move(100, 100))
  scene.wait(500)

  render(scene)