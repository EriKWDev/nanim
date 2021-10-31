# Package

version       = "0.3.1"
author        = "EriKWDev"
description   = "Nanim is an easy-to-use framework to create smooth GPU-accelerated animations and export them to videos."
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples", "tests"]


# Dependencies

requires "nim >= 1.4.2"
requires "staticglfw >= 4.1.3"
requires "glm >= 1.1.0"
requires "nanovg >= 0.3.2"
requires "rainbow >= 0.2.0"
requires "stb_image >= 1.2"
