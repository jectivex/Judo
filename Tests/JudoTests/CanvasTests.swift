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

        XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)


        try ctx.eval(this: canvas, script: "this.moveTo(1, 2);")
        try ctx.eval(this: canvas, script: "this.lineTo(99, 2);")
        try ctx.eval(this: canvas, script: "this.fillRect();")

        try ctx.eval(this: canvas, script: "this.font = '13px serif';")

        // TODO: implement measureText() (and CSS font parsing) to test text measurement
        // for now, just use `AbstractCanvasAPI`'s naieve calculation; once we have native font support, we can check the widths of Zapfino and other funky fonts
        XCTAssertEqual(3 * 13 * 0.8, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)

        // XCTAssertEqual(3 * 18, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)
        // XCTAssertEqual(5 * 13, try ctx.eval(this: canvas, script: "this.measureText('12345').width").numberValue)

        let doc = api.createPDF()
//        else {
//            return XCTFail("unable to create PDF document from data")
//        }
//
//        guard let attrs = doc.documentAttributes else {
//            return XCTFail("unable to create PDF document attributes from data")
//        }
//
//        // standard attributes for PDF documents
//        XCTAssertNotNil(attrs["ModDate"])
//        XCTAssertNotNil(attrs["CreationDate"])
//        XCTAssertNotNil(attrs["CreationDate"])
    }
}

#endif

