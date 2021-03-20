

proc printNames(names: varargs[string],
                id1: int = 0,
                id2: int = 20) =
    echo id1, "-", id2, ": ", $names

# Works
printNames("Foo", "Bar", id2=10, id1=10)
printNames("Foo", "Bar", id1=10, id2=10)
printNames("Foo", "Bar", 10, 10)

## Doesn't compile
#[ All These Produce:
first type mismatch at position: 2
  required type for id1: int
  but expression '"Bar"' is of type: string
]#

printNames("Foo", "Bar", 10)
printNames("Foo", "Bar", id1=10)
printNames("Foo", "Bar", id2=10)



