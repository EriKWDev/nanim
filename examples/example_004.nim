import nanim, math, random

proc daily045Scene(): Scene =
  let
    scene = newScene()
    N = 2600
  var colors = colorsFromCoolors("https://coolors.co/f6e8ea-ef626c-22181c-312f2f-84dccf")

  scene.randomize()
  colors.shuffle()

  let bg = colors[0]
  colors.del(0)

  scene.background = proc(scene: Scene) = scene.fill(bg)
  let spiralColor = colors.sample()

  for i in 1..N:
    var circle = newDot(20)

    let
      d = 6 * 2 * PI / N
      r = i/N * 700.0
      angle = i * d
      x = cos(angle) * r
      y = sin(angle) * r

    circle.moveTo(500, 500)
    circle.move(x, y)
    circle.fill(spiralColor)
    scene.add(circle)
    scene.onTrack i:
      scene.sleep(i * 3.0)
      for _ in 1..5:
        scene.play(circle.scaleTo(2.0))
        scene.play(circle.scaleTo(1.0))

  return scene

when isMainModule:
  for _ in 1..15:
    render(daily045Scene)
