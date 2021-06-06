//
//  OffscreenCanvas.swift
//  Glance
//
//  Created by Marc Prud'hommeaux on 7/21/15.

import JXKit
import MiscKit

public protocol CanvasAPI : AnyObject {
    var width: Double { get set }

    var height: Double { get set }

    /// The color, gradient, or pattern to use inside shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle
    var fillStyle: AnyObject? { get set }

    /// The color, gradient, or pattern to use for the strokes (outlines) around shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeStyle
    var strokeStyle: String? { get set }

    /// The color of shadows
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowColor
    var shadowColor: String? { get set }

    /// The amount of blur applied to shadows.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur
    var shadowBlur: Double? { get set }

    /// The distance that shadows will be offset horizontally.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetX
    var shadowOffsetX: Double? { get set }

    /// The distance that shadows will be offset vertically.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetY
    var shadowOffsetY: Double? { get set }

    /// The shape used to draw the end points of lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap
    var lineCap: String? { get set }

    /// The shape used to join two line segments where they meet.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin
    var lineJoin: String? { get set }

    /// The thickness of lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineWidth
    var lineWidth: Double? { get set }

    /// Sets the line dash offset, or "phase."
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineDashOffset
    var lineDashOffset: Double? { get set }

    /// The miter limit ratio.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/miterLimit
    var miterLimit: Double? { get set }

    /// The current text style to use when drawing text. This string uses the same syntax as the CSS font specifier.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/font
    var font: String? { get set }

    /// The current text alignment used when drawing text.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign
    var textAlign: String? { get set }

    /// The current text baseline used when drawing text.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline
    var textBaseline: String? { get set }

    /// The alpha (transparency) value that is applied to shapes and images before they are drawn onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalAlpha
    var globalAlpha: Double? { get set }

    /// The type of compositing operation to apply when drawing new shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation
    var globalCompositeOperation: String? { get set }

    /// Returns a TextMetrics object that contains information about the measured text (such as its width, for example).
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/measureText
    func measureText(value: String?) -> [String: Double]

    /// Resets (overrides) the current transformation to the identity matrix, and then invokes a transformation described by the arguments of this method.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform
    func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Multiplies the current transformation with the matrix described by the arguments of this method.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform
    func transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Saves the entire state of the canvas by pushing the current state onto a stack.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/save
    func save()

    /// Restores the most recently saved canvas state by popping the top entry in the drawing state stack. If there is no saved state, this method does nothing.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/restore
    func restore()

    /// Erases the pixels in a rectangular area by setting them to transparent black.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clearRect
    func clearRect(x: Double, y: Double, w: Double, h: Double)

    /// Adds a translation transformation to the current matrix.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/translate
    func translate(x: Double, y: Double)

    /// Starts a new path by emptying the list of sub-paths. Call this method when you want to create a new path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/beginPath
    func beginPath()

    /// Attempts to add a straight line from the current point to the start of the current sub-path. If the shape has already been closed or has only one point, this function does nothing.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/closePath
    func closePath()

    /// Adds a rectangle to the current path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rect
    func rect(x: Double, y: Double, w: Double, h: Double)

    /// Draws a rectangle that is filled according to the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillRect
    func fillRect(x: Double, y: Double, w: Double, h: Double)

    /// Draws a rectangle that is stroked (outlined) according to the current strokeStyle and other context settings.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeRect
    func strokeRect(x: Double, y: Double, width: Double, height: Double)

    /// Fills the current or given path with the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fill
    func fill()

    /// Strokes (outlines) the current or given path with the current stroke style.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/stroke
    func stroke()

    /// Turns the current or given path into the current clipping region. It replaces any previous clipping region.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clip
    func clip()

    /// Begins a new sub-path at the point specified by the given (x, y) coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/moveTo
    func moveTo(x: Double, y: Double)

    /// Adds a straight line to the current sub-path by connecting the sub-path's last point to the specified (x, y) coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineTo
    func lineTo(x: Double, y: Double)

    /// Draws a text string at the specified coordinates, filling the string's characters with the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillText
    func fillText(text: String, x: Double, y: Double, maxWidth: Double)

