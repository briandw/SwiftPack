//
//  UnpackerIntegerTestCase.swift
//  SwiftPack
//
//  Created by Witold Skibniewski on 20/12/14.
//  Copyright (c) 2014 Rantlab. All rights reserved.
//

import XCTest

class UnpackerIntegerTestCase: XCTestCase {

    func test_Unpack_5BitNegativeIntegerMax() {
        XCTAssertEqual(-1, unpackInt([0xff]))
    }

    func test_Unpack_5BitNegativeIntegerMin() {
        XCTAssertEqual(-32, unpackInt([0xe0]))
    }

    func test_Unpack_7BitPositiveIntegerMin() {
        XCTAssertEqual(0, unpackInt([0x00]))
    }

    func test_Unpack_7BitPositiveIntegerMax() {
        XCTAssertEqual(Int(Int8.max), unpackInt([0x7f]))
    }

    func test_Unpack_Int8Min() {
        XCTAssertEqual(Int(Int8.min), unpackInt([0xd0, 0x80]))
        XCTAssertEqual(Int(Int8.min), unpackInt([0xd1, 0xff, 0x80]))
        XCTAssertEqual(Int(Int8.min) + 1, unpackInt([0xd0, 0x81]))
    }

    func test_Unpack_Int16Min() {
        XCTAssertEqual(Int(Int16.min), unpackInt([0xd1, 0x80, 0x00]))
    }

    func test_Unpack_Int16Max() {
        XCTAssertEqual(Int(Int16.max), unpackInt([0xd1, 0x7f, 0xff]))
    }

    func test_Unpack_Int32Min() {
        XCTAssertEqual(Int(Int32.min), unpackInt([0xd2, 0x80, 0x00, 0x00, 0x00]))
    }

    func test_Unpack_Int32Max() {
        XCTAssertEqual(Int(Int32.max), unpackInt([0xd2, 0x7f, 0xff, 0xff, 0xff]))
    }

    func test_Unpack_Int64Min() {
        XCTAssertEqual(Int(Int64.min), unpackInt([0xd3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }

    func test_Unpack_Int64Max() {
        XCTAssertEqual(Int(Int64.max), unpackInt([0xd3, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]))
    }

    // MARK: -

    private func unpackInt(bytes: [UInt8]) -> Int {
        return Unpacker.unPackByteArray(bytes) as Int
    }
}
