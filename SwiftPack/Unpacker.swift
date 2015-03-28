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
    println("error" + errorMessage)
}

extension String {
    subscript (i: Int) -> String
    {
        return String(Array(self)[i])
    }
    
    subscript (r: Range<Int>) -> String
    {
        var start = advance(startIndex, r.startIndex)
        var end = advance(startIndex, r.endIndex)
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
        var bytesRead:UInt = 0
        var returnArray:Array<AnyObject> = []
        var useArray = false
        
        while Int(bytesRead) < bytes.count
        {
            let results = parseBytes(sliceBytes)
            bytesRead += results.bytesRead
            if (!useArray && bytesRead == UInt(bytes.count))
            {
                return results.value
            }
            else
            {
                useArray = true
                returnArray.append(results.value)
                sliceBytes = bytes[Int(bytesRead)..<bytes.count]
            }
        }
        
        return returnArray
    }

    class func unPackData(data:NSData)->Any
    {
        let bytes = swiftByteArray(data)
        return unPackByteArray(bytes)
    }

    class func parseBytes(bytesIn:ArraySlice<UInt8>)->(value:AnyObject, bytesRead:UInt)
    {
        let formatByte:UInt8 = bytesIn[0]
        let bytes = dropFirst(bytesIn)

        switch formatByte
            {
        case 0x00...0x7f:
            return (Int(formatByte), 1)
        case 0x80...0x8f:
            let elements = UInt(formatByte & 0xF)
            let mapValues = parseMapWithElements(bytes, elements: elements)
            return (value:mapValues.value, bytesRead:mapValues.bytesRead+1)
        case 0x90...0x9f:
            let elements = UInt(formatByte & 0xF)
            let arrayValues = parseArrayWithElements(bytes, elements: elements)
            return (value:arrayValues.value, bytesRead:arrayValues.bytesRead+1)
        case 0xa0...0xbf:
            let length = UInt(formatByte & 0x1F)
            let str:String? = String(bytes: bytes[0..<Int(length)], encoding: NSUTF8StringEncoding)
            if (str != nil)
            {
                return (value:str!, bytesRead:length+1)
            }
            else
            {
                return (value:"", bytesRead:length+1);
            }
        case 0xc0:          //nil type
            return ("",1)
        case 0xc1:          //neverused
            error("Never used symbol found")
            return ("", 0)
        case 0xc2:
            return (false, 1)
        case 0xc3:
            return (true, 1)
        case 0xc4:
            let results = parseBin(bytes, headerSize: 1)
            return (results.value, results.bytesRead+1)
        case 0xc5:
            let results = parseBin(bytes, headerSize: 2)
            return (results.value, results.bytesRead+1)
        case 0xc6:
            let results = parseBin(bytes, headerSize: 4)
            return (results.value, results.bytesRead+1)
        case 0xc7...0xc9:
            error("Unhandeled type")
        case 0xca:
            let float = parseFloat(bytes)
            return (float, 5)
        case 0xcb:
            let double = parseDouble(bytes)
            return (double, 9)
        case 0xcc:
            return (parseUInt(bytes, length: 1), 2)
        case 0xcd:
            return (parseUInt(bytes, length: 2), 3)
        case 0xce:
            return (parseUInt(bytes, length: 4), 5)
        case 0xcf:
            return (parseUInt(bytes, length: 8), 9)
        case 0xd0:
            return (Int(parseInt(bytes, type: Int8.self)), 2)
        case 0xd1:
            return (Int(parseInt(bytes, type: Int16.self)), 3)
        case 0xd2:
            return (Int(parseInt(bytes, type: Int32.self)), 5)
        case 0xd3:
            return (Int(parseInt(bytes, type: Int64.self)), 9)
        case 0xd4...0xd8:
            error("Unhandeled type")
        case 0xd9:
            let results = parseStr(bytes, headerSize: 1)
            return (results.value, results.bytesRead+1)
        case 0xda:
            let results = parseStr(bytes, headerSize: 2)
            return (results.value, results.bytesRead+1)
        case 0xdb:
            let results = parseStr(bytes, headerSize: 4)
            return (results.value, results.bytesRead+1)
        case 0xdc:
            let results = parseArray(bytes, headerSize: 2)
            return(results.value, results.bytesRead+1)
        case 0xdd:
            let results = parseArray(bytes, headerSize: 4)
            return(results.value, results.bytesRead+1)
        case 0xde:
            let results = parseMap(bytes, headerSize: 2)
            return(results.value, results.bytesRead+1)
        case 0xdf:
            let results = parseMap(bytes, headerSize: 4)
            return(results.value, results.bytesRead+1)
        case 0xe0...0xff:
            let fixnum = Int(unsafeBitCast(formatByte, Int8.self))
            return (fixnum, 1)
            
        default:
            error("Unknown type")
        }
        
        return ("", 0)
    }

    public class func parseInt<T: IntegerType>(data: ArraySlice<UInt8>, type: T.Type) -> T {
        var int:T = 0
        var intBytes = unsafeBitCast(data, ArraySlice<Int8>.self)
        let length = UInt(sizeof(type))
        memcpy(&int, [Int8](intBytes.reverse()), Int(length))
        return int
    }

   public class func parseUInt(bytes:ArraySlice<UInt8>, length:UInt)->UInt
    {
        var uint:UInt = 0
        var intBytes = bytes[0..<Int(length)].reverse()
        memcpy(&uint, Array<UInt8>(intBytes), Int(length))
        return uint
    }

    public class func parseFloat(bytes:ArraySlice<UInt8>)->Float
    {
        //reverse bytes first?
        var f:Float = 0.0
        var floatBytes = Array<UInt8>(bytes[0..<4].reverse())
        memcpy(&f, floatBytes, 4)
        return f
    }

