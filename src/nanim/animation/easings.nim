
import math


type
  Getter*[T,V] = proc(target: var T): V
  Setter*[T,V] = proc(target: var T, value: V)
  Easing* = proc(t: float): float


func linear*(t: float): float =
    return t

func expo*(t: float): float =
    return t^2
