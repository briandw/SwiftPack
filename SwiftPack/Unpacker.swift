//
//  Unpacker.swift
//  SwiftPack
//
//  Created by brian on 6/29/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Foundation
import SwiftPack

///util
func error(errorMessage:String)
{
    print("error" + errorMessage)
}

extension String {
    subscript (i: Int) -> String
        {
            return String(Array(self.characters)[i])
    }
    
    subscript (r: Range<Int>) -> String
        {
            let start = advance(startIndex, r.startIndex)
            let end = advance(startIndex, r.endIndex)
            return substringWithRange(Range(start: start, end: end))
    }
}

public class Unpacker
{
    class func swiftByteArray(data:NSData)->[UInt8]
    {
        var bytes = [UInt8](count:data.length, repeatedValue: 0)
        CFDataGetBytes(data, CFRangeMake(0, data.length), &bytes)
        return bytes
    }
    
    public class func unPackByteArray(bytes:Array<UInt8>)->Any
    {
        var sliceBytes = bytes[0..<bytes.count]
        var bytesRead:Int = 0
        var returnArray:Array<Any> = []
        var useArray = false
        
        while Int(bytesRead) < bytes.count
        {
            let results = parseBytes(sliceBytes)
            bytesRead += results.bytesRead
            if (!useArray && bytesRead == bytes.count)
            {
                return results.value
            }
            else
            {
                useArray = true
                returnArray.append(results.value)
                assert(bytesRead < bytes.count, "Too many bytes read")
                sliceBytes = bytes[bytesRead..<bytes.count]
            }
        }
        
        return returnArray
    }
    
    class func unPackData(data:NSData)->Any
    {
        let bytes = swiftByteArray(data)
        return unPackByteArray(bytes)
    }
    
    class func parseBytes(bytesIn:ArraySlice<UInt8>)->(value:Any, bytesRead:Int)
    {
        let formatByte:UInt = UInt(bytesIn[0]) //Cast this up to a UInt so the switch doesn't crash
        let bytes = dropFirst(bytesIn)
        
        var bytesRead:Int = 1
        var value:Any = 0
        
        switch formatByte
        {
        case 0x00...0x7f:
            value = Int(formatByte)
            
        case 0x80...0x8f:
            let elements = Int(formatByte & 0xF)
            let result = parseMapWithElements(bytes, elements: elements)
            value = result.value
            bytesRead += result.bytesRead
            
        case 0x90...0x9f:
            let elements = Int(formatByte & 0xF)
            let result = parseArrayWithElements(bytes, elements: elements)
            value = result.value
            bytesRead += result.bytesRead
            
        case 0xa0...0xbf:
            let length = Int(formatByte & 0x1F)
            let str:String? = String(bytes: bytes[0..<length], encoding: NSUTF8StringEncoding)
            if (str != nil)
            {
                value = str!;
            }
            else
            {
                value = "#ERROR#"
            }
            
            bytesRead += length
            
        case 0xc0:          //nil type
            //value = nil
            error("nil type not handeled")
            
        case 0xc1:          //neverused
            value = "#Never Used#"
            
        case 0xc2:
            value = false
            
        case 0xc3:
            value = true
            
        case 0xc4:
            let results = parseBin(bytes, headerSize: 1)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xc5:
            let results = parseBin(bytes, headerSize: 2)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xc6:
            let results = parseBin(bytes, headerSize: 4)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xc7...0xc9:
            value = "Unhandeled ext"
            
        case 0xca:
            value = parseFloat(bytes)
            bytesRead += 4
            
        case 0xcb:
            value = parseDouble(bytes)
            bytesRead += 8
            
        case 0xcc:
            value = parseUInt(bytes, length: 1)
            bytesRead += 1
            
        case 0xcd:
            value = parseUInt(bytes, length: 2)
            bytesRead += 2
            
        case 0xce:
            value = parseUInt(bytes, length: 4)
            bytesRead += 4
            
        case 0xcf:
            value = parseUInt(bytes, length: 8)
            bytesRead += 8
            
        case 0xd0:
            value = parseInt(bytes, length:1)
            bytesRead += 1
            
        case 0xd1:
            value = parseInt(bytes, length:2)
            bytesRead += 2
            
        case 0xd2:
            value = parseInt(bytes, length:4)
            bytesRead += 4
            
        case 0xd3:
            value = parseInt(bytes, length:8)
            bytesRead += 8
            
        case 0xd4:
            let results = parseBin(bytes, headerSize: 1)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xd5:
            let results = parseBin(bytes, headerSize: 2)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xd6:
            let results = parseBin(bytes, headerSize: 4)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xd7:
            let results = parseBin(bytes, headerSize: 8)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xd8:
            let results = parseBin(bytes, headerSize: 16)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xd9:
            let results = parseStr(bytes, headerSize: 1)
            value = results.value
            bytesRead += 1
            
        case 0xda:
            let results = parseStr(bytes, headerSize: 2)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xdb:
            let results = parseStr(bytes, headerSize: 4)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xdc:
            let results = parseArray(bytes, headerSize: 2)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xdd:
            let results = parseArray(bytes, headerSize: 4)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xde:
            let results = parseMap(bytes, headerSize: 2)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xdf:
            let results = parseMap(bytes, headerSize: 4)
            value = results.value
            bytesRead += results.bytesRead
            
        case 0xe0...0xff:
            //swift won't do the right thing here so hack it
            let tmp = Int(formatByte);
            value = tmp-256;
            
        default:
            value = "Unknown type"
            
        }
        
