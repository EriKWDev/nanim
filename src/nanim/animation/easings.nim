

import
  # since Matrix arithmetic is defined in glm,
  # we need it here for the interpolate() proc
  glm,
  math,
  sequtils,
  nanovg


type Easing* = proc(t: float): float


func linear*(t: float): float = return t

func inQuad*(t: float): float = return pow(t, 4.0)
func outQuad*(t: float): float = return 1.0 - inQuad(t - 1.0)

func inExpo*(t: float): float = return pow(t, 2.0)
func outExpo*(t: float): float = return 1.0 - inExpo(t - 1.0)

# from https://stats.stackexchange.com/questions/214877/is-there-a-formula-for-an-s-shaped-curve-with-domain-and-range-0-1
func sigmoid*(t: float, n: float): float = return 1.0/(1.0 + pow(t/(1.0 - t), -abs(n)))

func sigmoid2*(t: float): float = sigmoid(t, 2.0)
func sigmoid3*(t: float): float = sigmoid(t, 3.0)
func sigmoid4*(t: float): float = sigmoid(t, 4.0)
func sigmoid5*(t: float): float = sigmoid(t, 5.0)

func bounceOut*(t: float): float =
  if t < 4/11.0:
    return (121 * t * t)/16.0
  elif t < 8/11.0:
    return (363/40.0 * t * t) - (99/10.0 * t) + 17/5.0
  elif t < 9/10.0:
    return (4356/361.0 * t * t) - (35442/1805.0 * t) + 16061/1805.0
  else:
    return (54/5.0 * t * t) - (513/25.0 * t) + 268/25.0

func bounceIn*(t: float): float = return 1.0 - bounceOut(1.0 - t)

func easeOutElastic*(t: float): float =
  let c4 = (2.0 * PI) / 3.0

  return pow(2.0, -10 * t) * sin((t * 10 - 0.75) * c4) + 1.0

proc eitherOrInterpolation*[T](fromValue: T, toValue: T, t: float): T =
  return if t < 0.5: fromValue else: toValue


proc interpolate*[V](fromValue: V, toValue: V, t: float): V =
  return fromValue + t * (toValue - fromValue)


proc interpolate*(fromValue: bool, toValue: bool, t: float): bool =
  eitherOrInterpolation(fromValue, toValue, t)


proc interpolate*(fromValue: int, toValue: int, t: float): int =
  interpolate(fromValue.float, toValue.float, t).int


proc interpolatePointsOfSameSize*(fromValue: seq[Vec3[float]],
                                  toValue: seq[Vec3[float]],
                                  t: float): seq[Vec3[float]] =
  result = newSeq[Vec3[float]](len(fromValue))

  let fromTo = zip(fromValue, toValue)
  for i, points in fromTo:
    result[i] = interpolate(points[0], points[1], t)


# Interpolation of sequence of points
# TODO: Make sequences of differing size interpolate well too (somehow...)
proc interpolate*(fromValue: seq[Vec3[float]],
                  toValue: seq[Vec3[float]],
                  t: float): seq[Vec3[float]] =
  let
    lf = len(fromValue)
    lt = len(toValue)

  if lf == lt:
    return interpolatePointsOfSameSize(fromValue, toValue, t)

  if lf + 1 == lt:
    return interpolatePointsOfSameSize(fromValue, toValue[0..^2], t) & interpolate(fromValue[^1], toValue[^1], t)

  if lt + 1 == lf:
    return interpolatePointsOfSameSize(fromValue[0..^2], toValue, t) & interpolate(toValue[^1], fromValue[^1], t)


proc interpolate*(fromValue: Color, toValue: Color, t: float): Color =
  lerp(fromValue, toValue, t)

proc interpolate*(fromValue: Paint, toValue: Paint, t: float): Paint =
  eitherOrInterpolation(fromValue, toValue, t)


# Can use https://cubic-bezier.com/ to create nice curves
func cubicBezier*(t: float = 0.0, cpx1, cpy1, cpx2, cpy2: float): float =
  let
    controlPoint1 = vec2(min(1.0, max(0.0, cpx1)), cpy1)
    controlPoint2 = vec2(min(1.0, max(0.0, cpx2)), cpy2)
    startPoint = vec2(0.0, 0.0)
    endPoint = vec2(1.0, 1.0)

  let
    p1 = interpolate(startPoint, controlPoint1, t)
    p2 = interpolate(controlPoint1, controlPoint2, t)
    p3 = interpolate(controlPoint2, endPoint, t)
    p12 = interpolate(p1, p2, t)
    p23 = interpolate(p2, p3, t)
    finalPoint = interpolate(p12, p23, t)

  return finalPoint.y

func smoothOvershoot*(t: float): float = cubicBezier(t, 1.0, -0.3, 0.12, 1.22)

var defaultEasing* = sigmoid3

