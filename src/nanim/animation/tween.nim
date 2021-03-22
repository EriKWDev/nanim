
import easings


type
  Tween* = ref object of RootObj
    startTime*: float
    duration*: float

    interpolators*: seq[proc(t: float)]
    easing*: Easing


const defaultDuration*: float = 1200.0


proc evaluate*(tween: Tween, t: float) =
  var alpha = tween.easing(min(1.0, max(0.0, (t - tween.startTime)/tween.duration)))

  for interpolator in tween.interpolators:
    interpolator(alpha)


proc init(tween: Tween, interpolators: seq[proc(t: float)], easing: Easing, duration: float) =
  tween.interpolators = interpolators
  tween.easing = easing
  tween.duration = duration


func newTween*(interpolators: seq[proc(t: float)], easing: proc(t: float): float, duration: float): Tween =
  new(result)
  result.init(interpolators,
              easing,
              duration)

