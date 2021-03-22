#
#                       Nanim
#        (c) Copyright 2021 Erik Wilhem Gren
#
#    See the file LICENSE regarging using, distributing
#     and copying all or parts of the code written for
#                   this package
#

import
  # Animation
  nanim/animation/tween,
  nanim/animation/easings,

  # Entities
  nanim/entities/entity,
  nanim/entities/circle,
  nanim/entities/rectangle,
  nanim/entities/text,

  # Scene
  nanim/scene

export tween, easings, scene, entity, circle, rectangle, text

# exporting these doesn't make sense in a normal library, but I can't bother importing them in every scene
import lenientops, glm
export lenientops, glm