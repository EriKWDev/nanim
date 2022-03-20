import nanim, nanovg

proc scene051(): Scene =
  let scene = newScene()

  let
    bg = newColor("#B3D89C")
    color = newColor("#D0EFB1")

  scene.setBackgroundColor(bg)

  for i in 1..10:
    let d = newArc(i * 40.0, 0, 45)
    d.moveTo(500, 500)
    d.fill(white(0))
    d.stroke(color, 20.0)
    scene.add(d)

    scene.onTrack i:
      scene.sleep(i * defaultDuration/8.0)
      for n in 1..(360/45).int:
        scene.play(d.rotate(45).with(easing=easeOutElastic, duration=defaultDuration*2))

  return scene

when isMainModule:
  render(scene051)