        return (value, bytesRead)
    }
    
    public class func parseInt(bytes: ArraySlice<UInt8>, length:Int)->Int
    {
        var result:Int = 0
        let intBytes = Array(bytes[0..<length].reverse())
        switch length {
        case 1:
            var int:Int8 = 0
            memcpy(&int, Array<UInt8>(intBytes), length)
            result = Int(int)
        case 2:
            var int:Int16 = 0
            memcpy(&int, Array<UInt8>(intBytes), length)
            result = Int(int)
        case 4:
            var int:Int32 = 0
            memcpy(&int, Array<UInt8>(intBytes), length)
            result = Int(int)
        default:
            assert(length == 8)
            var int:Int64 = 0
            memcpy(&int, Array<UInt8>(intBytes), length)
            result = Int(int)
        }
        return result
    }
    
    public class func parseUInt(bytes:ArraySlice<UInt8>, length:Int)->UInt
    {
        var uint:UInt = 0
        let intBytes = Array(bytes[0..<length].reverse())
        memcpy(&uint, Array<UInt8>(intBytes), length)
        return uint
    }
    
    public class func parseFloat(bytes:ArraySlice<UInt8>)->Float
    {
        //reverse bytes first?
        var f:Float = 0.0
        let floatBytes = Array<UInt8>(Array(bytes[0..<4].reverse()))
        memcpy(&f, floatBytes, 4)
        return f
    }
    
    public class func parseDouble(bytes:ArraySlice<UInt8>)->Double
    {
        //reverse bytes first?
        var d:Double = 0.0
        let doubleBytes = Array<UInt8>(Array(bytes[0..<8].reverse()))
        memcpy(&d, doubleBytes, 8)
        return d
    }
    
    public class func parseBin(bytes:ArraySlice<UInt8>, headerSize:Int) -> (value:AnyObject, bytesRead:Int)
    {
        var length:Int = 0
        let headerBytes = Array<UInt8>(Array(bytes[0..<headerSize].reverse()))
        memcpy(&length, headerBytes, headerSize)
        
        let slice = bytes[headerSize...length]
        assert(slice.count == length, "Data doesn't match the length");
        let size = length+headerSize
        return (NSData(bytes:Array<UInt8>(slice), length:length), size)
    }
    
    public class func parseMap(bytes:ArraySlice<UInt8>, headerSize:Int)->(value:Dictionary<String, Any>, bytesRead:Int)
    {
        var elements:Int = 0
        let headerBytes = Array<UInt8>(Array(bytes[0..<Int(headerSize)].reverse()))
        memcpy(&elements, headerBytes, Int(headerSize))
        
        let results = parseMapWithElements(bytes[headerSize..<bytes.count], elements: elements)
        
        return (results.value, results.bytesRead+headerSize)
    }
    
