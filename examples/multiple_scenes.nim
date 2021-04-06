
import nanim


proc extraScene(): Scene =
  let scene = newScene()
  var entity = newRectangle()

  scene.add(entity)
  scene.play(entity.moveTo(500, 500))
  scene.wait(500)

  return scene


proc mainScene(): Scene =
  let scene = newScene()

  var subScene1 = newSceneEntity(extraScene)
  discard subScene1.pause()
  scene.add(subScene1)

  scene.wait(500)
  scene.play(subScene1.play())
  scene.wait(1500)
  scene.play(subScene1.pause())
  scene.wait(500)

  return scene


when isMainModule:
  render(mainScene)
