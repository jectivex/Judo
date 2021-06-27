import MiscKit

#if canImport(CoreGraphics)
import CoreGraphics
import CoreText

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit // NSAttributedString additions
import MobileCoreServices // needed for kUTTypePNG on iOS
import ImageIO
#elseif os(macOS)
import AppKit
#endif

/// A `Canvas` implementation that uses the CoreGraphics framework to draw into a destination such as a `CGLayer` or `CGPDFDocument`.
///
/// Most methods are a 1-to-1 mapping to the equivalent `CoreGraphics` APIs.
open class CoreGraphicsCanvas : AbstractCanvasAPI {

    /// The underlying `CGContext` for drawing
    open var ctx: CGContext

    /// The background color to draw for `clearRect`
    open var backgroundColor: CGColor?

    /// The size of the canvas
    open var size: CGSize {
        didSet {
            // every time we change the size, re-apply the transform to fix Quartz's flipped coordinate system
            resetTransform()
        }
    }

    open override var width: Double {
        get {
            Double(size.width)
        }

        set {
            size.width = CGFloat(size.width)
        }
    }

    open override var height: Double {
        get {
            Double(size.height)
        }

        set {
            size.height = CGFloat(size.height)
        }
    }

    /// Creates this canvas with the given underlying context and size
    public init(context: CGContext, size: CGSize, backgroundColor: CGColor? = nil) {
        self.ctx = context
        self.size = size
        self.backgroundColor = backgroundColor
    }

    /// The transform for flipping along the Y axis
    func flippedYTransform() -> CGAffineTransform {
        #if os(macOS)
        return CGAffineTransform.identity.translatedBy(x: 0, y: .init(self.size.height))
            .scaledBy(x: 1, y: -1)
        #else
        return CGAffineTransform.identity
        #endif
    }

    /// Flip vertical since Quartz coordinates have origin at lower-left
    func resetTransform() {
        ctx.concatenate(ctx.ctm.inverted()) // revert to the identity so we can apply the transform…
        ctx.concatenate(flippedYTransform()) // …then flip the image so the origin is what Canvas2D expects
    }

    open override var lineCap: String {
        didSet {
            switch lineCap {
            case "butt": ctx.setLineCap(.butt)
            case "round": ctx.setLineCap(.round)
            case "square": ctx.setLineCap(.square)
            default: break
            }
        }
    }

    open override var lineJoin: String {
        didSet {
            switch lineJoin {
            case "bevel": ctx.setLineJoin(.bevel)
            case "round": ctx.setLineJoin(.round)
            case "miter": ctx.setLineJoin(.miter)
            default: break
            }
        }
    }

    open override var lineWidth: Double {
        didSet {
            ctx.setLineWidth(.init(lineWidth))
        }
    }

    private var lineDashInfo: (segments: [Double], offset: Double) = ([], 0) {
        didSet {
            ctx.setLineDash(phase: .init(lineDashInfo.offset), lengths: lineDashInfo.segments.map({ .init($0) }))
        }
    }

    open override var lineDashOffset: Double {
        get { lineDashInfo.offset }
        set { lineDashInfo.offset = newValue }
    }

    public override func setLineDash(segments: [Double]) {
        lineDashInfo.segments = segments
    }

    public override func getLineDash() -> [Double] {
        lineDashInfo.segments
    }

    open override var miterLimit: Double {
        didSet {
            ctx.setMiterLimit(.init(miterLimit))
        }
    }

    open override var globalAlpha: Double {
        didSet {
            ctx.setAlpha(.init(globalAlpha))
        }
    }

