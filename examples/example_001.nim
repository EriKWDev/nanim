
import lenientops, nanim


proc testScene(): Scene =
    let scene = newScene()

    var circles: seq[Entity]

    for i in 0..10:
        circles.add(newCircle(50))

    scene.add(circles)

    scene.wait()

    for i, circle in circles:
        scene.play(circle.move(150.0 + i * 10.0, 220.0))
        scene.wait(50)

    return scene


when isMainModule:
    render(testScene())
