//
//  OffscreenCanvas.swift
//  Glance
//
//  Created by Marc Prud'hommeaux on 7/21/15.

import JXKit
import MiscKit

public protocol CanvasAPI : AnyObject {
//    var width: Double { get set }
//
//    var height: Double { get set }

    /// The color, gradient, or pattern to use inside shapes.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle)
    var fillStyle: String { get set }

    /// The color, gradient, or pattern to use for the strokes (outlines) around shapes.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeStyle)
    var strokeStyle: String { get set }

    /// The color of shadows
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowColor)
    var shadowColor: String { get set }

    /// The amount of blur applied to shadows.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur)
    var shadowBlur: Double { get set }

    /// The distance that shadows will be offset horizontally.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetX)
    var shadowOffsetX: Double { get set }

    /// The distance that shadows will be offset vertically.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowOffsetY)
    var shadowOffsetY: Double { get set }

    /// The shape used to draw the end points of lines.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap)
    var lineCap: String { get set }

    /// The shape used to join two line segments where they meet.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineJoin)
    var lineJoin: String { get set }

    /// The thickness of lines.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineWidth)
    var lineWidth: Double { get set }

    /// Sets the line dash offset, or "phase."
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineDashOffset)
    var lineDashOffset: Double { get set }

    /// The miter limit ratio.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/miterLimit)
    var miterLimit: Double { get set }

    /// The current text style to use when drawing text. This string uses the same syntax as the CSS font specifier.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/font)
    var font: String { get set }

    /// The current text alignment used when drawing text.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textAlign)
    var textAlign: String { get set }

    /// The current text baseline used when drawing text.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/textBaseline)
    var textBaseline: String { get set }

    /// The alpha (transparency) value that is applied to shapes and images before they are drawn onto the canvas.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalAlpha)
    var globalAlpha: Double { get set }

    /// The type of compositing operation to apply when drawing new shapes.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation)
    var globalCompositeOperation: String { get set }

    /// The imageSmoothingEnabled property of the CanvasRenderingContext2D interface, part of the Canvas API, determines whether scaled images are smoothed (true, default) or not (false). On getting the imageSmoothingEnabled property, the last value it was set to is returned.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/imageSmoothingEnabled)
    var imageSmoothingEnabled: Bool { get set }


    /// Returns a TextMetrics object that contains information about the measured text (such as its width, for example).
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/measureText)
    func measureText(value: String) -> TextMetrics?

    /// Resets (overrides) the current transformation to the identity matrix, and then invokes a transformation described by the arguments of this method.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform)
    func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Multiplies the current transformation with the matrix described by the arguments of this method.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform)
    func transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Saves the entire state of the canvas by pushing the current state onto a stack.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/save)
    func save()

    /// Restores the most recently saved canvas state by popping the top entry in the drawing state stack. If there is no saved state, this method does nothing.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/restore)
    func restore()

    /// Erases the pixels in a rectangular area by setting them to transparent black.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clearRect)
    func clearRect(x: Double, y: Double, w: Double, h: Double)

    /// Adds a translation transformation to the current matrix.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/translate)
    func translate(x: Double, y: Double)

    /// Starts a new path by emptying the list of sub-paths. Call this method when you want to create a new path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/beginPath)
    func beginPath()

    /// Attempts to add a straight line from the current point to the start of the current sub-path. If the shape has already been closed or has only one point, this function does nothing.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/closePath)
    func closePath()

    /// Draws a focus ring around the current or given path, if the specified element is focused.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawFocusIfNeeded)
    func drawFocusIfNeeded(path: Any, element: Any)

    /// Retrieves the current transformation matrix being applied to the context.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getTransform)
    func getTransform() -> DOMMatrixAPI?

    /// Adds a scaling transformation to the canvas units horizontally and/or vertically.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/scale)
    func scale(x: Double, y: Double)

    /// Adds a rectangle to the current path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rect)
    func rect(x: Double, y: Double, w: Double, h: Double)

    /// Draws a rectangle that is filled according to the current fillStyle.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillRect)
    func fillRect(x: Double, y: Double, w: Double, h: Double)

    /// Draws a rectangle that is stroked (outlined) according to the current strokeStyle and other context settings.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeRect)
    func strokeRect(x: Double, y: Double, width: Double, height: Double)

    /// Fills the current or given path with the current fillStyle.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fill)
    func fill()

    /// Strokes (outlines) the current or given path with the current stroke style.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/stroke)
    func stroke()

    /// Turns the current or given path into the current clipping region. It replaces any previous clipping region.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/clip)
    func clip()

    /// Begins a new sub-path at the point specified by the given (x, y) coordinates.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/moveTo)
    func moveTo(x: Double, y: Double)

    /// Adds a straight line to the current sub-path by connecting the sub-path's last point to the specified (x, y) coordinates.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineTo)
    func lineTo(x: Double, y: Double)

    /// Draws a text string at the specified coordinates, filling the string's characters with the current fillStyle.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillText)
    func fillText(text: String, x: Double, y: Double, maxWidth: Double)

    /// Strokes — that is, draws the outlines of — the characters of a text string at the specified coordinates.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeText)
    func strokeText(text: String, x: Double, y: Double, maxWidth: Double)

    /// Adds a rotation to the transformation matrix.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rotate)
    func rotate(angle: Double)

    /// Adds a cubic Bézier curve to the current sub-path. It requires three points: the first two are control points and the third one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the Bézier curve.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/bezierCurveTo)
    func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double)

    /// adds a quadratic Bézier curve to the current sub-path. It requires two points: the first one is a control point and the second one is the end point. The starting point is the latest point in the current path, which can be changed using moveTo() before creating the quadratic Bézier curve.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/quadraticCurveTo)
    func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double)

    /// Adds a circular arc to the current sub-path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arc)
    func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, anticlockwise: Bool)

    /// Adds a circular arc to the current sub-path, using the given control points and radius.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arcTo)
    func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double)

    /// Adds an elliptical arc to the current sub-path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/ellipse)
    func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double)

    /// Creates a gradient along the line connecting two given coordinates.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createLinearGradient)
    func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI?

    /// Creates a gradient around a point with given coordinates
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createConicGradient)
    func createConicGradient(startAngle: Double, x: Double, y: Double) -> CanvasGradientAPI?

    /// Creates a pattern using the specified image and repetition.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createPattern)
    func createPattern(image: Any, repetition: String) -> CanvasPatternAPI?

    /// Creates a radial gradient using the size and coordinates of two circles.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient)
    func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI?

    /// Provides different ways to draw an image onto the canvas.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/drawImage)
    func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double)

    /// Creates a new, blank ImageData object with the specified dimensions.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createImageData)
    func createImageData(width: Double, height: Double) -> ImageDataAPI?

    /// Returns an ImageData object representing the underlying pixel data for a specified portion of the canvas.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getImageData)
    func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI?

    /// returns an object that contains the actual context parameters. Context attributes can be requested with HTMLCanvasElement.getContext() on context creation.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getContextAttributes)
    func getContextAttributes() -> CanvasRenderingContext2DSettingsAPI?


    /// Paints data from the given ImageData object onto the canvas.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/putImageData)
    func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double)

    /// Sets the line dash pattern used when stroking lines.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setLineDash)
    func setLineDash(segments: [Double])

    /// Gets the current line dash pattern.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getLineDash)
    func getLineDash() -> [Double]

    /// Reports whether or not the specified point is contained in the current path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInPath)
    func isPointInPath(x: Double, y: Double) -> Bool

    /// Reports whether or not the specified point is inside the area contained by the stroking of a path.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/isPointInStroke)
    func isPointInStroke(x: Double, y: Double) -> Bool
}