    /// Strokes — that is, draws the outlines of — the characters of a text string at the specified coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeText
    func strokeText(text: String, x: Double, y: Double, maxWidth: Double)

    /// Adds a rotation to the transformation matrix.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rotate
    func rotate(angle: Double)

    /// Adds a cubic Bézier curve to the current sub-path. It requires three points: the first two are control points and the third one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the Bézier curve.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/bezierCurveTo
    func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double)

    /// adds a quadratic Bézier curve to the current sub-path. It requires two points: the first one is a control point and the second one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the quadratic Bézier curve.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/quadraticCurveTo
    func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double)

    /// Adds a circular arc to the current sub-path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arc
    func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, anticlockwise: Bool)

    /// Adds a circular arc to the current sub-path, using the given control points and radius.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arcTo
    func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double)

    /// Adds an elliptical arc to the current sub-path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/ellipse
    func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double)

    /// Creates a gradient along the line connecting two given coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createLinearGradient
    func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI?

    /// Creates a radial gradient using the size and coordinates of two circles.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
    func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI?

//    /// Creates a pattern using the specified image and repetition.
//    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createPattern
    // NOTE: we will need this now that some (non-axis-aligned) gradients patterns are drawn offscreen: https://github.com/vega/vega/issues/2365
//    CanvasPattern ctx.createPattern(image, repetition);

//    func ctx.drawFocusIfNeeded(path, element)

    /// Provides different ways to draw an image onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage
    func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double)

    /// Creates a new, blank ImageData object with the specified dimensions.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createImageData
    func createImageData(width: Double, height: Double) -> ImageDataAPI?

    /// Returns an ImageData object representing the underlying pixel data for a specified portion of the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getImageData
    func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI?

    /// Paints data from the given ImageData object onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/putImageData
    func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double)

    /// Sets the line dash pattern used when stroking lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setLineDash
    func setLineDash(segments: [Double])

    /// Gets the current line dash pattern.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getLineDash
    func getLineDash() -> [Double]

    /// Reports whether or not the specified point is contained in the current path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInPath
    func isPointInPath(x: Double, y: Double) -> Bool

    /// Reports whether or not the specified point is inside the area contained by the stroking of a path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInStroke
    func isPointInStroke(x: Double, y: Double) -> Bool
}


/// The CanvasGradient interface represents an opaque object describing a gradient. It is returned by the methods CanvasRenderingContext2D.createLinearGradient() or CanvasRenderingContext2D.createRadialGradient().
/// https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient
public protocol CanvasGradientAPI : AnyObject {
    /// adds a new color stop, defined by an offset and a color, to a given canvas gradient.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient/addColorStop
    func addColorStop(offset: Double, color: String)
}

public protocol ImageDataAPI : AnyObject {
}



/// A base class for an implementation of the CanvasAPI to be exposed to a `JXContext`, thereby allowing the use of Canvas2D.
///
/// This class synthesizes the JavaScript properties and functions that are exposed by Canvas2D. Sublcasses are expected to implement the actual drawing calls for the CanvasAPI protocol, which can be either immediate-mode or stored.
///
/// See: [Canvas API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
open class Canvas : JXValue {
    /// The color, gradient, or pattern to use inside shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle
    open var fillStyle: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The color, gradient, or pattern to use for the strokes (outlines) around shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeStyle
    open var strokeStyle: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The color of shadows
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowColor
    open var shadowColor: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The amount of blur applied to shadows.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur
    open var shadowBlur: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The distance that shadows will be offset horizontally.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetX
    open var shadowOffsetX: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The distance that shadows will be offset vertically.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetY
    open var shadowOffsetY: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The shape used to draw the end points of lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap
    open var lineCap: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The shape used to join two line segments where they meet.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin
    open var lineJoin: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The thickness of lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineWidth
    open var lineWidth: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// Sets the line dash offset, or "phase."
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineDashOffset
    open var lineDashOffset: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The miter limit ratio.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/miterLimit
    open var miterLimit: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The current text style to use when drawing text. This string uses the same syntax as the CSS font specifier.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/font
    open var font: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The current text alignment used when drawing text.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign
    open var textAlign: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The current text baseline used when drawing text.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline
    open var textBaseline: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The alpha (transparency) value that is applied to shapes and images before they are drawn onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalAlpha
    open var globalAlpha: JXValue {
        didSet {
            dbg("set")
        }
    }

