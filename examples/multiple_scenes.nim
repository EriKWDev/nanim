
import nanim, nanovg


proc extraScene(): Scene =
  let scene = newScene()
  scene.background =
    proc(scene: Scene) =
      scene.fill(rgb(255, 255, 255))

  var entity = newSquare()
  discard entity.scale(3)

  discard entity.moveTo(0, 500)

  scene.add(entity)
  scene.wait(200)
  scene.play(entity.moveTo(500, 500))
  scene.wait(200)
  scene.play(entity.rotate(360))
  scene.sleep()

  return scene


proc mainScene(): Scene =
  let scene = newScene()

  for i in 1..10:
    scene.onTrack i:
      var subScene1 = newSceneEntity(extraScene, 100, 500)
      discard subScene1.pause()
      discard subScene1.moveTo((i - 1) * 100.0, 250)
      scene.add(subScene1)

      scene.wait(500 + i * 100.0)
      scene.play(subScene1.play())
      scene.wait(1500)
      scene.play(subScene1.pause())

  scene.switchToDefaultTrack()
  scene.syncTracks()
  scene.wait(500)

  return scene


when isMainModule:
  render(mainScene)
