import glm, nanovg

const Tolerance = 1e-8

proc `~=`*(a, b: float): bool {.inline.} =
  ## Check if "a" and "b" are close.
  ## We use a relative tolerance to compare the values.

  result = abs(a - b) <= max(abs(a), abs(b)) * Tolerance
  # echo $a & " ~= " & $b & " = " & $result


proc `~=`*(a, b: Vec3[float]): bool {.inline.} =
  result = a.x ~= b.x and a.y ~= b.y and a.z ~= b.z

proc `~=`*(a, b: Vec2[float]): bool {.inline.} =
  result = a.x ~= b.x and a.y ~= b.y

proc `~=`*(a: Vec3[float], b: Vec2[float]): bool {.inline.} =
  result = a.x ~= b.x and a.y ~= b.y

proc `~=`*(a: Vec2[float], b: Vec3[float]): bool {.inline.} =
  result = a.x ~= b.x and a.y ~= b.y

proc `~=`*(a, b: Color): bool {.inline.} =
  result = a.r ~= b.r and a.g ~= b.g and a.b ~= b.b and a.a ~= b.a