    open override var globalCompositeOperation: String {
        didSet {
            switch globalCompositeOperation {
            case "source-over": ctx.setBlendMode(.normal) // "source over" mode is called `kCGBlendModeNormal'
            case "source-in": ctx.setBlendMode(.sourceIn)
            case "source-out": ctx.setBlendMode(.sourceOut)
            case "source-atop": ctx.setBlendMode(.sourceAtop)
            case "destination-over": ctx.setBlendMode(.destinationOver)
            case "destination-in": ctx.setBlendMode(.destinationIn)
            case "destination-out": ctx.setBlendMode(.destinationOut)
            case "destination-atop": ctx.setBlendMode(.destinationAtop)
            case "lighter": ctx.setBlendMode(.lighten)
            case "copy": ctx.setBlendMode(.copy)
            case "xor": ctx.setBlendMode(.xor)
            case "multiply": ctx.setBlendMode(.multiply)
            case "screen": ctx.setBlendMode(.screen)
            case "overlay": ctx.setBlendMode(.overlay)
            case "darken": ctx.setBlendMode(.darken)
            case "lighten": ctx.setBlendMode(.lighten)
            case "color-dodge": ctx.setBlendMode(.colorDodge)
            case "color-burn": ctx.setBlendMode(.colorBurn)
            case "hard-light": ctx.setBlendMode(.hardLight)
            case "soft-light": ctx.setBlendMode(.softLight)
            case "difference": ctx.setBlendMode(.difference)
            case "exclusion": ctx.setBlendMode(.exclusion)
            case "hue": ctx.setBlendMode(.hue)
            case "saturation": ctx.setBlendMode(.saturation)
            case "color": ctx.setBlendMode(.color)
            case "luminosity": ctx.setBlendMode(.luminosity)
            default: break
            }
        }
    }

