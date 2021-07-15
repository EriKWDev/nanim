import nanim

proc daily092Scene(): Scene =
  let scene = newScene()

  var colors = colorsFromCoolors("https://coolors.co/161032-ffc53a-e06d06")
  scene.randomize()
  colors.shuffle()
  let bg = colors[0]
  colors.del(0)
  scene.setBackgroundColor(bg)

  let
    N = 13
    d = 1000.0/N

  let
    height = 300.0
    l = newLine(0.0, 0.0, 0.0, height)
    color = colors.sample()

  l.moveTo(500.0, 350.0)
  scene.add(l)
  l.fill(newColor("#00000000"))
  l.stroke(color)

  let
    r = d/2.0
    dot = newDot(r)

  dot.moveDown(height - r/2)
  dot.fill(color)
  dot.stroke(newColor("#00000000"), 0.0)
  l.add(dot)

  l.rotate(45.0)

  scene.onTrack 3:
    for _ in 0..6:
      scene.play(l.rotate(-90.0))
      scene.play(l.rotate(90.0))

  scene.onTrack 2:
    let a = newArc(400.0, 0.0, 0.0)
    a.fill(newColor("#00000000"))
    a.stroke(color, 8.0)
    a.moveTo(500.0, 500.0)
    scene.add(a)

    a.endAngleTo(0.5)
    for j in 1..N:
      scene.play(a.endAngleTo(360.0/N * j))
    scene.play(a.endAngleTo(0.5))


  return scene

when isMainModule:
  render(daily092Scene)
