# Package

version       = "0.3.0"
author        = "EriKWDev"
description   = "Nanim is an easy-to-use framework to create smooth GPU-accelerated animations and export them to videos."
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples"]


# Dependencies

requires "nim >= 1.4.2"
requires "staticglfw >= 4.1.3"
requires "glm >= 1.1.0"
requires "https://github.com/johnnovak/nim-nanovg#dc5fe1f13f17746ff1687871506056ef6be8c8da"
requires "rainbow >= 0.2.0"
