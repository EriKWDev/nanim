
import nanim


proc weirdScene(): Scene =
  let scene = newScene()

  var
    entity = newCircle()
    entities: seq[Entity] = @[]

  entities.add(entity)
  scene.add(entities)

  discard entity.moveTo(0, 0)
  var tween1 = entity.moveTo(100, 100)
  scene.play(tween1)

  var tween2 = entity.moveTo(500, 500)
  scene.play(tween2)

  var tween3 = entity.moveTo(1000, 1000)
  scene.play(tween3)

  return scene


when isMainModule:
  render(weirdScene)