
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


proc defaultPattern(context: NVGContext) =
  context.beginPath()
  context.circle(5, 1440-5, 3)
  context.closePath()

  context.fillColor(rgb(20, 20, 20))
  context.fill()


var
  patternPaint: Paint
  hasGatheredPattern = false

proc gridPattern*(context: NVGContext, patternDrawer: proc(context: NVGContext) = defaultPattern, width: cint = 10, height: cint = 10): Paint =
  # Impure, but worth it for the performance benefit...
  if hasGatheredPattern:
    return patternPaint

  let
    bufferSize = width*height*4
    oldTransformMatrix = context.currentTransform()

  var
    oldData = alloc0(bufferSize)
    imageData = alloc0(bufferSize)

  context.endFrame()

  glPixelStorei(GL_PACK_ALIGNMENT, 1)
  glReadBuffer(GL_BACK)

  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, oldData)
  glDrawPixels(width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)

  context.beginFrame(2880.cfloat, 1440.cfloat, 1)
  patternDrawer(context)
  context.endFrame()

  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData)
  var pixels: seq[uint8] = newSeq[uint8](bufferSize)
  copyMem(pixels[0].unsafeAddr, imageData, bufferSize)
  let image = context.createImageRGBA(width, height, {ifRepeatX, ifRepeatY, ifFlipY}, pixels)

  patternPaint = context.imagePattern(0, 0, width.cfloat, height.cfloat, 0, image, 1.0)
  hasGatheredPattern = true
  result = patternPaint

  context.beginFrame(2880.cfloat, 1440.cfloat, 1)
  glDrawPixels(width, height, GL_RGBA, GL_UNSIGNED_BYTE, oldData)

  dealloc(oldData)
  dealloc(imageData)

  context.transform(oldTransformMatrix.m[0], oldTransformMatrix.m[1], oldTransformMatrix.m[2],
                    oldTransformMatrix.m[3], oldTransformMatrix.m[4], oldTransformMatrix.m[5])
