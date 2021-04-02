
import nanim


when isMainModule:
  let scene = newScene()

  var circle = newCircle()

  scene.add(circle)

  scene.wait(500)
  scene.show(circle)
  scene.wait(500)
  scene.play(circle.moveTo(600, 600))
  scene.play(circle.moveTo(500, 500))
  scene.wait(500)

  render(scene)