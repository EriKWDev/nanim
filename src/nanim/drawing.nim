
import
  nanovg,
  opengl,
  glm


proc clearWithColor*(color: Color = rgba(0, 0, 0, 0)) =
  glClearColor(color.r, color.g, color.b, color.a)
  glClear(GL_COLOR_BUFFER_BIT or
          GL_DEPTH_BUFFER_BIT or
          GL_STENCIL_BUFFER_BIT)


proc drawPointsWithTension*(context: NVGContext, points: seq[Vec], tension: float = 0.5) =
  if len(points) < 2: return

  context.moveTo(points[0].x, points[0].y)

  let controlScale = tension / 0.5 * 0.175
  let numberOfPoints = len(points)

  for i in 0..high(points):
    let points_before = points[(i - 1 + numberOfPoints) mod numberOfPoints]
    let point = points[i]

    let pointAfter = points[(i + 1) mod numberOfPoints]
    let pointAfter2 = points[(i + 2) mod numberOfPoints]

    let p4 = pointAfter

    let di = vec2(pointAfter.x - points_before.x, pointAfter.y - points_before.y)
    let p2 = vec2(point.x + controlScale * di.x, point.y + controlScale * di.y)

    let diPlus1 = vec2(pointAfter2.x - points[i].x, pointAfter2.y - points[i].y)

    let p3 = vec2(pointAfter.x - controlScale * diPlus1.x, pointAfter.y - controlScale * diPlus1.y)

    context.bezierTo(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)


proc drawPointsWithRoundedCornerRadius*(context: NVGContext, points: seq[Vec], cornerRadius: float = 20) =
    if len(points) < 2: return

    var p1 = points[0]

    let lastPoint = points[high(points)]
    let midPoint = vec2((p1.x + lastPoint.x) / 2.0, (p1.y + lastPoint.y) / 2.0)

    context.moveTo(midPoint.x, midPoint.y)
    for i in 1..high(points):
      let p2 = points[i]

      context.arcTo(p1.x, p1.y, p2.x, p2.y, cornerRadius)
      p1 = p2

    context.arcTo(p1.x, p1.y, midPoint.x, midPoint.y, cornerRadius)


proc defaultPatternDrawer*(context: NVGContext, width: float, height: float) =
  context.beginPath()
  context.circle(width/2, height/2, width/2)
  context.closePath()

  context.fillColor(rgb(20, 20, 20))
  context.fill()


proc offset(some: pointer; b: int): pointer {.inline.} =
  result = cast[pointer](cast[int](some) + b)


var
  patternPaint: Paint
  hasGatheredPattern = false

proc gridPattern*(context: NVGContext,
                  patternDrawer: proc(context: NVGContext, width: float, height: float) = defaultPatternDrawer,
                  width: cint = 10,
                  height: cint = 10): Paint =

    # Impure, but worth it for the performance benefit...
  if hasGatheredPattern:
    return patternPaint

  let
    bufferSize = width * height * 4
    tempContext = nvgCreateContext({nifStencilStrokes, nifDebug})

  var imageData = alloc0(bufferSize)

  # clear the region
  glDrawPixels(width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)

  # draw the pattern
  let (frameBufferWidth, frameBufferHeight) = (2560, 1440)

  tempContext.beginFrame(frameBufferWidth.cfloat, frameBufferHeight.cfloat, 1)
  clearWithColor()
  tempContext.translate(0, frameBufferHeight.float - height.float)
  patternDrawer(tempContext, width.float, height.float)
  tempContext.endFrame()

  # read the region
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)

  var pixels = newSeq[uint8](bufferSize)

  # Flip the image
  for y in 0..<height:
    let
      lineSize = width * 4
      yDest = y * lineSize
      ySrc = bufferSize - yDest - lineSize
    copyMem(pixels[yDest].unsafeAddr, imageData.offset(ySrc), lineSize)

  # create an image from pixels
  let image = context.createImageRGBA(width, height, {ifRepeatX, ifRepeatY, ifFlipY}, pixels)

  # create and cache a pattern from the image
  patternPaint = context.imagePattern(0, 0, width.cfloat, height.cfloat, 0, image, 1.0)
  hasGatheredPattern = true

  # return the pattern
  result = patternPaint

  dealloc(imageData)


proc defaultPattern*(context: NVGContext): Paint =
  context.gridPattern(defaultPatternDrawer, 10, 10)
