import glm

const Tolerance = 1e-8

proc `~=`*(a, b: float): bool =
  ## Check if "a" and "b" are close.
  ## We use a relative tolerance to compare the values.

  result = abs(a - b) <= max(abs(a), abs(b)) * Tolerance
  # echo $a & " ~= " & $b & " = " & $result


proc `~=`*(a, b: Vec3[float]): bool =
  result = a.x ~= b.x and a.y ~= b.y and a.z ~= b.z

proc `~=`*(a, b: Vec2[float]): bool =
  result = a.x ~= b.x and a.y ~= b.y

proc `~=`*(a: Vec3[float], b: Vec2[float]): bool =
  result = a.x ~= b.x and a.y ~= b.y

proc `~=`*(a: Vec2[float], b: Vec3[float]): bool =
  result = a.x ~= b.x and a.y ~= b.y
