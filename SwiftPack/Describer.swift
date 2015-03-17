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
            description += "\(key)\n\(value)\n"
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
        
        switch formatByte
        {
        case 0x00...0x7f:
            return ("\(indent)FixInt \(formatByte)", 1)
        case 0x80...0x8f:
            let elements = UInt(formatByte & 0xF)
            let mapValues = parseMapWithElements(bytes, elements:elements, indent:indent)
            return (mapValues.description, bytesRead:mapValues.bytesRead+1)
        case 0x90...0x9f:
            let elements = UInt(formatByte & 0xF)
            let parsed = parseArrayWithElements(bytes, elements: elements, indent:indent)
            return (parsed.description, bytesRead:parsed.bytesRead+1)
        case 0xa0...0xbf:
            let length = UInt(formatByte & 0x1F)
            let str:String? = String(bytes: bytes[0..<Int(length)], encoding: NSUTF8StringEncoding)
            var description:String
            if (str != nil)
            {
                description = "\(indent)FixStr:\(length):\(str)"
            }
            else
            {
               description = "\(indent)FixStr:\(length):#ERROR#"
            }
            
            return (description, bytesRead:length+1)
        case 0xc0:          //nil type
            return ("\(indent)nil",1)
        case 0xc1:          //neverused
            return ("\(indent)#never used#",1)
        case 0xc2:
            return ("\(indent)false",1)
        case 0xc3:
            return ("\(indent)true",1)
        case 0xc4:
            let results = Unpacker.parseBin(bytes, headerSize: 1)
            return ("\(indent)Bin8:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xc5:
            let results = Unpacker.parseBin(bytes, headerSize: 2)
            return ("\(indent)Bin16:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xc6:
            let results = Unpacker.parseBin(bytes, headerSize: 4)
            return ("\(indent)Bin64:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xc7...0xc9:
            return ("\(indent)Unhandeled ext",1)
        case 0xca:
            let float = Unpacker.parseFloat(bytes)
            return ("\(indent)float\(float)", 5)
        case 0xcb:
            let double = Unpacker.parseDouble(bytes)
            return ("Double\(double)",9)
        case 0xcc:
            return ("UInt8\(Unpacker.parseUInt(bytes, length: 1))",2)
        case 0xcd:
            return ("UInt16\(Unpacker.parseUInt(bytes, length: 2))", 3)
        case 0xce:
            return ("UInt32\(Unpacker.parseUInt(bytes, length: 4))", 5)
        case 0xcf:
            return ("UInt64\(Unpacker.parseUInt(bytes, length: 8))", 9)
        case 0xd0:
            return ("Int8\(Unpacker.parseInt(bytes, type: Int8.self))", 2)
        case 0xd1:
            return ("Int16\(Unpacker.parseInt(bytes, type: Int16.self))", 3)
        case 0xd2:
            return ("Int32\(Unpacker.parseInt(bytes, type: Int32.self))", 5)
        case 0xd3:
            return ("Int64\(Unpacker.parseInt(bytes, type: Int64.self))", 9)
        
        case 0xd4:
            return ("fixext1\(indent)",2)
        case 0xd5:
            return ("fixext2\(indent)",3)
        case 0xd6:
            return ("fixext4\(indent)",5)
        case 0xd7:
            return ("fixext8\(indent)",9)
        case 0xd8:
            return ("fixext16\(indent)",17)
            
        case 0xd9:
            let results = Unpacker.parseStr(bytes, headerSize: 1)
            return ("\(indent)str8:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xda:
            let results = Unpacker.parseStr(bytes, headerSize: 2)
            return ("\(indent)str16:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xdb:
            let results = Unpacker.parseStr(bytes, headerSize: 4)
            return ("\(indent)str32:\(results.bytesRead):\(results.value)",results.bytesRead+1)
        case 0xdc:
            let results = parseArray(bytes, headerSize: 2, indent:indent)
            return ("\(indent)array16:\(results.bytesRead):\(results.description)",results.bytesRead+1)
        case 0xdd:
            let results = parseArray(bytes, headerSize: 4, indent:indent)
            return ("\(indent)array32:\(results.bytesRead):\(results.description)",results.bytesRead+1)
        case 0xde:
            let results = parseMapWithElements(bytes, elements: 2, indent:indent)
            return ("\(indent)map16:\(results.bytesRead):\(results.description)",results.bytesRead+1)
        case 0xdf:
            let results = parseMapWithElements(bytes, elements: 4, indent:indent)
            return ("\(indent)array32:\(results.bytesRead):\(results.description)",results.bytesRead+1)
        case 0xe0...0xff:
            let fixnum = Int(unsafeBitCast(formatByte, Int8.self))
            return ("\(indent)fixnum:\(fixnum)",1)
            
        default:
            return ("\(indent)Unknown type",1)
        }
    }
}