//
//  DescriberTest.swift
//  SwiftPack
//
//  Created by Brian Williams on 3/19/15.
//  Copyright (c) 2015 Rantlab. All rights reserved.
//

import Cocoa
import XCTest
import SwiftPack

class DescriberTestCase: XCTestCase {

    func test()
    {
        let simpleHex = "82 A3 66 6F 6F A3 62 61 72 A3 62 61 7A 01"
        let simple = Unpacker.hexStringToByteArray(simpleHex)
        
        let packed = Packer.packBin(simple, bytes:Array<UInt8>())
        print(Unpacker.hexFromBytes(packed))
        
        let text1 = Describer.describeBytes(simple);
        print(text1.descriptions)
        
        let msgPackCaseHex = "C2 C3 C0 00 CC 00 CD 00 00 CE 00 00 00 00 CF 00 00 00 00 00 00 00 00 D0 00 D1 00 00 D2 00 00 00 00 D3 00 00 00 00 00 00 00 00 FF D0 FF D1 FF FF D2 FF FF FF FF D3 FF FF FF FF FF FF FF FF 7F CC 7F CD 00 FF CE 00 00 FF FF CF 00 00 00 00 FF FF FF FF E0 D0 E0 D1 FF 80 D2 FF FF 80 00 D3 FF FF FF FF 80 00 00 00 CB 00 00 00 00 00 00 00 00 CB 80 00 00 00 00 00 00 00 CB 3F F0 00 00 00 00 00 00 CB BF F0 00 00 00 00 00 00 A1 61 DA 00 01 61 DB 00 00 00 01 61 A0 DA 00 00 DB 00 00 00 00 91 00 DC 00 01 00 DD 00 00 00 01 00 90 DC 00 00 DD 00 00 00 00 80 DE 00 00 DF 00 00 00 00 81 A1 61 61 DE 00 01 A1 61 61 DF 00 00 00 01 A1 61 61 91 90 91 91 A1 61"
        
        let msgPackCase = Unpacker.hexStringToByteArray(msgPackCaseHex)
        let text2 = Describer.describeBytes(msgPackCase);
        print(text2.descriptions)
    }
}