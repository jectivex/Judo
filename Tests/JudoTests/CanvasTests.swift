//
//  File.swift
//  
//
//  Created by Marc Prud'hommeaux on 6/6/21.
//

import Foundation
import Judo
import XCTest

#if canImport(CoreGraphics)
import CoreGraphics

final class CoreGraphicsCanvasTests: XCTestCase {
    func testCoreGraphicsCanvas() throws {
        let size = CGSize(width: 500, height: 500)
        var imageRect: CGRect = NSMakeRect(0, 0, size.width, size.height)

        let outputData = NSMutableData()
        guard let dataConsumer = CGDataConsumer(data: outputData as CFMutableData) else {
            return XCTFail("Unable to create data consumer")
        }

        let attrDictionary = NSMutableDictionary()
//        var properties: [String: Any] = [:]
//        for prop in properties {
//            prop.add(to: attrDictionary)
//        }

        guard let cgctx = CGContext(consumer: dataConsumer, mediaBox: &imageRect, attrDictionary) else {
            return XCTFail("Unable to create PDF context")
        }

//        NSGraphicsContext.saveGraphicsState()
//        defer { NSGraphicsContext.restoreGraphicsState() }
//        NSGraphicsContext.current = NSGraphicsContext(cgContext: cgctx, flipped: false) // use the PDF context for drawing

//        cgctx.beginPDFPage(nil)
//        self.draw(in: imageRect)
//        cgctx.endPage()
//        cgctx.closePDF()
//
//        return outputData


        let api = CoreGraphicsCanvas(context: cgctx)

        let ctx = JXContext()
        let canvas = try Canvas(env: ctx, delegate: api)

        do { // check font property
            XCTAssertEqual("10px sans-serif", api.font)
            try ctx.eval(this: canvas, script: "this.font = '18px serif';")
            XCTAssertEqual("18px serif", api.font)
        }

        XCTAssertEqual("function", try ctx.eval(this: canvas, script: "typeof this.measureText").stringValue)

//        XCTAssertEqual(3 * 18, try ctx.eval(this: canvas, script: "this.measureText('abc').width").numberValue)

        try ctx.eval(this: canvas, script: "this.font = '13px serif';")

//        XCTAssertEqual(5 * 13, try ctx.eval(this: canvas, script: "this.measureText('12345').width").numberValue)
    }
}

#endif

