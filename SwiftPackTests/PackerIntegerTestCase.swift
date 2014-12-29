//
//  IntegerTestCase.swift
//  SwiftPack
//
//  Created by Witold Skibniewski on 20/12/14.
//  Copyright (c) 2014 Rantlab. All rights reserved.
//

import XCTest

class PackerIntegerTestCase: XCTestCase {

    func test_Pack_5BitNegativeIntegerMax_PacksNegativeFixnum() {
        XCTAssertEqual([0xff], packInt(-1))
    }

    func test_Pack_5BitNegativeIntegerMin_PacksNegativeFixnum() {
        XCTAssertEqual([0xe0], packInt(-32))
    }

    func test_Pack_7BitPositiveIntegerMin_PacksPositiveFixnum() {
        XCTAssertEqual([0x00], packInt(0))
    }

    func test_Pack_7BitPositiveIntegerMax_PacksPositiveFixnum() {
        XCTAssertEqual([0x7f], packInt(Int(Int8.max)))
    }

    func test_Pack_Int8Min() {
        XCTAssertEqual([0xd0, 0x81], packInt(Int(Int8.min) + 1))
        XCTAssertEqual([0xd0, 0x80], packInt(Int(Int8.min)))
    }

    func test_Pack_Int16Min() {
        XCTAssertEqual([0xd1, 0x80, 0x00], packInt(Int(Int16.min)))
    }

    func test_Pack_Int16Max() {
        XCTAssertEqual([0xd1, 0x7f, 0xff], packInt(Int(Int16.max)))
    }

    func test_Pack_Int32Min() {
        XCTAssertEqual([0xd2, 0x80, 0x00, 0x00, 0x00], packInt(Int(Int32.min)))
    }

    func test_Pack_Int32Max() {
        XCTAssertEqual([0xd2, 0x7f, 0xff, 0xff, 0xff], packInt(Int(Int32.max)))
    }

    func test_Pack_Int64Min() {
        XCTAssertEqual([0xd3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], packInt(Int(Int64.min)))
    }

    func test_Pack_Int64Max() {
        XCTAssertEqual([0xd3, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], packInt(Int(Int64.max)))
    }

    // MARK: -

    private func packInt<T: IntegerType>(int: T) -> [UInt8] {
        return Packer.pack(int)
    }
}
