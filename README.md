<h1 align="center">Nanim</h1>
<p align="center">"Totally not <a href="https://github.com/3b1b/manim/">manim</a> in nim" - Erik</p>

### About
Nanim is an easy-to-use framework to create smooth GPU-accelerated animations that can be previewed live inside a glfw window and, when ready, rendered to videos at an arbetrary resolution and framerate.

### Usage
Create a normal nim program where you create a Nanim Scene. This scene will carry the state of all animations and entities. Here is what a simple scene might look like:
```nim
import nanim

proc testScene(): Scene =
  let scene = newScene()

  var
    text = newText("Hello, World!", font="montserrat-thin")
    rect = newSquare()

  scene.add(rect, text)
  
  discard text.move(150, 150)

  scene.wait(500)
  scene.showAllEntities()
  scene.wait(500)

  scene.play(text.move(500, 500),
             rect.move(100, 500),
             rect.rotate(45))

  scene.play(rect.pscale(3))
  scene.play(rect.setTension(0.6))
  scene.wait(500)

  scene.play(rect.pscale(1/3))

  scene.play(rect.setTension(0),
             rect.rotate(360*2),
             rect.pscale(4))

  scene.wait(500)
  scene.play(rect.move(600), rect.setCornerRadius(30))

  for i in 0..5:
    scene.play(rect.move(-20),
               rect.rotate(-300),
               rect.pscale(if i mod 2 == 0: 1.0/10.0 else: 10.0))

  scene.wait(500)

  return scene


when isMainModule:
  when defined(release):
    render1440p(testScene)
  else:
    render(testScene)

```

The scene can then be run by simply compiling the file like so: `nim c -d:glfwStaticLib -r myScene.nim`

### Legal
 - The source for this project is release under the MIT license. See the `LICENSE` file for details on what this means for distribution.
 - The Montserrat font families are used under the OFL and are subject to copyright by The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat).
 - This project has no association with 3b1b nor ManimCommunity's `manim`, but is indeed inspired by it.
