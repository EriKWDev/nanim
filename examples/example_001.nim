import nanim

proc daily068Scene(): Scene =
  let scene = newScene()

  var colors = colorsFromCoolors("https://coolors.co/33658a-86bbd8-758e4f-f6ae2d-f26419")
  scene.randomize()

  defaultDuration = 2400.0

  colors.shuffle()
  let bg = colors[0]
  colors.del(0)
  scene.setBackgroundColor(bg)


  let
    N = 15
    d = 1000.0/N
    s = 0

  defaultEasing = linear

  var i = 0
  for y in s..N-s:
    var color = colors[y mod len(colors)]
    for x in s..N-s:
      inc i

      let even2 = x mod 2 == 0

      let a = newArc(d/2, 0.0, 180.0)

      a.fill(newColor("#00000000"))
      a.stroke(color, d/10.0)
      a.moveTo(x * d, y * d)
      scene.add(a)

      if not even2:
        a.rotate(180)
        a.stretch(-1)


      scene.onTrack i:
        for _ in 0..3:
          if even2:
            scene.play(a.endAngleTo(0), a.fadeOut())
            scene.play([a.endAngleTo(180), a.startAngleTo(180), a.fadeIn()].with(duration=0))
            scene.play(a.startAngleTo(0))
          else:
            scene.play([a.endAngleTo(180), a.startAngleTo(180), a.fadeIn()].with(duration=0))
            scene.play(a.startAngleTo(0))
            scene.play(a.endAngleTo(0), a.fadeOut())


  return scene

when isMainModule:
  # for _ in 0..10:
  #   render(daily068Scene)

  render(daily068Scene)