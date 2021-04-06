
## `Nanim` is an easy-to-use framework to create smooth GPU-accelerated
## animations and export them to videos.

#
#                       Nanim
#        (c) Copyright 2021 Erik Wilhem Gren
#
#    See the file LICENSE regarging using, distributing
#     and copying all or parts of the code written for
#                   this package
#

import
  # Core
  nanim/core,

  # Animation
  nanim/animation,

  # Rendering
  nanim/rendering,

  # Entities
  nanim/entities


export
  core,
  animation,
  rendering,
  entities

# exporting these doesn't make sense in a normal library, but I can't bother importing them in every scene
import lenientops, glm
export lenientops, glm