    open override var fillStyle: String {
        didSet {
            if let color = CSS.parseColorStyle(css: fillStyle) {
                ctx.setFillColor(color)
            } else {
                ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
    }

    open override var strokeStyle: String {
        didSet {
            if let color = CSS.parseColorStyle(css: strokeStyle) {
                ctx.setStrokeColor(color)
            } else {
                ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
    }

    public override func beginPath() {
        ctx.beginPath()
    }
    
    public override func closePath() {
        ctx.closePath()
    }

    public override func rect(x: Double, y: Double, w: Double, h: Double) {
        ctx.addRect(CGRect(x: x, y: y, width: w, height: h))
    }
    
    public override func fillRect(x: Double, y: Double, w: Double, h: Double) {
        ctx.fill(CGRect(x: x, y: y, width: w, height: h))
    }
    
    public override func stroke() {
        // restore afterwards because “The current path is cleared as a side effect of calling this function"
        continuingPath {
            ctx.strokePath()
        }
    }

    public override func fill() {
        // restore afterwards because “After filling the path, this method clears the context’s current path.”
        continuingPath {
            // fillStyle can be a color, gradient or pattern (unsupported)
//            if let gradient = self.fillStyle as? CanvasGradient {
//                restoringContext {
//                    gradient.fill(context: ctx)
//                }
//            } else {
                ctx.fillPath()
//            }
        }
    }

    public override func save() {
        ctx.saveGState()
    }

    public override func restore() {
        ctx.restoreGState()
    }
    
    public override func clip() {
        ctx.clip()
    }

    public override func clearRect(x: Double, y: Double, w: Double, h: Double) {
        // When this is a PDF context it draws a black background because: “If the provided context is a window or bitmap context, Core Graphics clears the rectangle. For other context types, Core Graphics fills the rectangle in a device-dependent manner. However, you should not use this function in contexts other than window or bitmap contexts.”
        // ctx.clear(.init(x: x, y: y, width: w, height: h))
        self.restoringContext {
            if let backgroundColor = self.backgroundColor {
                ctx.setFillColor(backgroundColor)
                ctx.fill(.init(x: x, y: y, width: w, height: h))
            } else {
                ctx.clear(CGRect(x: x, y: y, width: w, height: h))
            }
        }
    }

    public override func moveTo(x: Double, y: Double) {
        ctx.move(to: CGPoint(x: x, y: y))
    }
    
    public override func lineTo(x: Double, y: Double) {
        ctx.addLine(to: CGPoint(x: x, y: y))
    }
    
    public override func strokeRect(x: Double, y: Double, width: Double, height: Double) {
        ctx.stroke(CGRect(x: x, y: y, width: width, height: height))
    }

    public override func quadraticCurveTo(cpx: Double, cpy: Double, x: Double, y: Double) {
        ctx.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cpx, y: cpy))
    }

    public override func bezierCurveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
        ctx.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: cp1x, y: cp1y), control2: CGPoint(x: cp2x, y: cp2y))
    }
    
    public override func arc(x: Double, y: Double, radius: Double, startAngle: Double, endAngle: Double, anticlockwise: Bool) {
        ctx.addArc(center: CGPoint(x: x, y: y), radius: CGFloat(radius), startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: !anticlockwise) // anti-anticlockwise
    }

    public override func arcTo(x1: Double, y1: Double, x2: Double, y2: Double, radius: Double) {
        ctx.addArc(tangent1End: CGPoint(x: x1, y: y1), tangent2End: CGPoint(x: x2, y: y2), radius: CGFloat(radius))
    }

    public override func rotate(angle: Double) {
        ctx.rotate(by: CGFloat(angle))
    }

    public override func translate(x: Double, y: Double) {
        ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
    }

    public override func transform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        ctx.concatenate(CGAffineTransform(a: CGFloat(a), b: CGFloat(b), c: CGFloat(c), d: CGFloat(d), tx: CGFloat(e), ty: CGFloat(f)))
    }

    public override func isPointInPath(x: Double, y: Double) -> Bool {
        #if os(macOS)
        // TODO: CGContextGetCTM
        #endif
        return ctx.pathContains(CGPoint(x: x, y: y), mode: .fill)
    }

    public override func isPointInStroke(x: Double, y: Double) -> Bool {
        ctx.pathContains(CGPoint(x: x, y: y), mode: .stroke)
    }

    public override func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        resetTransform() // restore the identity (flipped) transform…
        transform(CGFloat(a), CGFloat(b), CGFloat(c), CGFloat(d), CGFloat(e), CGFloat(f)) // …then apply the new transform
    }

    func transform(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat, _ e: CGFloat, _ f: CGFloat) {
        ctx.concatenate(CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f))
    }

    public override func drawFocusIfNeeded(path: Any, element: Any) {
        wipcanvas(super.drawFocusIfNeeded(path: path, element: element))
    }

    public override func getTransform() -> DOMMatrixAPI? {
        wipcanvas(super.getTransform())
    }

    public override func scale(x: Double, y: Double) {
        wipcanvas(super.scale(x: x, y: y))
    }

    public override func measureText(value: String) -> TextMetrics? {
        let astr = NSAttributedString(string: value, attributes: self.textAttributes(stroke: false))
        return TextMetrics(width: .init(astr.size().width))
    }

    public override func fillText(text: String, x: Double, y: Double, maxWidth: Double) {
        renderText(mode: .fill, text, x, y, maxWidth)
    }

    public override func strokeText(text: String, x: Double, y: Double, maxWidth: Double) {
        renderText(mode: .stroke, text, x, y, maxWidth)
    }

    private func renderText(mode: CGTextDrawingMode, _ text: String, _ x: Double, _ y: Double, _ maxWidth: Double) {
        restoringContext {
            self.ctx.concatenate(flippedYTransform().inverted()) // flip back…
            var position = CGPoint(x: x, y: y).applying(flippedYTransform()) // …and re-apply transform to origin
            let astr = NSAttributedString(string: text, attributes: self.textAttributes(stroke: mode == .stroke))
            let width = astr.size().width

            switch self.textAlign {
            case "left": break // nothing to do
            case "center": position.x -= width / 2
            case "right": position.x -= width
            default: break
            }

            self.ctx.textPosition = position
            self.ctx.setTextDrawingMode(mode)
            let line = CTLineCreateWithAttributedString(astr)
            CTLineDraw(line, self.ctx)
        }
    }

    /// Returns the current text attributes for drawing text
    func textAttributes(stroke: Bool? = nil) -> [NSAttributedString.Key: NSObject] {
        var attrs: [NSAttributedString.Key: NSObject] = [:]

        if let font = CSS.parseFontStyle(css: self.font) {
            attrs[NSAttributedString.Key.font] = font
        }

        return attrs
    }

    public override func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double) {
        //ctx.addEllipse(in: <#T##CGRect#>)
        wipcanvas(super.ellipse(x: x, y: y, radiusX: radiusX, radiusY: radiusY, rotation: rotation, startAngle: startAngle, endAngle: endAngle))
    }

    public override func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI? {
        wipgrad(super.createLinearGradient(x0: x0, y0: y0, x1: x1, y1: y1))
    }

    public override func createConicGradient(startAngle: Double, x: Double, y: Double) -> CanvasGradientAPI? {
        wipgrad(super.createConicGradient(startAngle: startAngle, x: x, y: y))
    }

    public override func createPattern(image: Any, repetition: String) -> CanvasPatternAPI? {
        wipgrad(super.createPattern(image: image, repetition: repetition))
    }

    public override func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI? {
        wipgrad(super.createRadialGradient(x0: x0, y0: y0, r0: r0, x1: x1, y1: y1, r1: r1))
    }

    public override func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double) {
        wipgrad(super.drawImage(image: image, dx: dx, dy: dy, dWidth: dWidth, dHeight: dHeight))
    }

    public override func createImageData(width: Double, height: Double) -> ImageDataAPI? {
        wipgrad(super.createImageData(width: width, height: height))
    }

    public override func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI? {
        wipgrad(super.getImageData(sx: sx, sy: sy, sw: sw, sh: sh))
    }

    public override func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double) {
        wipgrad(super.putImageData(imageData: imageData, dx: dx, dy: dy))
    }

    public override func getContextAttributes() -> CanvasRenderingContext2DSettingsAPI? {
        wipcanvas(super.getContextAttributes())
    }


    /// Perform the given block and then restore the context
    private func restoringContext(_ f: () throws -> ()) rethrows {
        save()
        defer { restore() }
        try f()
    }

    /// Perform the given block and then re-set the current path
    private func continuingPath(_ f: () throws -> ()) rethrows {
        // operations like `fillPath` clears the path, so grab a copy to add it back
        let path = ctx.path?.copy()
        defer {
            // continue the current path
            if let path = path {
                ctx.addPath(path)
            }
        }
        try f()
    }
}

