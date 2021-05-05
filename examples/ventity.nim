import nanim, nanovg


proc ventityScene(): Scene =
  let
    scene = newScene()
    testPath = "M 230 80 A 45 45, 0, 1, 0, 275 125 L 275 80 Z"
    testPathHeart = "M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z"
    testPath2 = "M2,2 L8,2 L2,5 L8,5 L2,8 L8,8"
    testPath3 = "M2,8 L5,2 L8,8"
    testPath4 = "M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80"
    testPath5 = "M 10 80 Q 52.5 10, 95 80 T 180 80"
    testPath6 = "M 10 10 H 90 V 90 H 10 Z"
    strokeColor = rgb(0, 200, 200)
    strokeColor2 = rgb(100, 100, 200)

  var a = newVEntityFromPathString(testPath6)

  a.moveTo(300, 300)
  a.stroke(strokeColor, 5.0)
  a.fill(rgba(0,0,0,0))
  a.pscale(3.0)

  var b = newVEntityFromPathString(testPath5)

  b.moveTo(300, 500)
  b.stroke(strokeColor2, 5.0)
  b.fill(rgba(0,0,0,0))
  b.pscale(3.0)

  scene.add(a, b)

  return scene


when isMainModule:
  render(ventityScene)