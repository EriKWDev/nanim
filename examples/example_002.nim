import nanim, nanovg, algorithm


proc daily088Scene(colors: var seq[Color]): Scene =
  let scene = newScene()
  scene.setBackgroundColor(colors[0])
  colors.del(0)

  let
    offset = 500.0
    widths = @[
      10.0,
      50.0,
      20.0,
      80.0,
      60.0,
      130.0,
      40.0,
      10.0
    ]

  defaultEasing = easeOutElastic
  defaultDuration = 2300.0

  for i, color in colors:
    let l = newLine(-200.0, 0.0, 1200.0, 0.0)

    l.fill(newColor("#0000000"))
    l.stroke(color, widths[0])
    l.moveTo(0.0, i * widths[0] + offset)

    scene.add(l)

    scene.onTrack i + 100:
      scene.sleep(i * 100.0 + 500.0)
      for width in widths[1..^1]:
        scene.play(l.stroke(color, width), l.moveTo(0.0, i * width + offset))
        scene.sleep(200.0)

  return scene

when isMainModule:
  var colors = colorsFromCoolors("https://coolors.co/5bc0eb-fde74c-9bc53d-c3423f-211a1e")

  colors.rotateLeft(4)
  var currentColors = colors.deepCopy()
  render(daily088Scene(currentColors))

