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
        let text = Describer.describeBytes(simple);
        println(text.description)
        
    }
}