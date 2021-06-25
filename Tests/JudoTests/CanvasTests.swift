import Foundation
import Judo
import XCTest

final class CanvasTests: XCTestCase {
    func testAbstractCanvasAPI() throws {
        let ctx = JXContext()
        let api = AbstractCanvasAPI()
        let canvas = try Canvas(env: ctx, delegate: api)

        do { // check font property
            XCTAssertEqual("10px sans-serif", api.font)
            try ctx.eval(this: canvas, script: "this.font = '18px serif';")
            XCTAssertEqual("18px serif", api.font)
        }

        XCTAssertTrue(canvas["measureText"].isFunction)
        XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)

        XCTAssertEqual(3 * 18 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)

        try ctx.eval(this: canvas, script: "this.font = '13px serif';")

        XCTAssertEqual(5 * 13 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('12345').width").numberValue)
    }
}


final class CSSTests : XCTestCase {
    /// Compare our CSS font parsing output with WebKit's (via NSAttributedString(html:), which is only available on macOS).
    /// This will validate our own cross-platform font parsing using WebKit's behavior as a reference.
    func testColorParsing() throws {
        func components(_ css: String, parser: (String) -> CGColor?) -> [Double]? {
            // compare AppKit with non-AppKit
            guard let c = parser(css) else { return nil }


            if c.numberOfComponents != 4 { return nil }
            let comps = c.components ?? []
            return [Double(round(comps[0] * 10)/10), Double(round(comps[1] * 10)/10), Double(round(comps[2] * 10)/10), Double(round(comps[3] * 10)/10)]
        }

        ///
        func comps(_ css: String) -> [Double]? {
            let n1 = components(css, parser: CSS.parseColorStyleWebKit(css:))
            let n2 = components(css, parser: CSS.parseColorStyleNative(css:))
            XCTAssertEqual(n1, n2, "native and emulated parsing did not match")
            return n1
        }

        XCTAssertEqual([1.0, 0.0, 0.0, 1.0], comps("red"))
        XCTAssertEqual([0.0, 0.0, 1.0, 1.0], comps("blue"))
        XCTAssertEqual([0.0, 0.5, 0.0, 1.0], comps("green"))
        XCTAssertEqual([0.6, 0.9, 0.6, 1.0], comps("lightgreen"))
        XCTAssertEqual([0.0, 0.4, 0.0, 1.0], comps("darkgreen"))

        XCTAssertEqual([0.3, 0.0, 0.5, 1.0], comps("indigo"))
        XCTAssertEqual([0.9, 0.5, 0.9, 1.0], comps("violet"))
        XCTAssertEqual([0.4, 0.2, 0.6, 1.0], comps("rebeccapurple"))

        XCTAssertEqual([1.0, 0.0, 0.0, 1.0], comps("#F00"))
        XCTAssertEqual([1.0, 0.7, 0.2, 1.0], comps("#FFAB31"))
        XCTAssertEqual([1.0, 0.2, 0.0, 1.0], comps("rgb(100%, 22%, 0%)"))

        XCTAssertEqual([1.0, 0.0, 0.0, 0.5], comps("rgba(255, 0, 0, 0.5)"))
        XCTAssertEqual([1.0, 0.0, 0.0, 0.5], comps("rgba(255, 0, 0, 50%)"))

        XCTAssertEqual([0.0, 0.0, 0.0, 1.0], comps("rgb(0,0,0)"))
        XCTAssertEqual([0.5, 0.3, 0.1, 1.0], comps("rgb(  137,78,36)"))
        XCTAssertEqual([0.9, 0.1, 0.1, 1.0], comps("rgb(220, 36,30)"))
        XCTAssertEqual([1.0, 0.8, 0.0, 1.0], comps("rgb(255,206,     0)"))

        XCTAssertEqual([1.0, 0.8, 0.0, 0.3], comps("rgba(255,206,0, 0.3)"))
        XCTAssertEqual([1.0, 0.8, 0.0, 0.3], comps("rgba(255,206,0, 33%)"))

        // HSL parsing works, but it isn't exactly the same as WebKit
//        XCTAssertEqual([0.3, 0.7, 0.3, 1.0], comps("hsl(120, 50%, 50%)"))
//        XCTAssertEqual([1.0, 1.0, 1.0, 0.5], comps("hsla(0,0%,100%,   0.5)"))
//        XCTAssertEqual([0.5, 0.7, 0.4, 0.8], comps("hsla(100, 33%, 55%, 0.8)"))
    }

