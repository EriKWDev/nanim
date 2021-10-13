import nanim

proc testScene(): Scene =
  # Creates a scene-state
  let scene = newScene()

  # You can load some nice colors from a palette on coolors.co!
  var colors = colorsFromCoolors("https://coolors.co/33658a-86bbd8-758e4f-f6ae2d-f26419")
  scene.randomize() # randomize the seed of the scene

  colors.shuffle()
  let bg = colors[0]
  colors.del(0)
  scene.setBackgroundColor(bg)

  var
    text = newText("Hello, World!", font="montserrat-thin")
    rect = newSquare()

  # We must add our entities to the scene in order for them to be drawn
  scene.add(rect, text)

  # Set some colors!
  text.fill(colors[1])
  rect.fill(colors[2])
  rect.stroke(colors[3], 4.0)

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