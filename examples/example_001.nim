
import nanim


proc testScene(): Scene =
    let scene = newScene()

    var circle1 = newCircle(60)
    var circle2 = newCircle(60)

    var text = newText("Hello, World!")

    var rect = newSquare()

    scene.add(circle1, circle2, text, rect)

    scene.wait(1000)
    scene.play(circle1.move(200, 200),
               circle2.move(500, 200),
               text.move(500, 500),
               rect.move(100, 500),
               rect.rotate(45))

    scene.wait(1000)
    scene.play(circle1.pscale(2),
               circle2.scale(2),
               rect.pscale(3))

    scene.wait(1000)
    scene.play(rect.setTension(0.6))

    scene.wait(1000)

    return scene


when isMainModule:
    render(testScene())
