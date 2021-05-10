
import
  unittest,
  nanim,
  tables,
  utils,
  nanovg,
  random


suite "Scene & Entity tests":
  test "Simple Scene with Entity.move()":
    proc simpleScene(): Scene =
      let scene = newScene()

      var circle = newCircle()
      scene.add(circle)

      let oldPosition = circle.position

      let circleMoveTween = circle.move(100, 100)
      check circle.position.x == oldPosition.x + 100.0
      check circle.position.y == oldPosition.y + 100.0

      checkpoint("move() correctly moves entity")

      check circleMoveTween.interpolators.len() > 0

      for interpolator in circleMoveTween.interpolators: interpolator(0.0)

      check circle.position.x ~= oldPosition.x
      check circle.position.y ~= oldPosition.y

      checkpoint("move() tween correctly evaluates at alpha 0.0")

      for interpolator in circleMoveTween.interpolators: interpolator(1.0)

      check circle.position.x ~= (oldPosition.x + 100.0)
      check circle.position.y ~= (oldPosition.y + 100.0)

      checkpoint("move() tween correctly evaluates at alpha 1.0")

      return scene

    discard simpleScene()


  test "Simple Scene with Entity.rotate()":
    proc simpleScene(): Scene =
      let scene = newScene()

      var bestagon = newBestagon()
      scene.add(bestagon)

      let beginningRotation = bestagon.rotation
      discard bestagon.rotate(180, amDegrees)
      check bestagon.rotation ~= (beginningRotation + PI)

      checkpoint("rotate() correctly rotates entity by degrees")

      let oldRotation = bestagon.rotation
      discard bestagon.rotate(2.0 * PI, amRadians)
      check bestagon.rotation ~= (oldRotation + 2.0 * PI)

      checkpoint("rotate() correctly rotates entity by radians")

      return scene

    discard simpleScene()


  test "Scene Initializing a Bunch of Entities":
    proc simpleScene(): Scene =
      let scene = newScene()

      var entities = @[newCircle(), newSquare(), newRectangle(), newText(), newPentagon(), newHexagon(), newHeptagon(), newEngon(100)]
      checkpoint("a bunch of entities could be initialized")

      for entity in entities:
        scene.add(entity)
      check scene.entities.len() == entities.len()
      checkpoint("entities could be added to scene one by one")

      scene.add(entities)
      check scene.entities.len() == entities.len() * 2
      checkpoint("entities could be added to scene in bulk")

      return scene

    discard simpleScene()


  test "Scene Stagger":
    let scene = newScene()

    var
      t1 = newTween(@[], linear, 1000.0)
      t2 = newTween(@[], linear, 1000.0)
      t3 = newTween(@[], linear, 1000.0)
      t4 = newTween(@[], linear, 1000.0)
      t5 = newTween(@[], linear, 1000.0)

    let
      tweens = [t1, t2, t3, t4, t5]
      staggering = 200.0
      duration = 2000.0

    scene.stagger(staggering, tweens.with(duration=duration))

    var last = 0.0
    let toCheck = scene.tweenTracks[scene.currentTweenTrackId].tweens

    for i in 1..high(toCheck):
      check toCheck[i].startTime - last ~= staggering
      check toCheck[i].duration ~= duration

      last = toCheck[i].startTime


  test "Scene.play() / Scene.animate()":
    let scene = newScene()

    var a = newDot()

    scene.play(a.move(10))
    scene.animate(a.move(10))
    scene.play([a.move(10), a.move(10)])
    scene.animate([a.move(10), a.move(10)])

    var ts = @[@[a.move(10), a.move(10)], @[a.move(10), a.move(10)]]

    scene.play(ts)
    scene.animate(ts)
    scene.play(ts, ts, ts)
    scene.animate(ts, ts, ts)


  test "Scene Fonts Loading Automatically Initiated":
    let
      scene = newScene()
      oldFontsLen = len(scene.fontsToLoad)

    scene.fontsToLoad = @[]
    scene.loadDefaultFonts()
    check len(scene.fontsToLoad) == oldFontsLen

