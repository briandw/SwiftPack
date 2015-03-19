//
//  UnpackerUnsignedIntegerTestCase.swift
//  SwiftPack
//
//  Created by Witold Skibniewski on 22/12/14.
//  Copyright (c) 2014 Rantlab. All rights reserved.
//

import XCTest

class UnpackerUnsignedIntegerTestCase: XCTestCase {

    func test_Unpack_0PackedAsUInt8() {
        XCTAssertEqual(UInt(0), unpackUInt([0xcc, 0x00]))
    }

    func test_Unpack_UInt8Max() {
        XCTAssertEqual(UInt(UInt8.max), unpackUInt([0xcc, 0xff]))
    }

    func test_Unpack_UInt16Max() {
        XCTAssertEqual(UInt(UInt16.max), unpackUInt([0xcd, 0xff, 0xff]))
    }

    func test_Unpack_UInt32Max() {
        let binaryValue: [UInt8] = [UInt8](count: sizeof(UInt32), repeatedValue: 0xff)
        XCTAssertEqual(UInt(UInt32.max), unpackUInt([0xce] + binaryValue))
    }

    func test_Unpack_UInt64Max() {
        let binaryValue: [UInt8] = [UInt8](count: sizeof(UInt64), repeatedValue: 0xff)
        XCTAssertEqual(UInt(UInt64.max), unpackUInt([0xcf] + binaryValue))
    }

    // MARK: -

    private func unpackUInt(bytes: [UInt8]) -> UInt {
        return Unpacker.unPackByteArray(bytes) as! UInt
    }
}
