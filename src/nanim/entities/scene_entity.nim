
import
  nanim/core,
  nanim/animation


type
  SceneEntity* = ref object of Entity
    scene*: Scene

    paused: bool
    loop: bool


proc init*(sceneEntity: SceneEntity) =
  init(sceneEntity.Entity)
  sceneEntity.paused = false
  sceneEntity.loop = false


proc newSceneEntity*(userScene: Scene): SceneEntity =
  new(result)
  result.init()

  result.scene = userScene.deepCopy()


proc newSceneEntity*(sceneCreator: proc(): Scene): SceneEntity = newSceneEntity(sceneCreator())


method draw*(sceneEntity: SceneEntity, mainScene: Scene) =
  sceneEntity.scene.context = mainScene.context
  sceneEntity.scene.window = mainScene.window

  sceneEntity.scene.width = mainScene.width
  sceneEntity.scene.height = mainScene.height

  sceneEntity.scene.frameBufferWidth = mainScene.frameBufferWidth
  sceneEntity.scene.frameBufferHeight = mainScene.frameBufferHeight

  if sceneEntity.paused:
    sceneEntity.scene.deltaTime = 0
  else:
    sceneEntity.scene.deltaTime = mainScene.deltaTime

  sceneEntity.scene.time = mainScene.time
  sceneEntity.scene.tick()

  if sceneEntity.loop and sceneEntity.scene.done:
    sceneEntity.scene.time = sceneEntity.scene.restartTime


func play*(entity: SceneEntity): Tween =
  var interpolators: seq[proc(t: float)]
  let startValue = entity.paused.deepCopy()

  let interpolator = proc(t: float) =
    entity.paused = interpolate(startValue, false, t)

  interpolators.add(interpolator)
  entity.paused = false

  result = newTween(interpolators)


func start*(entity: SceneEntity): Tween =
  entity.play()

func pause*(entity: SceneEntity): Tween =
  var interpolators: seq[proc(t: float)]
  let startValue = entity.paused.deepCopy()

  let interpolator = proc(t: float) =
    entity.paused = interpolate(startValue, true, t)

  interpolators.add(interpolator)
  entity.paused = true

  result = newTween(interpolators)


func stop*(entity: SceneEntity): Tween =
  entity.pause()
