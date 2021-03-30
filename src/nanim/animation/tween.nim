
import algorithm


import easings


type
  Tween* = ref object of RootObj
    startTime*: float
    duration*: float

    interpolators*: seq[proc(t: float)]
    easing*: Easing

  TweenTrack* = ref object of RootObj
    tweens*: seq[Tween]

    currentTweens: seq[Tween]
    oldTweens: seq[Tween]
    futureTweens: seq[Tween]

    done*: bool


const defaultDuration*: float = 1100.0


proc evaluate*(tween: Tween, time: float) =
  var t = tween.easing(min(1.0, max(0.0, (time - tween.startTime)/tween.duration)))

  for i in 0..high(tween.interpolators):
    tween.interpolators[i](t)


proc evaluate*(tweenTrack: TweenTrack, time: float) =
  # By first evaluating all future tweens in reverse order, then old tweens and
  # finally the current ones, we assure that all tween's have been reset and/or
  # completed correctly.
  tweenTrack.oldTweens = @[]
  tweenTrack.currentTweens = @[]
  tweenTrack.futureTweens = @[]

  for tween in tweenTrack.tweens:
    if time > tween.startTime + tween.duration:
      tweenTrack.oldTweens.add(tween)
    elif time < tween.startTime:
      tweenTrack.futureTweens.add(tween)

    else:
      tweenTrack.currentTweens.add(tween)

  for tween in tweenTrack.oldTweens & tweenTrack.futureTweens.reversed():
    tween.evaluate(time)

  for tween in tweenTrack.currentTweens:
    tween.evaluate(time)

  tweenTrack.done = false

  if len(tweenTrack.oldTweens) == len(tweenTrack.tweens) and len(tweenTrack.futureTweens) == 0:
    tweenTrack.done = true


proc add*(tweenTrack: TweenTrack, tweens: varargs[Tween]) =
  tweenTrack.tweens.add(tweens)


proc init(tween: Tween, interpolators: seq[proc(t: float)], easing: Easing, duration: float) =
  tween.interpolators = interpolators
  tween.easing = easing
  tween.duration = duration
  tween.startTime = 0


func newTween*(interpolators: seq[proc(t: float)], easing: proc(t: float): float, duration: float): Tween =
  new(result)
  result.init(interpolators,
              easing,
              duration)


func getLatestTween*(tweenTrack: TweenTrack): Tween =
  if len(tweenTrack.tweens) == 0:
    return newTween(@[], linear, 0)

  return tweenTrack.tweens[high(tweenTrack.tweens)]


proc init(tweenTrack: TweenTrack) =
  tweenTrack.tweens = @[]

  tweenTrack.currentTweens = @[]
  tweenTrack.oldTweens = @[]
  tweenTrack.futureTweens = @[]

  tweenTrack.done = false


func newTweenTrack*(): TweenTrack =
  new(result)
  result.init()