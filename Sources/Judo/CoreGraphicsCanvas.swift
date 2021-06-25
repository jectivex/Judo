import MiscKit

#if canImport(CoreGraphics)
import CoreGraphics

/// A `Canvas` implementation that uses the CoreGraphics framework to draw into a `CGLayer`.
///
/// Most methods are a 1-to-1 mapping to the equivalent `CoreGraphics` APIs.
open class CoreGraphicsCanvas : AbstractCanvasAPI {

    /// The underlying `CGContext` for drawing
    open var ctx: CGContext

    public init(context: CGContext) {
        self.ctx = context
    }

//    /// The transform for flipping along the Y axis
//    var flipYAxis: CGAffineTransform {
//        return CGAffineTransform.identity.translatedBy(x: 0, y: .init(height)).scaledBy(x: 1, y: -1)
//    }
//
//
//    /// Flip vertical since Quartz coordinates have origin at lower-left
//    private func resetTransform() {
//        ctx.concatenate(ctx.ctm.inverted()) // revert to the identity so we can apply the transform…
//        ctx.concatenate(flipYAxis) // …then flip the image so the origin is what Canvas2D expects
//    }

    open override var fillStyle: String {
        didSet {

        }
    }

    open override var strokeStyle: String {
        didSet {
        }
    }

    open override var shadowColor: String {
        didSet {
        }
    }

    open override var shadowBlur: Double {
        didSet {
        }
    }

    open override var shadowOffsetX: Double {
        didSet {
        }
    }

