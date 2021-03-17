
import nanim


proc testScene(): Scene =
    let scene = newScene()

    var circle = newCircle(500)

    scene.add(circle)

    scene.wait(2000)
    scene.animate(circle.move(10.0, 10.0))
    scene.wait(2000)

    return scene


when isMainModule:
    render(testScene())