extension CoreGraphicsCanvas {
    fileprivate static func createBitmapContext(width: CGFloat, height: CGFloat, scaleFactor: CGFloat = 2.0) -> CGContext? {
        if width <= 0 || !width.isFinite  { return nil }
        if height <= 0 || !height.isFinite { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8

        guard let bitmapContext = CGContext(
            data: nil,
            width: Int(width * scaleFactor),
            height: Int(height * scaleFactor),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }

        bitmapContext.scaleBy(x: scaleFactor, y: scaleFactor)

        return bitmapContext
    }
}

/// A `CoreGraphicsCanvas` subclass that maintains a PDF buffer into which the commands are drawn.
open class PDFCanvas : CoreGraphicsCanvas {
    /// The data buffer the PDF is being written to
    open var outputData: CFMutableData

    public enum Errors : Error {
        case unableToCreateDataConsumer
        case unableToCreatePDFContext
    }


    /// Creates a new `CoreGraphicsCanvas` that uses an underlying PDF context for drawing.
    ///
    /// - Parameters:
    ///   - properties: and properties to use to create the canvas
    ///   - size: the size of the canvas
    public required init(size: CGSize, properties: [String: Any] = [:]) throws {
        self.outputData = NSMutableData() as CFMutableData
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        guard let dataConsumer = CGDataConsumer(data: outputData) else {
            throw Errors.unableToCreateDataConsumer
        }

        let attrDictionary = NSMutableDictionary()
        for (key, value) in properties {
            attrDictionary[key] = value
        }

        guard let ctx = CGContext(consumer: dataConsumer, mediaBox: &imageRect, attrDictionary) else {
            throw Errors.unableToCreatePDFContext
        }

        super.init(context: ctx, size: size)

        ctx.beginPDFPage(nil)
        resetTransform()
    }

