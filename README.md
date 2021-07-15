<h1 align="center">Nanim</h1>
<p align="center">"Totally not <a href="https://github.com/3b1b/manim/">manim</a> in nim" - Erik</p>
<p align="center">
  <img src="https://github.com/EriKWDev/nanim/actions/workflows/unittests.yaml/badge.svg?branch=main">
  <img src="https://github.com/EriKWDev/nanim/actions/workflows/unittests_devel.yaml/badge.svg?branch=main">
</p>


### About
Nanim is an easy-to-use framework to create smooth GPU-accelerated animations that can be previewed live inside a glfw window and, when ready, rendered to videos at an arbitrary resolution and framerate.

### What can be done using Nanim?
I have a series of animations made using nanim posted to my [Instagram Page](https://www.instagram.com/erikwdev/). Some of them include:

|![Bricks](https://user-images.githubusercontent.com/19771356/116243662-74530500-a767-11eb-8e0f-214a2034266e.gif)|![Triangle Ball](https://user-images.githubusercontent.com/19771356/116243464-4372d000-a767-11eb-88d9-449110c1a8a2.gif)|![Dot Attack](https://user-images.githubusercontent.com/19771356/116243885-b3815600-a767-11eb-9055-e763dd54515a.gif)|
|--|--|--|
|![Lots o' dots](https://user-images.githubusercontent.com/19771356/116244643-6782e100-a768-11eb-99c4-b0be68d89051.gif)|![Daily Art](https://user-images.githubusercontent.com/19771356/116244886-a2851480-a768-11eb-9d30-fb2295cbe490.gif)|![Web](https://user-images.githubusercontent.com/19771356/116245061-d6f8d080-a768-11eb-9c2e-9ce443083a37.gif)|

I also post art to my [OpenSea Page](https://opensea.io/accounts/ErikWDev) where they can be bought as NFT:s.

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

The scene can then be run by simply compiling the file like so: `nim c -r <file_containing_scene>.nim`. Once your scene is compiled, you can run it either in "live" mode (default), which opens a window and renders the scene in realtime, or you can render it to a video by supplying `--render` after your call to the binary. Here are all the options (keep in mind that it is the last option(s) supplied that takes priority over others):
```
Options:
  -r, --run
    Opens a window with the scene rendered in realtime.
  -v, --video, --render
    Enables video rendering mode. Will output video to renders/final.mp4
  --fullhd, --1080p
    Enables video rendering mode with 1080p settings
  --2k, --1440p
    Enables video rendering mode with 1440p settings
  --4k, --2160p
    Enables video rendering mode with 2160p settings
  -w:WIDTH, --width:WIDTH
    Sets width to WIDTH
  -h:HEIGHT, --height:HEIGHT
    Sets height to HEIGHT
  --debug
    Enables debug mode which will visualize the scene's tracks.
    Default behaviour is to show the visualization in live mode
    but not in render mode.
```

Remember that the rendering to video requires [FFMpeg](https://www.ffmpeg.org/) to be installed and available in your `PATH`.

### Legal
 - The majority[1] of the source for this project is release under the MIT license. See the `LICENSE` file for details on what this means for distribution.
 - The Montserrat font families used in the examples in the `examples/fonts` directory are used under the OFL and are subject to copyright by The Montserrat Project Authors (https://github.com/JulietaUla/Montserrat). See `examples/fonts/OFL.txt`
 - This project has no association with 3b1b nor ManimCommunity's `manim`, but is indeed inspired by it.

[1]: Some files, like artwork and special entities, are not made public currently. This might change in the future.