/// A structure describing text measurments.
///
/// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/TextMetrics)
public struct TextMetrics : Codable {
    /// TextMetrics.width Read only
    /// Is a double giving the calculated width of a segment of inline text in CSS pixels. It takes into account the current font of the context.
    public var width: Double

    /// TextMetrics.actualBoundingBoxLeft Read only
    /// Is a double giving the distance from the alignment point given by the CanvasRenderingContext2D.textAlign property to the left side of the bounding rectangle of the given text, in CSS pixels. The distance is measured parallel to the baseline.
    public var actualBoundingBoxLeft: Double?

    /// TextMetrics.actualBoundingBoxRight Read only
    /// Is a double giving the distance from the alignment point given by the CanvasRenderingContext2D.textAlign property to the right side of the bounding rectangle of the given text, in CSS pixels. The distance is measured parallel to the baseline.
    public var actualBoundingBoxRight: Double?

    /// TextMetrics.fontBoundingBoxAscent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline attribute to the top of the highest bounding rectangle of all the fonts used to render the text, in CSS pixels.
    public var fontBoundingBoxAscent: Double?

    /// TextMetrics.fontBoundingBoxDescent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline attribute to the bottom of the bounding rectangle of all the fonts used to render the text, in CSS pixels.
    public var fontBoundingBoxDescent: Double?

