
import
  nanim/animation/easings


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


var defaultDuration*: float = 1100.0

method execute*(tween: Tween, t: float) {.inline, base.} =
  for interpolator in tween.interpolators:
    interpolator(t)


method evaluate*(tween: Tween, time: float) {.base.} =
  let t = if tween.duration <= 0:
      1.0
    else:
      tween.easing(min(1.0, max(0.0, (time - tween.startTime)/tween.duration)))

  tween.execute(t)

{.push checks: off, optimization: speed.}
proc evaluate*(tweenTrack: TweenTrack, time: float) =
  # By first evaluating all future tweens in reverse order, then old tweens and
  # finally the current ones, we assure that all tween's have been reset and/or
  # completed correctly.
  tweenTrack.oldTweens = @[]
  tweenTrack.currentTweens = @[]
  tweenTrack.futureTweens = @[]

  for i in 0..high(tweenTrack.tweens):
    let tween = tweenTrack.tweens[i]

    if time > tween.startTime + tween.duration:
      tweenTrack.oldTweens.add(tween)
    elif time < tween.startTime:
      tweenTrack.futureTweens.add(tween)
    else:
      tweenTrack.currentTweens.add(tween)

  for i in 0..high(tweenTrack.oldTweens):
    tweenTrack.oldTweens[i].execute(1.0)

  for i in countdown(high(tweenTrack.futureTweens), 0, 1):
    tweenTrack.futureTweens[i].execute(0.0)

  for i in 0..high(tweenTrack.currentTweens):
    tweenTrack.currentTweens[i].evaluate(time)

  tweenTrack.done = false

  if len(tweenTrack.oldTweens) == len(tweenTrack.tweens) and len(tweenTrack.futureTweens) == 0 and len(tweenTrack.currentTweens) == 0:
    tweenTrack.done = true
{.pop.}

proc add*(tweenTrack: TweenTrack, tweens: varargs[Tween]) {.inline.} =
  tweenTrack.tweens.add(tweens)


proc init(tween: Tween, interpolators: seq[proc(t: float)], easing: Easing = defaultEasing, duration: float) =
  tween.interpolators = interpolators
  tween.easing = easing
  tween.duration = duration
  tween.startTime = 0


func newTween*(interpolators: seq[proc(t: float)], easing: Easing = defaultEasing, duration: float = defaultDuration): Tween =
  new(result)
  result.init(interpolators, easing, duration)


func with*(base: Tween, duration=base.duration, easing: Easing = base.easing, startTime=base.startTime, interpolators=base.interpolators): Tween =
  new(result)
  result.duration = duration
  result.easing = easing
  result.startTime = startTime
  result.interpolators = interpolators


proc copyWith*(base: Tween, duration=base.duration, easing: Easing = base.easing, startTime=base.startTime, interpolators=base.interpolators): Tween {.inline.} =
  with(base, defaultDuration, easing, startTime, interpolators)


func with*(bases: openArray[Tween], duration=defaultDuration, easing: Easing = defaultEasing): seq[Tween] =
  result = newSeq[Tween]()
  for base in bases:
    result.add(base.with(duration, easing))


func with*(bases: openArray[seq[Tween]], duration=defaultDuration, easing: Easing = defaultEasing): seq[Tween] =
  result = newSeq[Tween]()
  for base in bases:
    result.add(base.with(duration, easing))


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
