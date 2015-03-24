//
//  Describer.swift
//  SwiftPack
//
//  Created by Brian Williams on 3/10/15.
//  Copyright (c) 2015 Rantlab. All rights reserved.
//

import Foundation
import SwiftPack

public class Describer
{
    public class func describeBytes(bytesIn:[UInt8]) -> (description:String, bytesRead:UInt)
    {
        return describeMsgPackBytes(ArraySlice(bytesIn), indent:"");
    }
    
    public class func parseMap(bytesIn:ArraySlice<UInt8>, headerSize:UInt, indent:String)->(description:String, bytesRead:UInt)
    {
        var elements:UInt = 0
        var headerBytes = Array<UInt8>(bytesIn[0..<Int(headerSize)].reverse())
        memcpy(&elements, headerBytes, Int(headerSize))
        return parseMapWithElements(bytesIn[Int(headerSize)..<bytesIn.count], elements:elements, indent: indent)
    }
    
    public class func parseMapWithElements(bytesIn:ArraySlice<UInt8>, elements:UInt, indent:String)->(description:String, bytesRead:UInt)
    {
        var bytes = bytesIn
        var description = String()
        var bytesRead:UInt = 0
        for i in 0..<elements
        {
            let nextIndent = "\t\(indent)"
            let keyResults = describeMsgPackBytes(bytes, indent:nextIndent)
            bytesRead += keyResults.bytesRead
            
            let key:String = keyResults.description
            bytes = bytes[Int(keyResults.bytesRead)..<bytes.count]
            
            let valueResults = describeMsgPackBytes(bytes, indent:indent)
            bytesRead += valueResults.bytesRead;
            let value : AnyObject = valueResults.description
            
            bytes = bytes[Int(valueResults.bytesRead)..<bytes.count]
            description += "\n\(nextIndent)\(key) - \(value)"
        }
        
        return (description, bytesRead)
    }

    public class func parseArray(bytesIn:ArraySlice<UInt8>, headerSize:UInt, indent:String)->(description:String, bytesRead:UInt)
    {
        var elements:UInt = 0
        var headerBytes = Array<UInt8>(bytesIn[0..<Int(headerSize)].reverse())
        memcpy(&elements, headerBytes, Int(headerSize))
        let results = parseArrayWithElements(bytesIn[Int(headerSize)..<bytesIn.count], elements: elements, indent:indent)
        
        return (results.description, results.bytesRead+headerSize)
    }
    
    public class func parseArrayWithElements(bytesIn:ArraySlice<UInt8>, elements:UInt, indent:String)->(description:String, bytesRead:UInt)
    {
        var description = ""
        var bytesRead:UInt = 0
        var bytes = bytesIn
        for i in 0..<elements
        {
            let results = describeMsgPackBytes(bytes, indent:indent)
            description += "\n\(indent)\(results.description)"
            bytes = bytes[Int(results.bytesRead)..<bytes.count]
            bytesRead += results.bytesRead
        }
        
        return (description, bytesRead)
    }
    
    public class func describeMsgPackBytes(bytesIn:ArraySlice<UInt8>, indent:String) -> (description:String, bytesRead:UInt)
    {
        let formatByte:UInt8 = bytesIn[0]
        let bytes = dropFirst(bytesIn)
        
        var bytesRead:UInt = 1;
        var description = ""
        