suite "Easings, Tweens and Interpolations":
  test "Easings":
    check linear(0.1) ~= 0.1
    check linear(1.0) ~= 1.0

    check sigmoid4(0.0) ~= 0.0
    check sigmoid4(1.0) ~= 1.0
    check sigmoid4(0.5) ~= 0.5

    check smoothOvershoot(0.0) ~= 0.0
    check smoothOvershoot(1.0) ~= 1.0

    let easings = [linear, sigmoid2, sigmoid3, sigmoid4, sigmoid5, smoothOvershoot, inQuad, outQuad, inExpo, outExpo, easeOutElastic]

    for easingFunction in easings:
      check (easingFunction(0.0) ~= 0.0) or (easingFunction(0.0) < 0.01 and easingFunction(1.0) > -0.01)
      check (easingFunction(1.0) ~= 1.0) or (easingFunction(1.0) > 0.99 and easingFunction(1.0) < 1.01)
      randomize()

      for i in 0..100:
        var t = rand(0.0..1.0)
        discard easingFunction(t)


  test "Interpolations":
    check interpolate(0.0, 1.0, 0.5) ~= 0.5
    check interpolate(100.0, 150.0, 0.5) ~= 125.0
    check interpolate(-100.0, 100.0, 0.5) ~= 0.0

    check interpolate(1.0, -1.0, 1.0) ~= -1.0
    check interpolate(-1.0, 1.0, 1.0) ~= 1.0

    check interpolate(false, true, 1.0) == true
    check interpolate(false, true, 0.2) == false
    check interpolate(false, true, 0.7) == true
    check interpolate(false, true, 0.0) == false

    let
      fromColor = rgb(0,0,0)
      toColor = rgb(255,255,255)
      interpolatedColor00 = interpolate(fromColor, toColor, 0.0)
      interpolatedColor10 = interpolate(fromColor, toColor, 1.0)

    check interpolatedColor00.r ~= fromColor.r
    check interpolatedColor00.g ~= fromColor.g
    check interpolatedColor00.b ~= fromColor.b
    check interpolatedColor00.a ~= fromColor.a

    check interpolatedColor10.r ~= toColor.r
    check interpolatedColor10.g ~= toColor.g
    check interpolatedColor10.b ~= toColor.b
    check interpolatedColor10.a ~= toColor.a

    var
      points1 = @[vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0)]
      points2 = @[vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0)]

      interpolatedPoints00 = interpolate(points1, points2, 0.0)
      interpolatedPoints05 = interpolate(points1, points2, 0.5)
      interpolatedPoints10 = interpolate(points1, points2, 1.0)

    check interpolatedPoints00[0] ~= vec3(0.0, 0.0, 0.0)
    check interpolatedPoints00[1] ~= vec3(1.0, 1.0, 1.0)
    check interpolatedPoints00[2] ~= vec3(0.0, 0.0, 0.0)

    check interpolatedPoints05[0] ~= vec3(0.5, 0.5, 0.5)
    check interpolatedPoints05[1] ~= vec3(0.5, 0.5, 0.5)
    check interpolatedPoints05[2] ~= vec3(0.5, 0.5, 0.5)

    check interpolatedPoints10[0] ~= vec3(1.0, 1.0, 1.0)
    check interpolatedPoints10[1] ~= vec3(0.0, 0.0, 0.0)
    check interpolatedPoints10[2] ~= vec3(1.0, 1.0, 1.0)


    var
      points21 = @[vec3(0.0, 0.0, 0.0)]
      points22 = @[vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0)]

    check interpolate(points21, points22, 0.5)[1] ~= vec3(0.5, 0.5, 0.5)
    check interpolate(points22, points21, 0.5)[1] ~= vec3(0.5, 0.5, 0.5)


  test "Simple Tracks":
    let scene = newScene()
    check scene.tweenTracks.len() == 1

    var
      circle = newCircle()
      rectangle = newRectangle()

    scene.add(circle, rectangle)
    scene.play(circle.move(100))
    scene.wait(2500)

    scene.switchTrack(2)
    scene.play(rectangle.move(100))
    check scene.tweenTracks.len() == 2

    scene.wait(1500)

    scene.syncTracks()
    check scene.getLatestTween().duration ~= 1000.0


  test "Discarded Tweens Should Still Set Values":
    var entity = newPentagon()
    discard entity.setCornerRadius(25.0)
    check entity.cornerRadius ~= 25.0

    discard entity.setCornerRadius(0.0)
    check entity.cornerRadius ~= 0.0

    entity.setCornerRadius(10.0)
    check entity.cornerRadius ~= 10.0


  test "Tween Options":
    var circle = newCircle()
    let tweens = [circle.moveTo(0, 0), circle.scale(10)].with(duration=100.0)
    for tween in tweens:
      check tween.duration ~= 100.0

    let easings = [linear, bounceIn, smoothOvershoot, outQuad]

    for easing in easings:
      let
        goalDuration = rand(0.0..3000.0)
        moveTween = circle.moveTo(100.0, 0).with(easing=easing, duration=goalDuration)
      check moveTween.easing == easing
      check moveTween.duration ~= goalDuration


  test "Simple Tweens 1":
    var entity = newBestagon()

    let
      oldPosition = entity.position
      moveTween1 = entity.move(100, 200)

    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    moveTween1.evaluate(0.0)
    check entity.position ~= oldPosition

    moveTween1.evaluate(defaultDuration)
    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    let
      moveTween2 = entity.move(100, 100)
      tweenTrack = newTweenTrack()

    check entity.position ~= (oldPosition + vec3(100.0 + 100.0, 200.0 + 100.0, 0.0))

    moveTween2.startTime = defaultDuration
    tweenTrack.add(moveTween1, moveTween2)

    tweenTrack.evaluate(0)
    check entity.position ~= oldPosition

    tweenTrack.evaluate(defaultDuration)
    check entity.position ~= (oldPosition + vec3(100.0, 200.0, 0.0))

    tweenTrack.evaluate(defaultDuration*2)
    check entity.position ~= (oldPosition + vec3(100.0 + 100.0, 200.0 + 100.0, 0.0))


  test "Simple Tweens 2":
    var entity = newRectangle()

    discard entity.moveTo(100, 100)
    check entity.position ~= vec2(100.0, 100.0)

    let tween1 = entity.moveTo(500, 500)
    check entity.position ~= vec2(500.0, 500.0)

    tween1.evaluate(0)
    check entity.position ~= vec2(100.0, 100.0)

    tween1.execute(1)
    check entity.position ~= vec2(500.0, 500.0)
    tween1.execute(0)
    check entity.position ~= vec2(100.0, 100.0)
    tween1.execute(1)
    check entity.position ~= vec2(500.0, 500.0)
    tween1.execute(0)
    check entity.position ~= vec2(100.0, 100.0)


  test "Track Evaluation":
    var
      track = newTweenTrack()
      entity = newCircle()

    discard entity.moveTo(0, 0)
    check entity.position ~= vec2(0.0, 0.0)

    let tween1 = entity.move(100, 100)
    check entity.position ~= vec2(100.0, 100.0)
    tween1.startTime = 0.0
    tween1.duration = 1000.0
    track.add(tween1)

    let tween2 = entity.moveTo(500, 500)
    check entity.position ~= vec2(500.0, 500.0)
    tween2.startTime = 1000.0
    tween2.duration = 1000.0
    track.add(tween2)

    let tween3 = entity.moveTo(1000, 1000)
    check entity.position ~= vec2(1000.0, 1000.0)
    tween3.startTime = 2000.0
    tween3.duration = 1000.0
    track.add(tween3)


    track.evaluate(0.0)
    check entity.position ~= vec2(0.0, 0.0)
    track.evaluate(1000.0)
    check entity.position ~= vec2(100.0, 100.0)
    track.evaluate(2000.0)
    check entity.position ~= vec2(500.0, 500.0)
    track.evaluate(3000.0)
    check entity.position ~= vec2(1000.0, 1000.0)