    /// Compare our CSS font parsing output with WebKit's (via an HTML NSAttributedString, which is only available on macOS)
    func testFontParsing() throws {
        let font = CSS.parseFontStyle

        #if !os(macOS)
        throw XCTSkip("font parsing not yet available on non macOS")
        #endif

        func check(font fontShorthand: String, parses expectedFont: String, size: Double = 12.0) {
            guard let parsedFont = font(fontShorthand) else {
                return XCTFail("could not parse font: \(fontShorthand)")
            }
            XCTAssertEqual(CTFontCopyDisplayName(parsedFont) as String, expectedFont, "bad font family for font: \(fontShorthand)")
            XCTAssertEqual(CTFontGetSize(parsedFont), .init(size), "bad font size for font: \(fontShorthand)")
        }

        check(font: "12px Serif", parses: "Times Roman")
        check(font: "12px Sans-Serif", parses: "Helvetica")
        check(font: "12px Cursive", parses: "Apple Chancery")
        check(font: "12px Fantasy", parses: "Papyrus")
        check(font: "12px Monospace", parses: "Courier")

        check(font: "12px X, MONOSPACE", parses: "Courier")
        check(font: "12px MONOSPACE, X", parses: "Courier")
        check(font: "19px X, FANTASY", parses: "Papyrus", size: 19)
        check(font: "19px FANTASY, X", parses: "Papyrus", size: 19)

        check(font: "12px/14px sans-serif", parses: "Helvetica")
        check(font: "1.2em \"Fira Sans\", sans-serif", parses: "Helvetica", size: 14.4)
        check(font: "italic small-caps bold 16px/2 cursive", parses: "Apple Chancery", size: 16.0)
        check(font: "small-caps bold 24px/1 sans-serif", parses: "Helvetica Bold", size: 24.0)
        check(font: "caption", parses: "System Font Regular", size: 13)
        check(font: "80% sans-serif", parses: "Helvetica", size: 9.6)
        check(font: "bold italic large serif", parses: "Times Bold Italic", size: 14)

        // https://github.com/web-platform-tests/wpt/blob/master/css/css-fonts/variations/font-shorthand.html
        check(font: "700.5 24px Arial", parses: "Arial Bold", size: 24)
        check(font: "oblique 45deg 24px Arial", parses: "Arial Italic", size: 24)
        check(font: "oblique 24px Arial", parses: "Arial Italic", size: 24)
        check(font: "oblique 50 24px Arial", parses: "Arial Italic", size: 24)
        check(font: "oblique 500 24px Arial", parses: "Arial Italic", size: 24)
        check(font: "oblique 45deg 500 24px Arial", parses: "Arial Italic", size: 24)

        // these might be dependent on local system settings, so we may need to add in some fuzzy matching…
        check(font: "caption", parses: "System Font Regular", size: 13.0)
        check(font: "icon", parses: "System Font Regular", size: 13.0)
        check(font: "menu", parses: "System Font Regular", size: 13.0)
        check(font: "message-box", parses: "System Font Regular", size: 13.0)
        check(font: "small-caption", parses: "System Font Regular", size: 11.0)
        check(font: "status-bar", parses: "System Font Regular", size: 10.0)
    }
}

#if canImport(PDFKit)
import PDFKit

final class CoreGraphicsCanvasTests: XCTestCase {

    let canvasSize = CGSize(width: 500, height: 500)

