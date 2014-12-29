//
//  PackerUnsignedIntegerTestCase.swift
//  SwiftPack
//
//  Created by Witold Skibniewski on 22/12/14.
//  Copyright (c) 2014 Rantlab. All rights reserved.
//

import XCTest

class PackerUnsignedIntegerTestCase: XCTestCase {

    func test_Pack_7BitPositiveIntegerMin_PacksPositiveFixnum() {
        XCTAssertEqual([0x00], packUInt(0))
    }

    func test_Pack_7BitPositiveIntegerMax_PacksPositiveFixnum() {
        XCTAssertEqual([0x7f], packUInt(0b0111_1111))
    }

    func test_Pack_UInt8Min() {
        XCTAssertEqual([0x00], packUInt(UInt(UInt8.min)))
    }

    func test_Pack_UInt8Max() {
        XCTAssertEqual([0xcc, 0xff], packUInt(UInt(UInt8.max)))
    }

    func test_Pack_UInt16Max() {
        XCTAssertEqual([0xcd, 0xff, 0xff], packUInt(UInt(UInt16.max)))
    }

    func test_Pack_UInt32Max() {
        let value = [UInt8](count: sizeof(UInt32), repeatedValue: 0xff)
        XCTAssertEqual([0xce] + value, packUInt(UInt(UInt32.max)))
    }

    func test_Pack_UInt64Max() {
        let value = [UInt8](count: sizeof(UInt64), repeatedValue: 0xff)
        XCTAssertEqual([0xcf] + value, packUInt(UInt(UInt64.max)))
    }

    // MARK: -

    private func packUInt(uint: UInt) -> [UInt8] {
        return Packer.pack(uint)
    }
}