    public class func parseDouble(bytes:ArraySlice<UInt8>)->Double
    {
        //reverse bytes first?
        var d:Double = 0.0
        var doubleBytes = Array<UInt8>(bytes[0..<8].reverse())
        memcpy(&d, doubleBytes, 8)
        return d
    }

    public class func parseBin(bytes:ArraySlice<UInt8>, headerSize:UInt) -> (value:AnyObject, bytesRead:UInt)
    {
        var length:UInt = 0
        var headerBytes = Array<UInt8>(bytes[0..<Int(headerSize)].reverse())
        memcpy(&length, headerBytes, Int(headerSize))

        let dataBytes = Array<UInt8>(bytes[Int(headerSize)...Int(length)]);
        let size = length+headerSize
        return (NSData(bytes: dataBytes, length: dataBytes.count), size)
    }

    public class func parseMap(bytes:ArraySlice<UInt8>, headerSize:UInt)->(value:Dictionary<String, AnyObject>, bytesRead:UInt)
    {
        var elements:UInt = 0
        var headerBytes = Array<UInt8>(bytes[0..<Int(headerSize)].reverse())
        memcpy(&elements, headerBytes, Int(headerSize))
        
        var results = parseMapWithElements(bytes[Int(headerSize)..<bytes.count], elements: elements)
        
        return (results.value, results.bytesRead+headerSize)
    }

    public class func parseMapWithElements(bytesIn:ArraySlice<UInt8>, elements:UInt)->(value:Dictionary<String, AnyObject>, bytesRead:UInt)
    {
        var bytes = bytesIn
        var dict = Dictionary<String, AnyObject>(minimumCapacity: Int(elements))
        var bytesRead:UInt = 0
        for i in 0..<elements
        {
            let keyResults = parseBytes(bytes)
            bytesRead += keyResults.bytesRead
            
            let key:String = keyResults.value as! String
            bytes = bytes[Int(keyResults.bytesRead)..<bytes.count]
            
            let valueResults = parseBytes(bytes)
            bytesRead += valueResults.bytesRead;
            let value : AnyObject = valueResults.value
            
            bytes = bytes[Int(valueResults.bytesRead)..<bytes.count]
            dict[key] = value
        }
        
        return (dict, bytesRead)
    }

    public class func parseArray(bytesIn:ArraySlice<UInt8>, headerSize:UInt)->(value:AnyObject, bytesRead:UInt)
    {
        var elements:UInt = 0
        var headerBytes = Array<UInt8>(bytesIn[0..<Int(headerSize)].reverse())
        memcpy(&elements, headerBytes, Int(headerSize))
        let results = parseArrayWithElements(bytesIn[Int(headerSize)...bytesIn.count], elements: elements)
        
        return (results.value, results.bytesRead+headerSize)
    }

    public class func parseArrayWithElements(bytesIn:ArraySlice<UInt8>, elements:UInt)->(value:AnyObject, bytesRead:UInt)
    {
        var bytesRead:UInt = 0
        var bytes = bytesIn
        var array = [AnyObject]()
        for i in 0..<elements
        {
            let results = parseBytes(bytes)
            array.append(results.value)
            bytes = bytes[Int(results.bytesRead)..<bytes.count]
            bytesRead += results.bytesRead
        }
        
        return (array, bytesRead)
    }

    public class func parseStr(bytes:ArraySlice<UInt8>, headerSize:UInt)->(value:String, bytesRead:UInt, length:UInt)
    {
        var length:UInt = 0
        var headerBytes = Array<UInt8>(bytes[0..<Int(headerSize)].reverse())
        memcpy(&length, headerBytes, Int(headerSize))
        
        if (headerSize+length <= UInt(bytes.count))
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
        var i = 0
        for byte in bytes
        {
            string += byteToString(byte)
            i++
            if (i%4==0)
            {
                string = string+" "
            }
        }
        
        return string
    }

    public class func byteToString(byte:UInt8) -> String
    {
        var string = ""
        var localByte = byte
        for j in 0..<2
        {
            var letter = ""
            var tmp = localByte & 240
            switch(tmp >> 4)
                {
            case 0:
                letter = "0"
            case 1:
                letter = "1"
            case 2:
                letter = "2"
            case 3:
                letter = "3"
            case 4:
                letter = "4"
            case 5:
                letter = "5"
            case 6:
                letter = "6"
            case 7:
                letter = "7"
            case 8:
                letter = "8"
            case 9:
                letter = "9"
            case 10:
                letter = "A"
            case 11:
                letter = "B"
            case 12:
                letter = "C"
            case 13:
                letter = "D"
            case 14:
                letter = "E"
            case 15:
                letter = "F"
            default:
                letter = ""
            }
            
            string = string+letter
            
            localByte = localByte << 4
        }
        return string
    }

    public class func hexStringToByteArray(stringIn:String) -> Array<UInt8>
    {
        var hexString = ""
        for character in stringIn
        {
            if (character != " ")
            {
                hexString.append(character)
            }
        }
        
        hexString = hexString.uppercaseString
        var bytes = [UInt8]()
        var stringLength = count(hexString)
        if (stringLength % 2 != 0)
        {
            stringLength -= 1;
        }
        
        for var i:Int = 0; i < stringLength; i += 2
        {
            var sub = hexString[i..<i+2]
            var byte:UInt8 = charPairToByte(sub)
            bytes.append(byte)
        }
        
        return bytes
    }

    class func charPairToByte(strIn:String) -> UInt8
    {
        var byte:UInt8 = 0
        for c in strIn
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
                    println("bad char \(c)")
            }
            byte = byte | number
        }
        
        return byte
    }
}
