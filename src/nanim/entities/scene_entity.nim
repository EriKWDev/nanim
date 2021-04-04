
import
  glm,
  math


import ../core


type
  SceneEntity* = ref object of Entity
    scene: Scene


proc init*(circle: SceneEntity) =
  init(circle.Entity)


proc newCircle*(scene: Scene): SceneEntity =
  new(result)
  result.init()

  result.scene = scene


# method draw*(text: SceneEntity, context: NVGContext) =