    open override var shadowOffsetY: Double {
        didSet {
        }
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

    open override var miterLimit: Double {
        didSet {
            ctx.setMiterLimit(.init(miterLimit))
        }
    }

    open override var font: String {
        didSet {
        }
    }

    open override var textAlign: String {
        didSet {
        }
    }

    open override var textBaseline: String {
        didSet {
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

    open override var imageSmoothingEnabled: Bool {
        didSet {
        }
    }

    public override func beginPath() {
        ctx.beginPath()
    }
    
    public override func closePath() {
        ctx.closePath()
    }

    /// Perform the given block and then re-set the current path
    private func continuingPath(_ f: () throws -> ()) rethrows {
        // operations like `fillPath` clears the path, so grab a copy to add it back
        let path = ctx.path?.copy()
        try f()
        if let path = path { ctx.addPath(path) } // continue the current path
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
        ctx.clear(CGRect(x: x, y: y, width: w, height: h))
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
        ctx.pathContains(CGPoint(x: x, y: y), mode: .fill)
    }

    public override func isPointInStroke(x: Double, y: Double) -> Bool {
        ctx.pathContains(CGPoint(x: x, y: y), mode: .stroke)
    }

    public override func measureText(value: String) -> TextMetrics? {
        wip(super.measureText(value: value))
    }

    public override func setTransform(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        wip(super.setTransform(a: a, b: b, c: c, d: d, e: e, f: f))
    }

    public override func drawFocusIfNeeded(path: Any, element: Any) {
        wip(super.drawFocusIfNeeded(path: path, element: element))
    }

    public override func getTransform() -> DOMMatrixAPI? {
        wip(super.getTransform())
    }

    public override func scale(x: Double, y: Double) {
        wip(super.scale(x: x, y: y))
    }

    public override func fill() {
        wip(super.fill())
    }

    public override func fillText(text: String, x: Double, y: Double, maxWidth: Double) {
        wip(super.fillText(text: text, x: x, y: y, maxWidth: maxWidth))
    }

    public override func strokeText(text: String, x: Double, y: Double, maxWidth: Double) {
        wip(super.strokeText(text: text, x: x, y: y, maxWidth: maxWidth))
    }

    public override func ellipse(x: Double, y: Double, radiusX: Double, radiusY: Double, rotation: Double, startAngle: Double, endAngle: Double) {
        wip(super.ellipse(x: x, y: y, radiusX: radiusX, radiusY: radiusY, rotation: rotation, startAngle: startAngle, endAngle: endAngle))
    }

    public override func createLinearGradient(x0: Double, y0: Double, x1: Double, y1: Double) -> CanvasGradientAPI? {
        wip(super.createLinearGradient(x0: x0, y0: y0, x1: x1, y1: y1))
    }

    public override func createConicGradient(startAngle: Double, x: Double, y: Double) -> CanvasGradientAPI? {
        wip(super.createConicGradient(startAngle: startAngle, x: x, y: y))
    }

    public override func createPattern(image: Any, repetition: String) -> CanvasPatternAPI? {
        wip(super.createPattern(image: image, repetition: repetition))
    }

    public override func createRadialGradient(x0: Double, y0: Double, r0: Double, x1: Double, y1: Double, r1: Double) -> CanvasGradientAPI? {
        wip(super.createRadialGradient(x0: x0, y0: y0, r0: r0, x1: x1, y1: y1, r1: r1))
    }

    public override func drawImage(image: ImageDataAPI, dx: Double, dy: Double, dWidth: Double, dHeight: Double) {
        wip(super.drawImage(image: image, dx: dx, dy: dy, dWidth: dWidth, dHeight: dHeight))
    }

    public override func createImageData(width: Double, height: Double) -> ImageDataAPI? {
        wip(super.createImageData(width: width, height: height))
    }

    public override func getImageData(sx: Double, sy: Double, sw: Double, sh: Double) -> ImageDataAPI? {
        wip(super.getImageData(sx: sx, sy: sy, sw: sw, sh: sh))
    }

    public override func getContextAttributes() -> CanvasRenderingContext2DSettingsAPI? {
        wip(super.getContextAttributes())
    }

    public override func putImageData(imageData: ImageDataAPI, dx: Double, dy: Double) {
        wip(super.putImageData(imageData: imageData, dx: dx, dy: dy))
    }

    public override func setLineDash(segments: [Double]) {
        wip(super.setLineDash(segments: segments))
    }

    public override func getLineDash() -> [Double] {
        wip(super.getLineDash())
    }

}


extension CoreGraphicsCanvas {
    fileprivate static func createBitmapContext(width: CGFloat, height: CGFloat, scaleFactor: CGFloat = 12.0) throws -> CGContext {
        if width <= 0 || !width.isFinite  { throw err("illegal width \(width)") }
        if height <= 0 || !height.isFinite { throw err("illegal height \(height)") }

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
            throw err("unable to create bitmapContext")
        }

        bitmapContext.scaleBy(x: scaleFactor, y: scaleFactor)

        return bitmapContext
    }

    #warning("re-implement bitmap rendering")
    /// Renders the current canvas layer into a bitmap image and returns the resulting `CGImage`
    fileprivate func createBitmapImage(size: CGSize, scaleFactor: CGFloat, backgroundColor: CGColor?) throws -> CGImage {
        let bitmapContext = try Self.createBitmapContext(width: size.width, height: size.height, scaleFactor: 1.0)

        // place a white background underneath
        if let backgroundColor = backgroundColor {
            bitmapContext.setFillColor(backgroundColor)
            bitmapContext.fill(CGRect(origin: .zero, size: size))
        }

        bitmapContext.scaleBy(x: scaleFactor, y: scaleFactor)


        // draw our layer into the context
        //bitmapContext.draw(layer, at: .zero)
        throw err("TODO: restore thumbnail")

        guard let bitmapImage = bitmapContext.makeImage() else {
            throw err("unable to create bitmapImage from bitmapContext")
        }

        return bitmapImage
    }
}


public class PDFCanvas : CoreGraphicsCanvas {
    private var outputData: NSMutableData
    private let graphicsContext: CGContext

    enum Errors : Error {
        case unableToCreateDataConsumer
        case unableToCreatePDFContext
    }


    /// Creates a new `CoreGraphicsCanvas` that uses an underlying PDF context for drawing.
    ///
    /// - Parameters:
    ///   - properties: and properties to use to create the canvas
    ///   - size: the size of the canvas
    public required init(size: CGSize, properties: [String: Any] = [:]) throws {
        self.outputData = NSMutableData()
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        guard let dataConsumer = CGDataConsumer(data: outputData as CFMutableData) else {
            throw Errors.unableToCreateDataConsumer
        }

        let attrDictionary = NSMutableDictionary()
        for (key, value) in properties {
            attrDictionary[key] = value
        }

        guard let ctx = CGContext(consumer: dataConsumer, mediaBox: &imageRect, attrDictionary) else {
            throw Errors.unableToCreatePDFContext
        }

        self.graphicsContext = ctx
        graphicsContext.beginPDFPage(nil)

//        NSGraphicsContext.saveGraphicsState()
//        defer { NSGraphicsContext.restoreGraphicsState() }
//        NSGraphicsContext.current = NSGraphicsContext(cgContext: cgctx, flipped: false) // use the PDF context for drawing

//        cgctx.beginPDFPage(nil)
//        self.draw(in: imageRect)
//        cgctx.endPage()
//        cgctx.closePDF()
//
//        return outputData


        super.init(context: ctx)
    }

    /// Ends the current PDF context and returns the data. The context should not be used after calling this.
    public func createPDF() -> Data {
        graphicsContext.endPage()
        graphicsContext.closePDF()
        // return PDFDocument(data: outputData as Data)
        return outputData as Data
    }
}

/// Work-in-progress, simply to highlight a line with a deprecation warning
@available(*, deprecated, message: "work-in-progress")
fileprivate func wip<T>(_ value: T) -> T { value }

#endif
