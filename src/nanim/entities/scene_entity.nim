
import
  nanim/core,
  nanim/animation


type
  SceneEntity* = ref object of Entity
    scene*: Scene

    paused: bool
    loop: bool

    width*: int
    height*: int


proc init*(sceneEntity: SceneEntity) =
  init(sceneEntity.Entity)
  sceneEntity.paused = false
  sceneEntity.loop = false
  sceneEntity.width = 1920
  sceneEntity.height = 1080


proc newSceneEntity*(userScene: Scene, width: int = 1920, height: int = 1080): SceneEntity =
  new(result)
  result.init()

  result.scene = userScene
  result.scene.debug = false
  result.width = width
  result.height = height

  # discard result.moveTo(-500, 0)


proc newSceneEntity*(sceneCreator: proc(): Scene, width: int = 1920, height: int = 1080): SceneEntity =
  newSceneEntity(sceneCreator(), width, height)


method draw*(sceneEntity: SceneEntity, mainScene: Scene) =
  sceneEntity.scene.context = mainScene.context
  sceneEntity.scene.window = mainScene.window

  sceneEntity.scene.width = sceneEntity.width
  sceneEntity.scene.height = sceneEntity.height
  sceneEntity.scene.frameBufferWidth = sceneEntity.width.int32
  sceneEntity.scene.frameBufferHeight = sceneEntity.height.int32

  let deltaTime = if sceneEntity.paused: 0.0 else: mainScene.deltaTime

  # TODO: Fix issue https://github.com/EriKWDev/nanim/issues/5
  # sceneEntity.scene.time = mainScene.time - deltaTime
  sceneEntity.scene.tick(deltaTime)

  if sceneEntity.loop and sceneEntity.scene.done:
    sceneEntity.scene.time = sceneEntity.scene.restartTime


proc play*(entity: SceneEntity): Tween =
  var interpolators: seq[proc(t: float)]
  let startValue = entity.paused.deepCopy()

  let interpolator = proc(t: float) =
    entity.paused = interpolate(startValue, false, t)

  interpolators.add(interpolator)
  entity.paused = false

  result = newTween(interpolators)

proc start*(entity: SceneEntity): Tween =
  entity.play()

proc pause*(entity: SceneEntity): Tween =
  var interpolators: seq[proc(t: float)]
  let startValue = entity.paused.deepCopy()

  let interpolator = proc(t: float) =
    entity.paused = interpolate(startValue, true, t)

  interpolators.add(interpolator)
  entity.paused = true

  result = newTween(interpolators)

proc stop*(entity: SceneEntity): Tween =
  entity.pause()