suite "Styles & Colors":
  test "Style Initialization":
    let style = newStyle(opacity=0.5, strokeWidth=30)

    check style.opacity ~= 0.5
    check style.strokeWidth ~= 30


  test "Style Copying With Modifications":
    let style0 = newStyle(opacity=1.0, strokeWidth=10)
    check style0.strokeWidth ~= 10
    check style0.opacity ~= 1.0

    let style1 = style0.copyWith(opacity=0.5, strokeWidth=30)
    check style0.strokeWidth ~= 10
    check style0.opacity ~= 1.0
    check style1.opacity ~= 0.5
    check style1.strokeWidth ~= 30

    let style2 = style1.copyWith(opacity=1.0)
    check style0.strokeWidth ~= 10
    check style0.opacity ~= 1.0
    check style1.opacity ~= 0.5
    check style1.strokeWidth ~= 30
    check style2.opacity ~= 1.0
    check style2.strokeWidth ~= 30


  test "Style Tweens":
    let style = newStyle(opacity=0.9, strokeWidth=5)

    let entity = newCircle()
    discard entity.paint(style)
    check entity.style.opacity ~= 0.9

    discard entity.fadeTo(0.5)
    check entity.style.opacity ~= 0.5
    discard entity.fadeIn()
    check entity.style.opacity ~= 1.0

    let style2 = newStyle(strokeWidth=30)

    check entity.style.strokeWidth ~= 5
    let style1To2Tween = entity.paint(style2)
    check entity.style.strokeWidth ~= 30


    style1To2Tween.execute(0.0)
    check entity.style.strokeWidth ~= 5
    style1To2Tween.execute(1.0)
    check entity.style.strokeWidth ~= 30


  test "Color Parsing":
    let color1 = newColor("#FFFFFFFF")
    check color1.r ~= 1.0
    check color1.g ~= 1.0
    check color1.b ~= 1.0
    check color1.a ~= 1.0

    let color2 = newColor("#2c6494")
    check color2.r * 255 ~= 44.0
    check color2.g * 255  ~= 100.0
    check color2.b * 255  ~= 148.0
    check color2.a ~= 1.0

    let color3 = newColor("rgb(44, 100, 148)")
    check color3.r * 255 ~= 44.0
    check color3.g * 255  ~= 100.0
    check color3.b * 255  ~= 148.0
    check color3.a ~= 1.0

    let color4 = newColor("rgba(44, 100, 148, 0.5)")
    check color4.r * 255 ~= 44.0
    check color4.g * 255  ~= 100.0
    check color4.b * 255  ~= 148.0
    check color4.a ~= 0.5

    let color5 = newColor("thisisnotavalidcolorformat")
    check color5.r ~= 0.0
    check color5.g  ~= 0.0
    check color5.b  ~= 0.0
    check color5.a ~= 0.0

    let coolorColors1 = colorsFromCoolors("https://coolors.co/db5461-ffd9ce-593c8f-8ef9f3-171738")
    check len(coolorColors1) == 5

    let coolorColors2 = colorsFromCoolors("https://coolors.co/FFFFFF-000000")
    check len(coolorColors2) == 2
    check coolorColors2[0].r ~= 1.0
    check coolorColors2[0].g ~= 1.0
    check coolorColors2[0].b ~= 1.0
    check coolorColors2[0].a ~= 1.0
    check coolorColors2[1].r ~= 0.0
    check coolorColors2[1].g ~= 0.0
    check coolorColors2[1].b ~= 0.0
    check coolorColors2[1].a ~= 1.0


  test "Color Interpolation":
    let
      colorA = newColor("#000000")
      colorB = newColor("#FFFFFF")
      colorC = rgb(0.5, 0.5, 0.5)

    check interpolate(colorA, colorB, 0.0) ~= colorA
    check interpolate(colorA, colorB, 0.5) ~= colorC
    check interpolate(colorA, colorB, 1.0) ~= colorB

suite "SVG, Vector Entities and Vector Utilities":
  test "Point Equality":
    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0)) == true
    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0)) == false
    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(0.0, toleranceForPointEquality, 0.0)) == true
    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(0.0, toleranceForPointEquality*2, 0.0)) == false

    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0),
                                   vec3(0.0, 0.0, toleranceForPointEquality),
                                   vec3(0.0, toleranceForPointEquality, 0.0),
                                   vec3(toleranceForPointEquality, 0.0, 0.0)) == true

    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(0.0, toleranceForPointEquality, toleranceForPointEquality)) == false
    check arePointsConsideredEqual(vec3(0.0, 0.0, 0.0), vec3(toleranceForPointEquality, toleranceForPointEquality, toleranceForPointEquality)) == false


suite "Other":
  test "Entity Extents":
    let
      square = newSquare(10)
      entityExtents = extents(square)

    check entityExtents.topLeft ~= vec2[float](-5, -5)
    check entityExtents.topRight ~= vec2[float](5, -5)
    check entityExtents.bottomLeft ~= vec2[float](-5, 5)
    check entityExtents.bottomRight ~= vec2[float](5, 5)

    check entityExtents.height ~= 10
    check entityExtents.width ~= 10
