
import nanim/core


type
  Transition = ref object of Entity
    t*: float


proc init(transition: Transition) =
  init(transition.Entity)
  transition.t = 0.0


proc newTransition*(): Transition =
  new(result)
  result.init()