        switch formatByte
        {
        case 0x00...0x7f:
            description = "FixInt \(formatByte)"
            
        case 0x80...0x8f:
            let elements = UInt(formatByte & 0xF)
            let mapValues = parseMapWithElements(bytes, elements:elements, indent:indent)
            description = "FixMap\(elements) \(mapValues.description)"
            bytesRead += mapValues.bytesRead
            
        case 0x90...0x9f:
            let elements = UInt(formatByte & 0xF)
            let parsed = parseArrayWithElements(bytes, elements: elements, indent:indent)
            description = "FixArray\(elements) \(parsed.description)"
            bytesRead += parsed.bytesRead
            
        case 0xa0...0xbf:
            let length = UInt(formatByte & 0x1F)
            let str:String? = String(bytes: bytes[0..<Int(length)], encoding: NSUTF8StringEncoding)
            if (str != nil)
            {
                let value = str!;
                description = "FixStr:\(length):\(value)"
            }
            else
            {
               description = "FixStr:\(length):#ERROR#"
            }
            
            bytesRead += length
            
        case 0xc0:          //nil type
            description = "nil"
            
        case 0xc1:          //neverused
            description = "#never used#"
            
        case 0xc2:
            description = "false"
            
        case 0xc3:
            description = "true"
            
        case 0xc4:
            let results = Unpacker.parseBin(bytes, headerSize: 1)
            description = "Bin8:\(results.bytesRead):\(results.value)"
            bytesRead += results.bytesRead
            
        case 0xc5:
            let results = Unpacker.parseBin(bytes, headerSize: 2)
            description = "Bin16:\(results.value)"
            bytesRead += results.bytesRead
            
        case 0xc6:
            let results = Unpacker.parseBin(bytes, headerSize: 4)
            description = "Bin64:\(results.value)"
            bytesRead += results.bytesRead
            
        case 0xc7...0xc9:
            description = "Unhandeled ext"
            
        case 0xca:
            let float = Unpacker.parseFloat(bytes)
            description = "float\(float)"
            bytesRead += 5
            
        case 0xcb:
            let double = Unpacker.parseDouble(bytes)
            description = "Double\(double)"
            bytesRead += 9
            
        case 0xcc:
            let value = Unpacker.parseUInt(bytes, length: 1)
            description = "UInt8\(value)"
            bytesRead += 1
            
        case 0xcd:
            let value = Unpacker.parseUInt(bytes, length: 2)
            description = "UInt16\(value))"
            bytesRead += 2
            
        case 0xce:
            let value = Unpacker.parseUInt(bytes, length: 4)
            description = "UInt32\(value)"
            bytesRead += 4
            
        case 0xcf:
            let value = Unpacker.parseUInt(bytes, length: 8)
            description = "UInt64\(value)"
            bytesRead += 8
            
        case 0xd0:
            let value = Unpacker.parseInt(bytes, type: Int8.self)
            description = "Int8\(value)"
            bytesRead += 1
            
        case 0xd1:
            let value = Unpacker.parseInt(bytes, type: Int16.self)
            description = "Int16\(value)"
            bytesRead += 2
            
        case 0xd2:
            let value = Unpacker.parseInt(bytes, type: Int32.self)
            description = "Int32\(value)"
            bytesRead += 4
    
        case 0xd3:
            let value = Unpacker.parseInt(bytes, type: Int64.self)
            description = "Int64\(value)"
            bytesRead += 8
        
        case 0xd4:
            description = "fixext1"
            bytesRead += 1
            
        case 0xd5:
            description = "fixext2"
            bytesRead += 2
            
        case 0xd6:
            description = "fixext4"
            bytesRead += 4
            
        case 0xd7:
            description = "fixext8"
            bytesRead += 8
            
        case 0xd8:
            description = "fixext16"
            bytesRead += 16
            
        case 0xd9:
            let results = Unpacker.parseStr(bytes, headerSize: 1)
            description = "str8:\(results.value)"
            bytesRead += 1
            
        case 0xda:
            let results = Unpacker.parseStr(bytes, headerSize: 2)
            description = "str16:\(results.value)"
            bytesRead += results.bytesRead
            
        case 0xdb:
            let results = Unpacker.parseStr(bytes, headerSize: 4)
            description = "str32:\(results.value)"
            bytesRead += results.bytesRead
            
        case 0xdc:
            let results = parseArray(bytes, headerSize: 2, indent:indent)
            description = "array16:\(results.description)"
            bytesRead += results.bytesRead
            
        case 0xdd:
            let results = parseArray(bytes, headerSize: 4, indent:indent)
            description = "array32:\(results.description)"
            bytesRead += results.bytesRead
            
        case 0xde:
            let results = parseMap(bytes, headerSize: 2, indent:indent)
            description = "map16:\(results.description)"
            bytesRead += results.bytesRead
            
        case 0xdf:
            let results = parseMap(bytes, headerSize: 4, indent:indent)
            description = "map32:\(results.description)"
            bytesRead += results.bytesRead
            
        case 0xe0...0xff:
            let value = Int(unsafeBitCast(formatByte, Int8.self))
            description = "fixnum:\(value)"
            
        default:
            description = "Unknown type"
            
        }
        
        return (description, bytesRead)
    }
}