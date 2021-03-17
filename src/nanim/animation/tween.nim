


import
  glm,
  easings


type
  Tween*[T,V] = ref object of RootObj
    target*: T
    fromValue*: V
    toValue*: V

    setter*: proc(e: T, v: V)
    easing*: Easing


func `$`*(tween: Tween): string =
  result =
    "Tween\n" &
    "from: " & $(tween.fromValue) & "\n" &
    "to: " & $(tween.toValue)


proc evaluate*[T,V](tween: Tween[T,V], t: float) =
  tween.setter(tween.target, tween.fromValue + tween.easing(t) * (tween.toValue - tween.fromValue))


func init*[T,V](tween: Tween,
          target: T,
          fromValue: V,
          toValue: V,
          setter: proc(e: T, v: V),
          easing: Easing) =

  tween.target = target
  tween.fromValue = fromValue
  tween.toValue = toValue
  tween.setter = setter
  tween.easing = easing

func newTween*[T,V](target: T,
                    fromValue: V,
                    toValue: V,
                    setter: proc(e: T, v: V),
                    easing: Easing): Tween[T,V] =

  new(result)
  result.init(target,
              fromValue,
              toValue,
              setter,
              easing)

