<h1 align="center">Nanim</h1>
<p align="center">"Totally not <a href="https://github.com/3b1b/manim/">manim</a> in nim" - Erik</p>
<p align="center">
  <img src="https://github.com/EriKWDev/nanim/actions/workflows/unittests.yaml/badge.svg?branch=main">
</p>


### About
Nanim is an easy-to-use framework to create smooth GPU-accelerated animations that can be previewed live inside a glfw window and, when ready, rendered to videos at an arbitrary resolution and framerate.

### Usage
Create a normal nim program where you create a Nanim Scene. This scene will carry the state of all animations and entities. Here is what a simple scene might look like:
```nim
import nanim

proc testScene(): Scene =
  # Creates a scene-state
  let scene = newScene()

  var
    text = newText("Hello, World!", font="montserrat-thin")
    rect = newSquare()
  
  # We must add our entities to the scene in order for them to be drawn
  scene.add(rect, text)

  # By discarding tweens, we can "set" values without animating the change
  discard text.move(150, 150)
  
  scene.wait(500)
  scene.showAllEntities()
  scene.wait(500)

  # scene.play() and scene.animate() animates any number of tweens and
  # can be used interchangeably
  scene.play(text.move(500, 500),
             rect.move(100, 500),
             rect.rotate(45))

  scene.animate(rect.pscale(3))
  scene.play(rect.setTension(0.6))
  scene.wait(500)

  scene.play(rect.pscale(1/3))

  scene.play(rect.setTension(0),
             rect.rotate(360*2),
             rect.pscale(4))

  scene.wait(500)
  scene.play(rect.move(600), rect.setCornerRadius(30))
  
  # Want to repeat an animation? Simply add a loop!
  for i in 0..5:
    scene.play(rect.move(-20),
               rect.rotate(-300),
               rect.pscale(if i mod 2 == 0: 1.0/10.0 else: 10.0))

  scene.wait(500)
  
  # ..and finally return our scene. Scenes don't have to be created inside a proc/func like
  # this one, but it helps a lot when we want to combine multiple scenes in the future, so
  # it should be considered "best practice".
  return scene


when isMainModule:
  # Finally, call render to render our scene.
  # render(testScene()) works as well.
  render(testScene)

```

The scene can then be run by simply compiling the file like so: `nim c -d:glfwStaticLib -r <file_containing_scene>.nim`. Once your scene is compiled, you can run it either in "live" mode (default), which opens a window and renders the scene in realtime, or you can render it to a video by supplying `--render` after your call to the binary. Here are all the options (keep in mind that it is the last option(s) supplied that takes priority over others):
```
Options:
  -r, --run
    Opens a window with the scene rendered in realtime.
  -v, --video, --render
    Enables video rendering mode. Will output video to renders/final.mp4
  -fullhd, --1080p
    Enables video rendering mode with 1080p settings
  -2k, --1440p
    Enables video rendering mode with 1440p settings
  -4k, --2160p
    Enables video rendering mode with 2160p settings
  -w:WIDTH, --width:WIDTH
    Sets width to WIDTH
  -h:HEIGHT, --height:HEIGHT
    Sets height to HEIGHT
```

### Legal
 - The majority[1] of the source for this project is release under the MIT license. See the `LICENSE` file for details on what this means for distribution.
 - The Montserrat font families used in the examples in the `examples/fonts` directory are used under the OFL and are subject to copyright by The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat). See `examples/fonts/OFL.txt`
 - This project has no association with 3b1b nor ManimCommunity's `manim`, but is indeed inspired by it.

[1]: Some files, like artwork and special entities, are not made public currently. This might change in the future.
