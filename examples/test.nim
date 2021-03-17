
type
  Test = object of RootObj
    x: int


proc newTest(): Test =
  result.x = 0


proc modify(test: var Test, newX: int = 10) =
  test.x = newX

proc main() =
  var test = newTest()
  echo test.x
  test.modify()
  echo test.x


when isMainModule:
  main()
