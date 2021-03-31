# Package

version       = "0.2.0"
author        = "EriKWDev"
description   = "Nanim is an easy-to-use framework to create smooth GPU-accelerated animations and export them to videos."
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples"]


# Dependencies

requires "nim >= 1.4.2"
requires "glfw >= 3.3.2"
requires "glm >= 1.1.0"
requires "https://github.com/nimgl/opengl.git >= 1.0.1"
requires "https://github.com/johnnovak/nim-nanovg#099121232829722752d33e0472a11201195feb55"