    public class func parseMapWithElements(bytesIn:ArraySlice<UInt8>, elements:Int)->(value:Dictionary<String, Any>, bytesRead:Int)
    {
        var bytes = bytesIn
        var dict = Dictionary<String, Any>(minimumCapacity: Int(elements))
        var bytesRead:Int = 0
        for _ in 0..<elements
        {
            let keyResults = parseBytes(bytes)
            bytesRead += keyResults.bytesRead
            
            let key:String = keyResults.value as! String
            bytes = bytes[Int(keyResults.bytesRead)..<bytes.count]
            
            let valueResults = parseBytes(bytes)
            bytesRead += valueResults.bytesRead;
            let value:Any = valueResults.value
            
            bytes = bytes[Int(valueResults.bytesRead)..<bytes.count]
            dict[key] = value
        }
        
        return (dict, bytesRead)
    }
    
    public class func parseArray(bytesIn:ArraySlice<UInt8>, headerSize:Int)->(value:Any, bytesRead:Int)
    {
        var elements:Int = 0
        let headerBytes = Array<UInt8>(Array(bytesIn[0..<Int(headerSize)].reverse()))
        memcpy(&elements, headerBytes, Int(headerSize))
        let results = parseArrayWithElements(bytesIn[Int(headerSize)...bytesIn.count], elements: elements)
        
        return (results.value, results.bytesRead+headerSize)
    }
    
    public class func parseArrayWithElements(bytesIn:ArraySlice<UInt8>, elements:Int)->(value:Any, bytesRead:Int)
    {
        var bytesRead:Int = 0
        var bytes = bytesIn
        var array = [Any]()
        for _ in 0..<elements
        {
            let results = parseBytes(bytes)
            array.append(results.value)
            bytes = bytes[Int(results.bytesRead)..<bytes.count]
            bytesRead += results.bytesRead
        }
        
        return (array, bytesRead)
    }
    
    public class func parseStr(bytes:ArraySlice<UInt8>, headerSize:Int)->(value:String, bytesRead:Int, length:Int)
    {
        var length:Int = 0
        let headerBytes = Array<UInt8>(Array(bytes[0..<Int(headerSize)].reverse()))
        memcpy(&length, headerBytes, Int(headerSize))
        
        if (headerSize+length <= bytes.count)
        {
            let str = String(bytes: bytes[Int(headerSize)..<Int(length+headerSize)], encoding: NSUTF8StringEncoding)
            if let string = str
            {
                return (string, length+headerSize, length)
            }
            else
            {
                return ("", length+headerSize, length)
            }
        }
        
        return ("", 1, 0)
    }
    
    public class func hexFromData(data:NSData) -> String
    {
        return hexFromBytes(swiftByteArray(data))
    }
    
    public class func hexFromBytes(bytes:[UInt8])-> String
    {
        var string = ""
        for byte in bytes
        {
            string += String(byte, radix: 16)
        }
        return string
    }
    
    public class func hexStringToByteArray(stringIn:String) -> Array<UInt8>
    {
        var hexString = ""
        for character in stringIn.characters
        {
            if (character != " ")
            {
                hexString.append(character)
            }
        }
        
        hexString = hexString.uppercaseString
        var bytes = [UInt8]()
        var stringLength = hexString.characters.count
        if (stringLength % 2 != 0)
        {
            stringLength -= 1;
        }
        
        for var i:Int = 0; i < stringLength; i += 2
        {
            let sub = hexString[i..<i+2]
            let byte:UInt8 = charPairToByte(sub)
            bytes.append(byte)
        }
        
        return bytes
    }
    
    class func charPairToByte(strIn:String) -> UInt8
    {
        var byte:UInt8 = 0
        for c in strIn.characters
        {
            var number:UInt8 = 0
            byte = byte << 4
            switch(c)
            {
            case "0":
                number = 0
            case "1":
                number = 1
            case "2":
                number = 2
            case "3":
                number = 3
            case "4":
                number = 4
            case "5":
                number = 5
            case "6":
                number = 6
            case "7":
                number = 7
            case "8":
                number = 8
            case "9":
                number = 9
            case "A":
                number = 10
            case "B":
                number = 11
            case "C":
                number = 12
            case "D":
                number = 13
            case "E":
                number = 14
            case "F":
                number = 15
            default:
                print("bad char \(c)")
            }
            byte = byte | number
        }
        
        return byte
    }
}
