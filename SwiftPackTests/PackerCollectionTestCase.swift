//
//  PackerCollectionTestCase.swift
//  SwiftPack
//
//  Created by Charlz on 16/07/15.
//  Copyright © 2015. All rights reserved.
//

import XCTest

class PackerCollectionTestCase : XCTestCase {
//    func test_Array() {
//        NSDictionary *obj =
//        @{
//            "z": 0,
//            "p": 1,
//            "n": -1,
//            "u8": UINT8_MAX,
//            "u16": UINT16_MAX,
//            "u32": UINT32_MAX,
//            "u64": UINT64_MAX,
//            "s8": INT8_MAX,
//            "s16": INT16_MAX,
//            "s32": INT32_MAX,
//            "s64": INT64_MAX,
//            "n8": INT8_MIN,
//            "n16": INT16_MIN,
//            "n32": INT32_MIN,
//            "n64": INT64_MIN,
//            "arrayFloatDouble": @[1.1f, 2.1)],
//            "dataEmpty": [NSData data],
//            "dataShort": [self dataFromHexString:"ff"],
//            "data": [self dataFromHexString:"1c94d7de0000000344b409a81eafc66993cbe5fd885b5f6975a3f1f03c7338452116f7200a46412437007b65304528a314756bc701cec7b493cab44b3971b18c1137c1b1ba63d6a61119a5a2298b447d0cba89071320fc2c0f66b8f8056cd043d1ac6c0e983903355310e794ddd4a532729b3c2d65d71ebff32219f2f1759b3952d686149780c8e20f6bc912e5ba44701cdb165fcf5ab266c4295bf84796f9ac01c4e2ddf91ac7932d7ed71ee6187aa5fc3177b1abefdc29d8dec5098465b31f17511f65d38285f213724fcc98fe9cc6842c28d5"],
//            "null": [NSNull null],
//            "str": "🍆😗😂😰",
//        };
//        NSLog("Obj: %", obj);
//        
//        XCTAssertEqual([0xff], packInt(-1))
//    }
    
    func test_Dictionary() {
        let obj : Dictionary<String, Any> = [
            "z": 0,
            "p": 1,
            "n": -1,
            "u8": UInt(UInt8.max),
            "u16": UInt(UInt16.max),
            "u32": UInt(UInt32.max),
            "u64": UInt(UInt64.max),
            "s8": Int(Int8.max),
            "s16": Int(Int16.max),
            "s32": Int(Int32.max),
            "s64": Int(Int64.max),
            "n8": Int(Int8.min),
            "n16": Int(Int16.min),
            "n32": Int(Int32.min),
            "n64": Int(Int64.min),
            "arrayFloatDouble": Array<Any>(arrayLiteral: 1.1, 2.1),
////            "dataEmpty": NSData.init(),
//            "dataShort": dataFromHexString("ff"),
//            "data": dataFromHexString("1c94d7de0000000344b409a81eafc66993cbe5fd885b5f6975a3f1f03c7338452116f7200a46412437007b65304528a314756bc701cec7b493cab44b3971b18c1137c1b1ba63d6a61119a5a2298b447d0cba89071320fc2c0f66b8f8056cd043d1ac6c0e983903355310e794ddd4a532729b3c2d65d71ebff32219f2f1759b3952d686149780c8e20f6bc912e5ba44701cdb165fcf5ab266c4295bf84796f9ac01c4e2ddf91ac7932d7ed71ee6187aa5fc3177b1abefdc29d8dec5098465b31f17511f65d38285f213724fcc98fe9cc6842c28d5"),
////            "null": NSNull(),
            "str": "🍆😗😂😰",
        ]
        let packed = Packer.pack(obj)
        let unpacked = Unpacker.unPackByteArray(packed) as! Dictionary<String, Any>
        XCTAssertTrue(dictionaryCompare(obj, dict2:unpacked))
    }
    
    private func dictionaryCompare(dict1: Dictionary<String, Any>, dict2: Dictionary<String, Any>) -> Bool {
        if dict1.count != dict2.count {
            return false
        }
        
        for (key, lhsub) in dict1 {
            if let rhsub = dict2[key] {
                if String(lhsub) != String(rhsub) {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    
    private func dataFromHexString(hex:String) -> NSData {
        let slice = Unpacker.hexStringToByteArray(hex)
        return NSData(bytes:slice, length:slice.count)
    }
}
