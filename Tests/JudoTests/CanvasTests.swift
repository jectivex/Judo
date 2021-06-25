//
//  File.swift
//  
//
//  Created by Marc Prud'hommeaux on 6/6/21.
//

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

        XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)

        XCTAssertEqual(3 * 18 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)

        try ctx.eval(this: canvas, script: "this.font = '13px serif';")

        XCTAssertEqual(5 * 13 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('12345').width").numberValue)
    }
}

#if canImport(PDFKit)
import PDFKit

final class CoreGraphicsCanvasTests: XCTestCase {

    func testPDFCanvas() throws {
        let api = try PDFCanvas(size: CGSize(width: 500, height: 500))
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

        moveTo(0, 0)
        lineTo(10, 10)

        canvas["fillStyle"] = str("blue")
        fillRect(rnd(10...200), rnd(10...200), rnd(100...400), rnd(100...400))

        canvas["lineWidth"] = num(10)
        canvas["setLineDash"].call(withArguments: [JXValue(newArrayIn: ctx, values: [num(5), num(3)])])
        canvas["strokeStyle"] = str("rebeccapurple")

        strokeRect(rnd(10...200), rnd(10...200), rnd(100...400), rnd(100...400))

        canvas["fillStyle"] = str("red")
        canvas["font"] = str("33px Zapfino")
        _ = fillText("Hello Sailor", 100, 100, 300)


        do {
            XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)
            try ctx.eval(this: canvas, script: "this.font = '13px serif';")

            // TODO: implement measureText() (and CSS font parsing) to test text measurement
            // for now, just use `AbstractCanvasAPI`'s simplistic calculation; once we have native font support, we can check the widths of Zapfino and other funky fonts
            //XCTAssertEqual(3 * 13 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)
            //
            //XCTAssertEqual(3 * 13 * 0.8, measureText("abc"))
            //XCTAssertEqual(4 * 13 * 0.8, measureText("abcd"))
            //XCTAssertEqual(5 * 13 * 0.8, measureText("ab DE"))

            canvas["font"] = str("18px serif")
            XCTAssertEqual(37, measureText("ABC") ?? 0, accuracy: 1)
            canvas["font"] = str("99px monospace")
            XCTAssertEqual(178, measureText("ABC") ?? 0, accuracy: 1)
            canvas["font"] = str("33px Zapfino")
            XCTAssertEqual(126, measureText("ABC") ?? 0, accuracy: 1)
        }

        let doc = api.createPDF()
    }
}


#endif