    /// TextMetrics.actualBoundingBoxAscent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline attribute to the top of the bounding rectangle used to render the text, in CSS pixels.
    public var actualBoundingBoxAscent: Double?

    /// TextMetrics.actualBoundingBoxDescent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline attribute to the bottom of the bounding rectangle used to render the text, in CSS pixels.
    public var actualBoundingBoxDescent: Double?

    /// TextMetrics.emHeightAscent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline property to the top of the em square in the line box, in CSS pixels.
    public var emHeightAscent: Double?

    /// TextMetrics.emHeightDescent Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline property to the bottom of the em square in the line box, in CSS pixels.
    public var emHeightDescent: Double?

    /// TextMetrics.hangingBaseline Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline property to the hanging baseline of the line box, in CSS pixels.
    public var hangingBaseline: Double?

    /// TextMetrics.alphabeticBaseline Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline property to the alphabetic baseline of the line box, in CSS pixels.
    public var alphabeticBaseline: Double?

    /// TextMetrics.ideographicBaseline Read only
    /// Is a double giving the distance from the horizontal line indicated by the CanvasRenderingContext2D.textBaseline property to the ideographic baseline of the line box, in CSS pixels.
    public var ideographicBaseline: Double?

    public init(width: Double, actualBoundingBoxLeft: Double? = nil, actualBoundingBoxRight: Double? = nil, fontBoundingBoxAscent: Double? = nil, fontBoundingBoxDescent: Double? = nil, actualBoundingBoxAscent: Double? = nil, actualBoundingBoxDescent: Double? = nil, emHeightAscent: Double? = nil, emHeightDescent: Double? = nil, hangingBaseline: Double? = nil, alphabeticBaseline: Double? = nil, ideographicBaseline: Double? = nil) {
        self.width = width
        self.actualBoundingBoxLeft = actualBoundingBoxLeft
        self.actualBoundingBoxRight = actualBoundingBoxRight
        self.fontBoundingBoxAscent = fontBoundingBoxAscent
        self.fontBoundingBoxDescent = fontBoundingBoxDescent
        self.actualBoundingBoxAscent = actualBoundingBoxAscent
        self.actualBoundingBoxDescent = actualBoundingBoxDescent
        self.emHeightAscent = emHeightAscent
        self.emHeightDescent = emHeightDescent
        self.hangingBaseline = hangingBaseline
        self.alphabeticBaseline = alphabeticBaseline
        self.ideographicBaseline = ideographicBaseline
    }
}

/// The CanvasGradient interface represents an opaque object describing a gradient. It is returned by the methods CanvasRenderingContext2D.createLinearGradient() or CanvasRenderingContext2D.createRadialGradient().
///
/// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient)
public protocol CanvasGradientAPI : AnyObject {
    /// adds a new color stop, defined by an offset and a color, to a given canvas gradient.
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasGradient/addColorStop)
    func addColorStop(offset: Double, color: String)
}

public protocol CanvasPatternAPI : AnyObject {
    /// Applies an SVGMatrix or DOMMatrix representing a linear transform to the pattern
    ///
    /// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/CanvasPattern/setTransform)
    func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
}

public protocol ImageDataAPI : AnyObject {
}

public protocol CanvasRenderingContext2DSettingsAPI : AnyObject {
}

/// TBD: since this isn't live, should we make it a struct?
///
/// See: [MDN](https://developer.mozilla.org/en-US/docs/Web/API/DOMMatrix)
public protocol DOMMatrixAPI : AnyObject {
}


/// A base class for an implementation of the CanvasAPI to be exposed to a `JXContext`, thereby allowing the use of Canvas2D.
///
/// This class synthesizes the JavaScript properties and functions that are exposed by Canvas2D. Sublcasses are expected to implement the actual drawing calls for the CanvasAPI protocol, which can be either immediate-mode or stored.
///
/// See: [Canvas API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
open class Canvas : JXValue {
    let delegate: CanvasAPI