    @available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *)
    func testPDFCanvas() throws {
        let api = try PDFCanvas(size: canvasSize)
        try canvasTest(api: api)
        let doc = try XCTUnwrap(api.createPDFDocument())
        doc.write(to: URL(fileURLWithPath: "demo.pdf", relativeTo: URL(fileURLWithPath: NSTemporaryDirectory())))
    }

    func testBitmapCanvas() throws {
        let api = try LayerCanvas(size: canvasSize)
        try canvasTest(api: api)
        let doc = try XCTUnwrap(api.createPNGData())
        try doc.write(to: URL(fileURLWithPath: "demo.png", relativeTo: URL(fileURLWithPath: NSTemporaryDirectory())))
    }

    /// Tests the given `CoreGraphicsCanvas` implementation
    func canvasTest(api: CoreGraphicsCanvas) throws {
        let ctx = JXContext()
        let canvas = try Canvas(env: ctx, delegate: api)

        do { // check font property
            XCTAssertEqual("10px sans-serif", api.font)
            try ctx.eval(this: canvas, script: "this.font = '18px serif';")
            XCTAssertEqual("18px serif", api.font)
        }

        let measureText = { canvas["measureText"].call(withArguments: [JXValue(string: $0, in: ctx)])["width"].numberValue }

        func invoke(emptyArgs function: String) -> () -> () {
            let f = canvas[function]
            XCTAssertTrue(f.isFunction, "not a function: \(function)")
            return { f.call(withArguments: []) }
        }

        func invoke(numericArgs function: String) -> (Double...) -> () {
            let f = canvas[function]
            XCTAssertTrue(f.isFunction, "not a function: \(function)")
            return { f.call(withArguments: $0.map({ JXValue(double: $0, in: ctx) })) }
        }

        let str = { JXValue(string: $0, in: ctx) }
        let num = { JXValue(double: $0, in: ctx) }

        let stroke = invoke(emptyArgs: "stroke")
        let save = invoke(emptyArgs: "save")
        let restore = invoke(emptyArgs: "restore")
        let clip = invoke(emptyArgs: "clip")

        let moveTo = invoke(numericArgs: "moveTo")
        let lineTo = invoke(numericArgs: "lineTo")
        let fillRect = invoke(numericArgs: "fillRect")
        let clearRect = invoke(numericArgs: "clearRect")
        let strokeRect = invoke(numericArgs: "strokeRect")
        let quadraticCurveTo = invoke(numericArgs: "quadraticCurveTo")
        let bezierCurveTo = invoke(numericArgs: "bezierCurveTo")
        let arcTo = invoke(numericArgs: "arcTo")
        let rotate = invoke(numericArgs: "rotate")

        let fillText = { canvas["fillText"].call(withArguments: [str($0), num($1), num($2), num($3)]) }

        let rnd = { Double.random(in: $0 as ClosedRange<Double>) }


        moveTo(100, 1000)
        lineTo(10, 10)

        clearRect(5, 5, 20, 20)

        let randomColor = { (alpha: Double) in str("rgba(\(rnd(0...255)), \(rnd(0...255)), \(rnd(0...255)), \(alpha)") }

        for _ in 0...10 {
            save()
            defer { restore() }
            canvas["fillStyle"] = randomColor(0.5)
            fillRect(rnd(10...200), rnd(10...200), rnd(100...400), rnd(100...400))

            canvas["lineWidth"] = num(rnd(1...10) / 5)
            canvas["setLineDash"].call(withArguments: [JXValue(newArrayIn: ctx, values: [num(rnd(1...10)), num(rnd(3...10))])])

            canvas["strokeStyle"] = randomColor(0.9)
            strokeRect(rnd(10...200), rnd(10...200), rnd(100...400), rnd(100...400))
        }

        canvas["fillStyle"] = str("red")
        canvas["font"] = str("33px Zapfino")

        save()

        XCTAssertEqual(.zero, api.ctx.textPosition)

        _ = fillText("", 100, 100, 300)
        #if os(macOS)
        let y = 400 // NeXTStep!!
        #else
        let y = 100 // sane
        #endif

        XCTAssertEqual(CGPoint(x: 100, y: y), api.ctx.textPosition, "draw blank string should position text")

        _ = fillText("PLUGH", 100, 100, 300)
        XCTAssertNotEqual(CGPoint(x: 100, y: y), api.ctx.textPosition, "test position should have changed")

        restore()

        stroke()
        clip()
        rotate()
        quadraticCurveTo()
        bezierCurveTo()
        arcTo()

        do {
            XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)

            // TODO: implement measureText() (and CSS font parsing) to test text measurement
            // for now, just use `AbstractCanvasAPI`'s simplistic calculation; once we have native font support, we can check the widths of Zapfino and other funky fonts
            #if os(macOS)
            canvas["font"] = str("18px serif")
            XCTAssertEqual(37, measureText("ABC") ?? 0, accuracy: 1)
            canvas["font"] = str("99px monospace")
            XCTAssertEqual(178, measureText("ABC") ?? 0, accuracy: 1)
            canvas["font"] = str("33px Zapfino")
            XCTAssertEqual(126, measureText("ABC") ?? 0, accuracy: 1)
            #else
//            canvas["font"] = str("10px serif")
//            XCTAssertEqual(8, measureText("X"))
//            XCTAssertEqual(3 * 10 * 0.8, measureText("abc"))
//            XCTAssertEqual(4 * 10 * 0.8, measureText("ABCD"))
//            XCTAssertEqual(5 * 10 * 0.8, measureText("ab DE"))
            #endif
        }
    }
}


#endif
