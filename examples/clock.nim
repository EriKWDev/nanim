import nanim


proc scene039(): Scene =
  let
    scene = newScene()
    colors = colorsFromCoolors("https://coolors.co/fffffa-515052-000103-333138-ff312e")

  scene.background = proc(scene: Scene) = scene.fill(colors[4])

  let centralDot = newDot(8)
  centralDot.fill(colors[0])
  centralDot.moveTo(500, 500)
  scene.add(centralDot)


  for i in 0..12:
    var d = newLine(0, -360, 0, -400)
    d.moveTo(500, 500)
    d.stroke(colors[0], 6)
    d.rotate(i * 360.0/12.0)
    scene.add(d)

  var line1 = newLine(0.0, 0.0, 0.0, -120.0)
  line1.stroke(colors[0], 8)
  line1.moveTo(500, 500)

  var line2 = newLine(0.0, 0.0, 0.0, -290.0)
  line2.stroke(colors[0], 6)
  line2.moveTo(500, 500)

  # var line3 = newLine(0.0, 0.0, 0.0, -350.0)
  # line3.stroke(colors[0], 4)
  # line3.moveTo(500, 500)

  scene.add(line1, line2)
  defaultEasing = sigmoid4

  scene.onTrack 1:
    scene.sleep(500)
    for _ in 1..12:
      scene.play(line2.rotate(360).with(duration=2400))
      scene.play(line1.rotate(360/12.0).with(duration=1400, easing=easeOutElastic))

  scene.onTrack -1:
    let t = newDot(8)
    t.move(0, -440)
    t.fill(colors[0])
    centralDot.add(t)
    scene.sleep(500)
    scene.play(centralDot.rotate(360.0).with(duration=(2400 + 1400)*12, easing=linear))


  return scene


when isMainModule:
  render(scene039)