    // This initializer hooks up the methods and properties of a `CanvasRenderingContext2D` instance in the given environment to the underlying `CanvasAPI` delegate implementation
    public required init(env: JXContext, delegate: CanvasAPI) throws {
        self.delegate = delegate

        //super.init(newObjectIn: env) // needs to be a
        super.init(env: env, value: env.object().value)

        func addString(property: String, keyPath: ReferenceWritableKeyPath<CanvasAPI, String>) {
            defineProperty(property, JXProperty(getter: { this in
                this.env.string(delegate[keyPath: keyPath])
            }, setter: { this, newValue in
                delegate[keyPath: keyPath] = newValue.stringValue ?? delegate[keyPath: keyPath]
            }, configurable: true, enumerable: true))
        }

        func addNumber(property: String, keyPath: ReferenceWritableKeyPath<CanvasAPI, Double>) {
            defineProperty(property, JXProperty(getter: { this in
                this.env.number(delegate[keyPath: keyPath])
            }, setter: { this, newValue in
                delegate[keyPath: keyPath] = newValue.numberValue ?? delegate[keyPath: keyPath]
            }, configurable: true, enumerable: true))
        }

        func addBoolean(property: String, keyPath: ReferenceWritableKeyPath<CanvasAPI, Bool>) {
            defineProperty(property, JXProperty(getter: { this in
                this.env.boolean(delegate[keyPath: keyPath])
            }, setter: { this, newValue in
                delegate[keyPath: keyPath] = newValue.isBoolean ? newValue.booleanValue :  delegate[keyPath: keyPath]
            }, configurable: true, enumerable: true))
        }


//        addNumber(property: "width", keyPath: \.width)
//        addNumber(property: "height", keyPath: \.height)

        addString(property: "fillStyle", keyPath: \.fillStyle)
        addString(property: "font", keyPath: \.font)
        addNumber(property: "globalAlpha", keyPath: \.globalAlpha)
        addString(property: "globalCompositeOperation", keyPath: \.globalCompositeOperation)
        addBoolean(property: "imageSmoothingEnabled", keyPath: \.imageSmoothingEnabled)

        addString(property: "lineCap", keyPath: \.lineCap)
        addNumber(property: "lineDashOffset", keyPath: \.lineDashOffset)
        addString(property: "lineJoin", keyPath: \.lineJoin)
        addNumber(property: "lineWidth", keyPath: \.lineWidth)
        addNumber(property: "miterLimit", keyPath: \.miterLimit)

        addNumber(property: "shadowBlur", keyPath: \.shadowBlur)
        addString(property: "shadowColor", keyPath: \.shadowColor)
        addNumber(property: "shadowOffsetX", keyPath: \.shadowOffsetX)
        addNumber(property: "shadowOffsetY", keyPath: \.shadowOffsetY)

        addString(property: "strokeStyle", keyPath: \.strokeStyle)
        addString(property: "textAlign", keyPath: \.textAlign)
        addString(property: "textBaseline", keyPath: \.textBaseline)

        let shim = false

        try addFunction("measureText", shim: shim) { env, this, args in
            do {
                return try env.encode(delegate.measureText(value: args.first?.stringValue ?? ""))
            } catch {
                // this will only happen on an encode error, which should never happen
                dbg("encoding error:", error)
                return env.undefined()
            }
        }

        try addFunction("arc", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.arcTo(x1: narg(at: 0), y1: narg(at: 1), x2: narg(at: 2), y2: narg(at: 3), radius: narg(at: 4))
            return env.undefined()
        }

        try addFunction("arcTo", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.arcTo(x1: narg(at: 0), y1: narg(at: 1), x2: narg(at: 2), y2: narg(at: 3), radius: narg(at: 4))
            return env.undefined()
        }

        try addFunction("beginPath", shim: shim) { env, this, args in
            delegate.beginPath()
            return env.undefined()
        }

        try addFunction("bezierCurveTo", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.bezierCurveTo(cp1x: narg(at: 0), cp1y: narg(at: 1), cp2x: narg(at: 2), cp2y: narg(at: 3), x: narg(at: 4), y: narg(at: 5))
            return env.undefined()
        }

        try addFunction("clearRect", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.clearRect(x: narg(at: 0), y: narg(at: 1), w: narg(at: 2), h: narg(at: 3))
            return env.undefined()
        }

        try addFunction("clip", shim: shim) { env, this, args in
            delegate.clip()
            return env.undefined()
        }

        try addFunction("closePath", shim: shim) { env, this, args in
            delegate.closePath()
            return env.undefined()
        }

        try addFunction("ellipse", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.ellipse(x: narg(at: 0), y: narg(at: 1), radiusX: narg(at: 2), radiusY: narg(at: 3), rotation: narg(at: 4), startAngle: narg(at: 5), endAngle: narg(at: 6))
            return env.undefined()
        }

        try addFunction("fill", shim: shim) { env, this, args in
            delegate.fill()
            return env.undefined()
        }

        try addFunction("fillRect", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.fillRect(x: narg(at: 0), y: narg(at: 1), w: narg(at: 2), h: narg(at: 3))
            return env.undefined()
        }

        try addFunction("fillText", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            func sarg(at index: Int) -> String { arg(at: index)?.stringValue ?? "" }
            delegate.fillText(text: sarg(at: 0), x: narg(at: 1), y: narg(at: 2), maxWidth: narg(at: 3))
            return env.undefined()
        }
        try addFunction("isPointInPath", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            return env.boolean(delegate.isPointInPath(x: narg(at: 0), y: narg(at: 1)))
        }

        try addFunction("isPointInStroke", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            return env.boolean(delegate.isPointInStroke(x: narg(at: 0), y: narg(at: 1)))
        }

        try addFunction("lineTo", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.lineTo(x: narg(at: 0), y: narg(at: 1))
            return env.undefined()
        }

        try addFunction("moveTo", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.moveTo(x: narg(at: 0), y: narg(at: 1))
            return env.undefined()
        }

        try addFunction("quadraticCurveTo", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.quadraticCurveTo(cpx: narg(at: 0), cpy: narg(at: 1), x: narg(at: 2), y: narg(at: 3))
            return env.undefined()
        }

        try addFunction("rect", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.rect(x: narg(at: 0), y: narg(at: 1), w: narg(at: 2), h: narg(at: 3))
            return env.undefined()
        }

        try addFunction("restore", shim: shim) { env, this, args in
            delegate.restore()
            return env.undefined()
        }

        try addFunction("rotate", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.rotate(angle: narg(at: 0))
            return env.undefined()
        }

        try addFunction("save", shim: shim) { env, this, args in
            delegate.save()
            return env.undefined()
        }

        try addFunction("scale", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.scale(x: narg(at: 0), y: narg(at: 1))
            return env.undefined()
        }

        try addFunction("getLineDash", shim: shim) { env, this, args in
            env.array(delegate.getLineDash().map(env.number))
        }

        try addFunction("setLineDash", shim: shim) { env, this, args in
            let f = delegate.setLineDash
            return env.undefined()
        }

        try addFunction("setTransform", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.setTransform(a: narg(at: 0), b: narg(at: 1), c: narg(at: 2), d: narg(at: 3), e: narg(at: 4), f: narg(at: 5))
            return env.undefined()
        }

        try addFunction("stroke", shim: shim) { env, this, args in
            delegate.stroke()
            return env.undefined()
        }

        try addFunction("strokeRect", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.strokeRect(x: narg(at: 0), y: narg(at: 1), width: narg(at: 2), height: narg(at: 3))
            return env.undefined()
        }

        try addFunction("strokeText", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            func sarg(at index: Int) -> String { arg(at: index)?.stringValue ?? "" }
            delegate.strokeText(text: sarg(at: 0), x: narg(at: 1), y: narg(at: 2), maxWidth: narg(at: 3))
            return env.undefined()
        }

        try addFunction("transform", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.transform(a: narg(at: 0), b: narg(at: 1), c: narg(at: 2), d: narg(at: 3), e: narg(at: 4), f: narg(at: 5))
            return env.undefined()
        }

        try addFunction("translate", shim: shim) { env, this, args in
            func arg(at index: Int) -> JXValue? { index < args.count ? args[index] : nil }
            func narg(at index: Int) -> Double { arg(at: index)?.numberValue ?? .nan }
            delegate.translate(x: narg(at: 0), y: narg(at: 1))
            return env.undefined()
        }

        try addFunction("createConicGradient", shim: shim) { env, this, args in
            let f = delegate.createConicGradient
            return env.undefined()
        }

        try addFunction("createImageData", shim: shim) { env, this, args in
            let f = delegate.createImageData
            return env.undefined()
        }

        try addFunction("createLinearGradient", shim: shim) { env, this, args in
            let f = delegate.createLinearGradient
            return env.undefined()
        }

        try addFunction("createPattern", shim: shim) { env, this, args in
            let f = delegate.createPattern
            return env.undefined()
        }

        try addFunction("createRadialGradient", shim: shim) { env, this, args in
            let f = delegate.createRadialGradient
            return env.undefined()
        }

        try addFunction("drawFocusIfNeeded", shim: shim) { env, this, args in
            let f = delegate.drawFocusIfNeeded
            return env.undefined()
        }

        try addFunction("drawImage", shim: shim) { env, this, args in
            let f = delegate.drawImage
            return env.undefined()
        }


        try addFunction("getContextAttributes", shim: shim) { env, this, args in
            let f = delegate.getContextAttributes
            return env.undefined()
        }

        try addFunction("getImageData", shim: shim) { env, this, args in
            let f = delegate.getImageData
            return env.undefined()
        }

        // MARK: To Be Implemented

        try addFunction("getTransform", shim: shim) { env, this, args in
            let f = delegate.getTransform
            return env.undefined()
        }


        try addFunction("putImageData", shim: shim) { env, this, args in
            let f = delegate.putImageData
            return env.undefined()
        }



        // experimental and/or deprecated
        //try addFunction("addHitRegion", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //try addFunction("clearHitRegions", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //
        //
        //try addFunction("drawWidgetAsOnScreen", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //
        //try addFunction("drawWindow", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //try addFunction("removeHitRegion", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //
        //try addFunction("resetTransform", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
        //
        //try addFunction("scrollPathIntoView", shim: shim) { env, this, args in
        //    return env.undefined()
        //}
    }
}

