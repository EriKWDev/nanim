
const Tolerance = 1e-8

proc `~=`*(a, b: float): bool =
  ## Check if "a" and "b" are close.
  ## We use a relative tolerance to compare the values.

  result = abs(a - b) <= max(abs(a), abs(b)) * Tolerance