    /// Ends the current PDF context and returns the data. The context must not be used after calling this.
    public func finishPDF() -> Data {
        ctx.endPage()
        ctx.closePDF()
        return outputData as Data
    }

    /// Creates a CGPDFDocument document from the given data. The context must not be used after calling this.
    public func createCGPDFDocument() -> CGPDFDocument? {
        CGDataProvider(data: finishPDF() as CFData).flatMap(CGPDFDocument.init)
    }

}

/// A `CoreGraphicsCanvas` subclass that draws into a CGLayer
open class LayerCanvas : CoreGraphicsCanvas {
    open var layer: CGLayer

    public enum Errors : Error {
        case unableToCreateDataConsumer
        case unableToCreateLayer
    }

    public required init(context parentContext: CGContext? = nil, size: CGSize) throws {
        let outputData = NSMutableData()

        let rootContext = try parentContext ?? {
            guard let dataConsumer = CGDataConsumer(data: outputData as CFMutableData) else {
                throw Errors.unableToCreateDataConsumer
            }

            var mediaBox: CGRect = .zero
            guard let ctx = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, nil) else {
                throw Errors.unableToCreateDataConsumer
            }
            return ctx
        }()

        guard let layer = CGLayer(rootContext, size: size, auxiliaryInfo: nil) else {
            throw Errors.unableToCreateLayer
        }

        assert(layer.context != rootContext, "CGLayer's context should have differed from root")

        guard let ctx = layer.context else {
            throw Errors.unableToCreateLayer
        }

        self.layer = layer

        // note that we use the layer's context for drawing, not the parent context
        super.init(context: ctx, size: size)
    }

    /// Renders the current canvas layer into a bitmap image and returns the resulting `CGImage`
    func createBitmapImage(scaleFactor: CGFloat = 1.0) -> CGImage? {
        guard let bitmapContext = CoreGraphicsCanvas.createBitmapContext(width: .init(self.size.width), height: .init(self.size.height), scaleFactor: scaleFactor) else {
            return nil
        }

        // place a white background underneath
        if let backgroundColor = self.backgroundColor {
            bitmapContext.setFillColor(backgroundColor)
            bitmapContext.fill(CGRect(origin: .zero, size: layer.size))
        }

        if scaleFactor != 1.0 {
            bitmapContext.scaleBy(x: scaleFactor, y: scaleFactor)
        }

        bitmapContext.concatenate(flippedYTransform())

        // draw our layer into the context
        bitmapContext.draw(self.layer, at: .zero)

        return bitmapContext.makeImage()
    }
}

extension LayerCanvas {
    /// Creates image data for the canvas in the given format
    func createImageData(type: CFString, scaleFactor: CGFloat = 2.0) -> Data? {
        guard let img = createBitmapImage(scaleFactor: scaleFactor) else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, type, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, img, nil)
        if !CGImageDestinationFinalize(dest) { return nil }
        return data as Data
    }
}

extension LayerCanvas {
    /// Creates image data for the canvas in PNG format
    public func createPNGData() -> Data? {
        createImageData(type: kUTTypePNG)
    }

    /// Creates image data for the canvas in JPEG format
    public func createJPEGData() -> Data? {
        createImageData(type: kUTTypeJPEG)
    }
}


// MARK: Utilities

/// Work-in-progress, simply to highlight a line with a deprecation warning
@available(*, deprecated, message: "work-in-progress")
fileprivate func wip<T>(_ value: T) -> T { value }

/// Work-in-progress for gradientd, simply to highlight a line with a deprecation warning
/// - TODO: @available(*, deprecated, message: "work-in-progress")
fileprivate func wipgrad<T>(_ value: T) -> T { value }

#endif