    /// The type of compositing operation to apply when drawing new shapes.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation
    open var globalCompositeOperation: JXValue {
        didSet {
            dbg("set")
        }
    }


    /// Returns a TextMetrics object that contains information about the measured text (such as its width, for example).
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/measureText
    open var measureText: JXFunction = { ctx, this, args in
        dbg("measureText", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Resets (overrides) the current transformation to the identity matrix, and then invokes a transformation described by the arguments of this method.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform
    open var setTransform: JXFunction = { ctx, this, args in
        dbg("setTransform", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Multiplies the current transformation with the matrix described by the arguments of this method.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform
    open var transform: JXFunction = { ctx, this, args in
        dbg("transform", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Saves the entire state of the canvas by pushing the current state onto a stack.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/save
    open var save: JXFunction = { ctx, this, args in
        dbg("save", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Restores the most recently saved canvas state by popping the top entry in the drawing state stack. If there is no saved state, this method does nothing.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/restore
    open var restore: JXFunction = { ctx, this, args in
        dbg("restore", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Erases the pixels in a rectangular area by setting them to transparent black.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clearRect
    open var clearRect: JXFunction = { ctx, this, args in
        dbg("clearRect", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a translation transformation to the current matrix.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/translate
    open var translate: JXFunction = { ctx, this, args in
        dbg("translate", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Starts a new path by emptying the list of sub-paths. Call this method when you want to create a new path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/beginPath
    open var beginPath: JXFunction = { ctx, this, args in
        dbg("beginPath", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Attempts to add a straight line from the current point to the start of the current sub-path. If the shape has already been closed or has only one point, this function does nothing.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/closePath
    open var closePath: JXFunction = { ctx, this, args in
        dbg("closePath", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a rectangle to the current path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rect
    open var rect: JXFunction = { ctx, this, args in
        dbg("rect", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Draws a rectangle that is filled according to the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillRect
    open var fillRect: JXFunction = { ctx, this, args in
        dbg("fillRect", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Draws a rectangle that is stroked (outlined) according to the current strokeStyle and other context settings.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeRect
    open var strokeRect: JXFunction = { ctx, this, args in
        dbg("strokeRect", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Fills the current or given path with the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fill
    open var fill: JXFunction = { ctx, this, args in
        dbg("fill", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Strokes (outlines) the current or given path with the current stroke style.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/stroke
    open var stroke: JXFunction = { ctx, this, args in
        dbg("stroke", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Turns the current or given path into the current clipping region. It replaces any previous clipping region.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clip
    open var clip: JXFunction = { ctx, this, args in
        dbg("clip", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Begins a new sub-path at the point specified by the given (x, y) coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/moveTo
    open var moveTo: JXFunction = { ctx, this, args in
        dbg("moveTo", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a straight line to the current sub-path by connecting the sub-path's last point to the specified (x, y) coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineTo
    open var lineTo: JXFunction = { ctx, this, args in
        dbg("lineTo", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Draws a text string at the specified coordinates, filling the string's characters with the current fillStyle.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillText
    open var fillText: JXFunction = { ctx, this, args in
        dbg("fillText", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Strokes — that is, draws the outlines of — the characters of a text string at the specified coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeText
    open var strokeText: JXFunction = { ctx, this, args in
        dbg("strokeText", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a rotation to the transformation matrix.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/scale
    open var rotate: JXFunction = { ctx, this, args in
        dbg("rotate", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a scaling transformation to the canvas units by x horizontally and by y vertically.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rotate
    open var scale: JXFunction = { ctx, this, args in
        dbg("scale", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a cubic Bézier curve to the current sub-path. It requires three points: the first two are control points and the third one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the Bézier curve.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/bezierCurveTo
    open var bezierCurveTo: JXFunction = { ctx, this, args in
        dbg("bezierCurveTo", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// adds a quadratic Bézier curve to the current sub-path. It requires two points: the first one is a control point and the second one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the quadratic Bézier curve.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/quadraticCurveTo
    open var quadraticCurveTo: JXFunction = { ctx, this, args in
        dbg("quadraticCurveTo", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a circular arc to the current sub-path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arc
    open var arc: JXFunction = { ctx, this, args in
        dbg("arc", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds a circular arc to the current sub-path, using the given control points and radius.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arcTo
    open var arcTo: JXFunction = { ctx, this, args in
        dbg("arcTo", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Adds an elliptical arc to the current sub-path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/ellipse
    open var ellipse: JXFunction = { ctx, this, args in
        dbg("ellipse", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Creates a gradient along the line connecting two given coordinates.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createLinearGradient
    open var createLinearGradient: JXFunction = { ctx, this, args in
        dbg("createLinearGradient", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Creates a radial gradient using the size and coordinates of two circles.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
    open var createRadialGradient: JXFunction = { ctx, this, args in
        dbg("createRadialGradient", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Provides different ways to draw an image onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage
    open var drawImage: JXFunction = { ctx, this, args in
        dbg("drawImage", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Creates a new, blank ImageData object with the specified dimensions.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createImageData
    open var createImageData: JXFunction = { ctx, this, args in
        dbg("createImageData", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Returns an ImageData object representing the underlying pixel data for a specified portion of the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getImageData
    open var getImageData: JXFunction = { ctx, this, args in
        dbg("getImageData", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Paints data from the given ImageData object onto the canvas.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/putImageData
    open var putImageData: JXFunction = { ctx, this, args in
        dbg("putImageData", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Sets the line dash pattern used when stroking lines.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setLineDash
    open var setLineDash: JXFunction = { ctx, this, args in
        dbg("setLineDash", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Gets the current line dash pattern.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getLineDash
    open var getLineDash: JXFunction = { ctx, this, args in
        dbg("getLineDash", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Reports whether or not the specified point is contained in the current path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInPath
    open var isPointInPath: JXFunction = { ctx, this, args in
        dbg("isPointInPath", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    /// Reports whether or not the specified point is inside the area contained by the stroking of a path.
    /// https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInStroke
    open var isPointInStroke: JXFunction = { ctx, this, args in
        dbg("isPointInStroke", args.compactMap(\.stringValue))
        return ctx.undefined()
    }

    let delegate: CanvasAPI

    public required init(env: JXContext, delegate: CanvasAPI) {
        self.fillStyle = env.undefined() // fillStyle
        self.strokeStyle = env.undefined() // strokeStyle
        self.shadowColor = env.undefined() // shadowColor
        self.shadowBlur = env.undefined() // shadowBlur
        self.shadowOffsetX = env.undefined() // shadowOffsetX
        self.shadowOffsetY = env.undefined() // shadowOffsetY
        self.lineCap = env.undefined() // lineCap
        self.lineJoin = env.undefined() // lineJoin
        self.lineWidth = env.undefined() // lineWidth
        self.lineDashOffset = env.undefined() // lineDashOffset
        self.miterLimit = env.undefined() // miterLimit
        self.font = env.undefined() // font
        self.textAlign = env.undefined() // textAlign
        self.textBaseline = env.undefined() // textBaseline
        self.globalAlpha = env.undefined() // globalAlpha
        self.globalCompositeOperation = env.undefined() // globalCompositeOperation

        self.delegate = delegate
        
        //super.init(newObjectIn: env)
        super.init(env: env, value: env.object().value)

        addProperty(named: "fillStyle", path: \Self.fillStyle)
        addProperty(named: "strokeStyle", path: \Self.strokeStyle)
        addProperty(named: "shadowColor", path: \Self.shadowColor)
        addProperty(named: "shadowBlur", path: \Self.shadowBlur)
        addProperty(named: "shadowOffsetX", path: \Self.shadowOffsetX)
        addProperty(named: "shadowOffsetY", path: \Self.shadowOffsetY)
        addProperty(named: "lineCap", path: \Self.lineCap)
        addProperty(named: "lineJoin", path: \Self.lineJoin)
        addProperty(named: "lineWidth", path: \Self.lineWidth)
        addProperty(named: "lineDashOffset", path: \Self.lineDashOffset)
        addProperty(named: "miterLimit", path: \Self.miterLimit)
        addProperty(named: "font", path: \Self.font)
        addProperty(named: "textAlign", path: \Self.textAlign)
        addProperty(named: "textBaseline", path: \Self.textBaseline)
        addProperty(named: "globalAlpha", path: \Self.globalAlpha)
        addProperty(named: "globalCompositeOperation", path: \Self.globalCompositeOperation)


        let shim = false

        let _ = try? addFunction("measureText", shim: shim, callback: measureText)
        let _ = try? addFunction("setTransform", shim: shim, callback: setTransform)
        let _ = try? addFunction("transform", shim: shim, callback: transform)
        let _ = try? addFunction("save", shim: shim, callback: save)
        let _ = try? addFunction("restore", shim: shim, callback: restore)
        let _ = try? addFunction("clearRect", shim: shim, callback: clearRect)
        let _ = try? addFunction("translate", shim: shim, callback: translate)
        let _ = try? addFunction("beginPath", shim: shim, callback: beginPath)
        let _ = try? addFunction("closePath", shim: shim, callback: closePath)
        let _ = try? addFunction("rect", shim: shim, callback: rect)
        let _ = try? addFunction("fillRect", shim: shim, callback: fillRect)
        let _ = try? addFunction("strokeRect", shim: shim, callback: strokeRect)
        let _ = try? addFunction("fill", shim: shim, callback: fill)
        let _ = try? addFunction("stroke", shim: shim, callback: stroke)
        let _ = try? addFunction("clip", shim: shim, callback: clip)
        let _ = try? addFunction("moveTo", shim: shim, callback: moveTo)
        let _ = try? addFunction("lineTo", shim: shim, callback: lineTo)
        let _ = try? addFunction("fillText", shim: shim, callback: fillText)
        let _ = try? addFunction("strokeText", shim: shim, callback: strokeText)
        let _ = try? addFunction("scale", shim: shim, callback: clip)
        let _ = try? addFunction("rotate", shim: shim, callback: rotate)
        let _ = try? addFunction("bezierCurveTo", shim: shim, callback: bezierCurveTo)
        let _ = try? addFunction("quadraticCurveTo", shim: shim, callback: quadraticCurveTo)
        let _ = try? addFunction("arc", shim: shim, callback: arc)
        let _ = try? addFunction("arcTo", shim: shim, callback: arcTo)
        let _ = try? addFunction("ellipse", shim: shim, callback: ellipse)
        let _ = try? addFunction("createLinearGradient", shim: shim, callback: createLinearGradient)
        let _ = try? addFunction("createRadialGradient", shim: shim, callback: createRadialGradient)
        let _ = try? addFunction("drawImage", shim: shim, callback: drawImage)
        let _ = try? addFunction("createImageData", shim: shim, callback: createImageData)
        let _ = try? addFunction("getImageData", shim: shim, callback: createImageData)
        let _ = try? addFunction("putImageData", shim: shim, callback: putImageData)
        let _ = try? addFunction("setLineDash", shim: shim, callback: setLineDash)
        let _ = try? addFunction("getLineDash", shim: shim, callback: getLineDash)
        let _ = try? addFunction("isPointInPath", shim: shim, callback: isPointInPath)
        let _ = try? addFunction("isPointInStroke", shim: shim, callback: isPointInStroke)
    }
}

extension Canvas {
    /// Adds a property to the canvas
    func addProperty(named propertyName: String, path: ReferenceWritableKeyPath<Canvas, JXValue>) {
        defineProperty(propertyName, JXProp(getter: { [weak self] val in
            self?[keyPath: path] ?? val.env.undefined()
        }, setter: { [weak self] in
            self?[keyPath: path] = $1
        }, configurable: true, enumerable: true))
    }
}

/// An abstract `CanvasAPI` implementation that provides empty implementations for the requires properties and functions.
///
/// Partial implementations can subclass this class and implement only the parts they need.
open class AbstractCanvasAPI : CanvasAPI {
    open var width: Double = 0.0

    open var height: Double = 0.0

    open var fillStyle: AnyObject? = nil
    open var strokeStyle: String? = nil
    open var shadowColor: String? = nil
    open var shadowBlur: Double? = nil
    open var shadowOffsetX: Double? = nil
    open var shadowOffsetY: Double? = nil
    open var lineCap: String? = nil
    open var lineJoin: String? = nil
    open var lineWidth: Double? = nil
    open var lineDashOffset: Double? = nil
    open var miterLimit: Double? = nil
    open var font: String? = nil
    open var textAlign: String? = nil
    open var textBaseline: String? = nil
    open var globalAlpha: Double? = nil
    open var globalCompositeOperation: String? = nil

    public init() {
    }

    open func measureText(value: String?) -> [String : Double] {
        dbg("missing implementation")
        return .init()
    }

    open func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        dbg("missing implementation")
    }

    open func transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        dbg("missing implementation")
    }

    open func save() {
        dbg("missing implementation")
    }

    open func restore() {
        dbg("missing implementation")
    }

    open func clearRect(x: Double, y: Double, w: Double, h: Double) {
        dbg("missing implementation")
    }

    open func translate(x: Double, y: Double) {
        dbg("missing implementation")
    }

    open func beginPath() {
        dbg("missing implementation")
    }

    open func closePath() {
        dbg("missing implementation")
    }

    open func rect(x: Double, y: Double, w: Double, h: Double) {
        dbg("missing implementation")
    }

    open func fillRect(x: Double, y: Double, w: Double, h: Double) {
        dbg("missing implementation")
    }

    open func strokeRect(x: Double, y: Double, width: Double, height: Double) {
        dbg("missing implementation")
    }

    open func fill() {
        dbg("missing implementation")
    }

    open func stroke() {
        dbg("missing implementation")
    }

    open func clip() {
        dbg("missing implementation")
    }

    open func moveTo(x: Double, y: Double) {
        dbg("missing implementation")
    }

    open func lineTo(x: Double, y: Double) {
        dbg("missing implementation")
    }

    open func fillText(text: String, x: Double, y: Double, maxWidth: Double) {
        dbg("missing implementation")
    }

    open func strokeText(text: String, x: Double, y: Double, maxWidth: Double) {
        dbg("missing implementation")
    }

    open func rotate(angle: Double) {
        dbg("missing implementation")
    }

    open func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
        dbg("missing implementation")
    }

    open func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double) {
        dbg("missing implementation")
    }

    open func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, anticlockwise: Bool) {
        dbg("missing implementation")
    }

    open func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double) {
        dbg("missing implementation")
    }

    open func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double) {
        dbg("missing implementation")
    }

    open func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI? {
        dbg("missing implementation")
        return nil
    }

    open func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI? {
        dbg("missing implementation")
        return nil
    }

    open func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double) {
        dbg("missing implementation")
    }

    open func createImageData(width: Double, height: Double) -> ImageDataAPI? {
        dbg("missing implementation")
        return nil
    }

    open func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI? {
        dbg("missing implementation")
        return nil
    }

    open func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double) {
        dbg("missing implementation")
    }

    open func setLineDash(segments: [Double]) {
        dbg("missing implementation")
    }

    open func getLineDash() -> [Double] {
        dbg("missing implementation")
        return []
    }

    open func isPointInPath(x: Double, y: Double) -> Bool {
        dbg("missing implementation")
        return false
    }

    open func isPointInStroke(x: Double, y: Double) -> Bool {
        dbg("missing implementation")
        return false
    }
}


#if canImport(CoreGraphics)
import CoreGraphics

/// A `Canvas` implementation that uses Apple's CoreGraphics framework to draw into a `CGLayer`.
public class CoreGraphicsCanvas : AbstractCanvasAPI {
}

#endif
