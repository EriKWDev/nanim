
import nanim, nanovg


proc colorScene(): Scene =
  let scene = newScene()
  scene.background =
    proc(s: Scene) =
      s.fill(rgb(10, 10, 20))

  var bestagon = newBestagon()

  scene.add(bestagon)

  scene.wait(500)
  scene.play(bestagon.moveTo(500, 500), bestagon.pscale(3))
  scene.wait(500)
  let originalPaint = bestagon.style.deepCopy()

  scene.play(bestagon.fill(rgb(155, 100, 200)))
  scene.wait(500)
  scene.play(bestagon.fill(rgb(55, 255, 200)),
             bestagon.stroke(rgb(25, 250, 190)),
             bestagon.setTension(0.8))

  scene.wait(500)
  scene.play(bestagon.paint(bluePaint),
             bestagon.setTension(0.0))
  scene.wait(500)
  scene.play(bestagon.paint(defaultPaint))
  scene.startHere() # ! scene.startHere()
  scene.sleep(400)
  scene.play(bestagon.paint(bluePaint))
  scene.play(bestagon.paint(noisePaint),
             bestagon.setTension(0.8))
  scene.play(bestagon.move(100),
             bestagon.rotate(180),
             bestagon.pscale(0.5))
  scene.sleep(500)
  scene.play(bestagon.setTension(0.0))

  scene.onTrack(2):
    var rect = newRectangle()
    scene.add(rect)

    discard rect.paint(originalPaint)
    discard rect.pscale(4)
    scene.play(rect.moveTo(0, 500), rect.rotate(360))

    for i in 0..13:
      scene.play(rect.move(80, 0), rect.rotate(45))

  scene.syncTracks()
  scene.wait(500)

  return scene


when isMainModule:
  render(colorScene)
