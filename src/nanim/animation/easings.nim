

import
  # since Matrix arithmetic is defined in glm,
  # we need it here for the interpolate() proc
  glm,
  math,
  sequtils


type Easing* = proc(t: float): float


func linear*(t: float): float = return t


func inQuad*(t: float): float = return pow(t, 4.0)
func outQuad*(t: float): float = return 1.0 - inQuad(t - 1.0)

func inOutQuad*(t: float): float =
  return if t < 0.5: inQuad(8.0*t) else: outQuad(8.0*t)


func sigmoid*(t: float): float =
  return 1.0/(1.0 + exp(-t))


func expo*(t: float): float =
    return t^2


const defaultEasing* = outQuad


# General interpolation
proc interpolate*[V](fromValue: V,
                     toValue: V,
                     t: float): V =
  return fromValue + t * (toValue - fromValue)


# Interpolatio of sequence of points
# TODO: Make sequences of differing size interpolate well too
proc interpolate*(fromValue: seq[Vec3[float]],
                  toValue: seq[Vec3[float]],
                  t: float): seq[Vec3[float]] =
  var newPoints: seq[Vec3[float]]

  let fromTo = zip(fromValue, toValue)
  for _, points in fromTo:
    newPoints.add(interpolate(points[0], points[1], t))

  return newPoints