//extension Canvas {
//    /// Adds a property to the canvas
//    func addProperty(named propertyName: String, path: ReferenceWritableKeyPath<Canvas, JXValue>) {
//        defineProperty(propertyName, JXProperty(getter: { [weak self] val in
//            self?[keyPath: path] ?? val.env.undefined()
//        }, setter: { [weak self] in
//            self?[keyPath: path] = $1
//        }, configurable: true, enumerable: true))
//    }
//}

/// An abstract `CanvasAPI` implementation that provides empty implementations for the requires properties and functions.
///
/// Partial implementations can subclass this class and implement only the parts they need.
open class AbstractCanvasAPI : CanvasAPI {
    open var fillStyle: String = "#000"
    open var font: String = "10px sans-serif"
    open var globalAlpha: Double = 1.0
    open var globalCompositeOperation: String = "source-over"
    open var imageSmoothingEnabled: Bool = true

    open var lineCap: String = "butt"
    open var lineDashOffset: Double = 0.0
    open var lineJoin: String = "miter"
    open var lineWidth: Double = 1.0
    open var miterLimit: Double = 10.0

    open var shadowBlur: Double = 0
    open var shadowColor: String = "rgba(0, 0, 0, 0)" // WebKit's version of: "The default value is fully-transparent black"
    open var shadowOffsetX: Double = 0
    open var shadowOffsetY: Double = 0

