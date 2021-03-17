
import nanim


proc testScene(): Scene =
    let scene = newScene()

    var circle = newCircle(50)

    scene.add(circle)

    scene.wait(2000)
    scene.animate(circle.move(50.0, 20.0))
    scene.wait(2000)

    return scene


when isMainModule:
    render(testScene())