    open var strokeStyle: String = "#000"
    open var textAlign: String = "start"
    open var textBaseline: String = "alphabetic"

    public init() {
    }

    /// Default implementation of `CanvasAPI.measureText` that does nothing and returns `undefined()`
    open func measureText(value: String) -> TextMetrics? {
        /// Text measurement merely returns the number of characters in the text multiplied by the font size
        // naïve font size parsing: just grab the first numbers in the font string
        let fontSize = font
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .first.flatMap(Double.init)
        let factor = 0.8
        return TextMetrics(width: (fontSize ?? 0) * Double(value.count) * factor)
    }

    /// Default implementation of `CanvasAPI.setTransform` that does nothing and returns `undefined()`
    open func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.transform` that does nothing and returns `undefined()`
    open func transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.save` that does nothing and returns `undefined()`
    open func save() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.restore` that does nothing and returns `undefined()`
    open func restore() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.clearRect` that does nothing and returns `undefined()`
    open func clearRect(x: Double, y: Double, w: Double, h: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.translate` that does nothing and returns `undefined()`
    open func translate(x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.beginPath` that does nothing and returns `undefined()`
    open func beginPath() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.closePath` that does nothing and returns `undefined()`
    open func closePath() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.rect` that does nothing and returns `undefined()`
    open func rect(x: Double, y: Double, w: Double, h: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.fillRect` that does nothing and returns `undefined()`
    open func fillRect(x: Double, y: Double, w: Double, h: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.strokeRect` that does nothing and returns `undefined()`
    open func strokeRect(x: Double, y: Double, width: Double, height: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.fill` that does nothing and returns `undefined()`
    open func fill() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.stroke` that does nothing and returns `undefined()`
    open func stroke() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.clip` that does nothing and returns `undefined()`
    open func clip() {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.moveTo` that does nothing and returns `undefined()`
    open func moveTo(x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.lineTo` that does nothing and returns `undefined()`
    open func lineTo(x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.fillText` that does nothing and returns `undefined()`
    open func fillText(text: String, x: Double, y: Double, maxWidth: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.strokeText` that does nothing and returns `undefined()`
    open func strokeText(text: String, x: Double, y: Double, maxWidth: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.rotate` that does nothing and returns `undefined()`
    open func rotate(angle: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.bezierCurveTo` that does nothing and returns `undefined()`
    open func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.quadraticCurveTo` that does nothing and returns `undefined()`
    open func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.arc` that does nothing and returns `undefined()`
    open func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, anticlockwise: Bool) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.arcTo` that does nothing and returns `undefined()`
    open func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.ellipse` that does nothing and returns `undefined()`
    open func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.createLinearGradient` that does nothing and returns `undefined()`
    open func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.createRadialGradient` that does nothing and returns `undefined()`
    open func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.XXX` that does nothing and returns `undefined()`
    open func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.createImageData` that does nothing and returns `undefined()`
    open func createImageData(width: Double, height: Double) -> ImageDataAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.getImageData` that does nothing and returns `undefined()`
    open func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.putImageData` that does nothing and returns `undefined()`
    open func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.setLineDash` that does nothing and returns `undefined()`
    open func setLineDash(segments: [Double]) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.getLineDash` that does nothing and returns `undefined()`
    open func getLineDash() -> [Double] {
        missingImplementation(returning: [])
    }

    /// Default implementation of `CanvasAPI.isPointInPath` that does nothing and returns `undefined()`
    open func isPointInPath(x: Double, y: Double) -> Bool {
        missingImplementation(returning: false)
    }

    /// Default implementation of `CanvasAPI.isPointInStroke` that does nothing and returns `undefined()`
    open func isPointInStroke(x: Double, y: Double) -> Bool {
        missingImplementation(returning: false)
    }

    /// Default implementation of `CanvasAPI.drawFocusIfNeeded` that does nothing and returns `undefined()`
    open func drawFocusIfNeeded(path: Any, element: Any) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.getTransform` that does nothing and returns `undefined()`
    open func getTransform() -> DOMMatrixAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.scale` that does nothing and returns `undefined()`
    open func scale(x: Double, y: Double) {
        missingImplementation(returning: ())
    }

    /// Default implementation of `CanvasAPI.createConicGradient` that does nothing and returns `undefined()`
    open func createConicGradient(startAngle: Double, x: Double, y: Double) -> CanvasGradientAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.createPattern` that does nothing and returns `undefined()`
    open func createPattern(image: Any, repetition: String) -> CanvasPatternAPI? {
        missingImplementation(returning: nil)
    }

    /// Default implementation of `CanvasAPI.getContextAttributes` that does nothing and returns `undefined()`
    open func getContextAttributes() -> CanvasRenderingContext2DSettingsAPI? {
        missingImplementation(returning: nil)
    }

    /// The callback for a missing implementation; merely logs the occurance
    open func missingImplementation<T>(for function: StaticString = #function, returning returnValue: T) -> T {
        dbg(function)
        return returnValue
    }
}

