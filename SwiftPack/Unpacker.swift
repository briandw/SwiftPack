//
//  Unpacker.swift
//  SwiftPack
//
//  Created by brian on 6/29/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Foundation

func swiftByteArray(data:NSData)->UInt8[]
{
    var bytes = UInt8[](count:data.length, repeatedValue: 0)
    CFDataGetBytes(data, CFRangeMake(0, data.length), &bytes)
    return bytes
}

func stringFromSlice(bytes:Slice<UInt8>)->String
{
    return NSString(bytes: Array(bytes) as UInt8[], length: bytes.count, encoding: NSUTF8StringEncoding)
}

func dataFromSlice(bytes:Slice<UInt8>)->NSData
{
    return NSData(bytes: Array(bytes) as UInt8[], length: bytes.count)
}

func unPackByteArray(bytes:Array<UInt8>)->Array<AnyObject>
{
    var sliceBytes = bytes[0..bytes.count]
    var bytesRead:UInt = 0
    var returnArray:Array<AnyObject> = []
    while Int(bytesRead) < bytes.count
    {
        let results = parseBytes(sliceBytes)
        bytesRead += results.bytesRead
        returnArray.append(results.value)
        sliceBytes = bytes[Int(bytesRead)..bytes.count]
    }
    
    return returnArray
}

func unPackData(data:NSData)->Array<AnyObject>
{
    let bytes = swiftByteArray(data)
    return unPackByteArray(bytes)
}

func parseBytes(bytesIn:Slice<UInt8>)->(value:AnyObject, bytesRead:UInt)
{
    let byte:UInt8 = bytesIn[0]
    var bytes = bytesIn;
    bytes.removeAtIndex(0)
    
    switch(Int(byte))
        {
    case 0x00...0x7f:
        return (Int(byte), 1)
    case 0x80...0x8f:
        let elements = UInt(byte & 0xF)
        let mapValues = parseMapWithElements(bytes, elements)
        return (value:mapValues.value, bytesRead:mapValues.bytesRead+1)
    case 0x90...0x9f:
        let elements = UInt(byte & 0xF)
        let arrayValues = parseArrayWithElements(bytes, elements)
        return (value:arrayValues.value, bytesRead:arrayValues.bytesRead+1)
    case 0xa0...0xbf:
        let length = UInt(byte & 0x1F)
        let str = dataFromSlice(bytes[0..Int(length)])
        return (value:str, bytesRead:length+1)
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
        return (Int(bytes[0]), 2)
    case 0xc5:
        let bin = parseBin(bytes, 2)
        return (bin, 3)
    case 0xc6:
        let bin = parseBin(bytes, 4)
        return (bin, 5)
    case 0xc7...0xc9:
        error("Unhandeled type")
    case 0xca:
        let float = parseFloat(bytes)
        return (float, 5)
    case 0xcb:
        let double = parseDouble(bytes)
        return (double, 9)
    case 0xcc:
        return (parseUInt(bytes, 1), 2)
    case 0xcd:
        return (parseUInt(bytes, 2), 3)
    case 0xce:
        return (parseUInt(bytes, 4), 5)
    case 0xcf:
        return (parseUInt(bytes, 8), 9)
    case 0xd0:
        return (parseInt(bytes, 1), 2)
    case 0xd1:
        return (parseInt(bytes, 2), 3)
    case 0xd2:
        return (parseInt(bytes, 4), 5)
    case 0xd3:
        return (parseInt(bytes, 8), 9)
    case 0xd4...0xd8:
        error("Unhandeled type")
    case 0xd9:
        let results = parseStr(bytes, 1)
        return (results.value, results.bytesRead+1)
    case 0xda:
        let results = parseStr(bytes, 2)
        return (results.value, results.bytesRead+1)
    case 0xdb:
        let results = parseStr(bytes, 4)
        return (results.value, results.bytesRead+1)
    case 0xdc:
        let results = parseArray(bytes, 2)
        return(results.value, results.bytesRead+1)
    case 0xdd:
        let results = parseArray(bytes, 4)
        return(results.value, results.bytesRead+1)
    case 0xde:
        let results = parseMap(bytes, 2)
        return(results.value, results.bytesRead+1)
    case 0xdf:
        let results = parseMap(bytes, 4)
        return(results.value, results.bytesRead+1)
    case 0xe0...0xff:
        let negInt:Int = Int(byte&0x1F) * -1
        return (negInt, 1)
        
    default:
        error("Unknown type")
    }
    
    return ("", 0)
}

func parseInt(bytes:Slice<UInt8>, length:UInt)->Int
{
    var myInt:Int = 0
    var intBytes = bytes[0..Int(length)].reverse()
    memcpy(&myInt, bytes, length)
    return myInt
}

func parseUInt(bytes:Slice<UInt8>, length:UInt)->UInt
{
    var uint:UInt = 0
    var intBytes = bytes[0..Int(length)].reverse()
    memcpy(&uint, intBytes, length)
    return uint
}

func parseFloat(bytes:Slice<UInt8>)->Float
{
    //reverse bytes first?
    var f:Float = 0.0
    var floatBytes = bytes[0..4].reverse()
    memcpy(&f, floatBytes, 4)
    return f
}

func parseDouble(bytes:Slice<UInt8>)->Double
{
    //reverse bytes first?
    var d:Double = 0.0
    var doubleBytes = bytes[0..8].reverse()
    memcpy(&d, doubleBytes, 8)
    return d
}

func parseBin(bytes:Slice<UInt8>, length:UInt) ->Int
{
    var bin:Int = 0
    memcpy(&bin, bytes, length)
    return bin
}

func parseMap(bytes:Slice<UInt8>, headerSize:UInt)->(value:Dictionary<String, AnyObject>, bytesRead:UInt)
{
    var elements:UInt = 0
    var headerBytes = bytes[0..Int(headerSize)].reverse()
    memcpy(&elements, headerBytes, headerSize)
    
    var results = parseMapWithElements(bytes[Int(headerSize)..bytes.count], elements)
    
    return (results.value, results.bytesRead+headerSize)
}

func parseMapWithElements(bytesIn:Slice<UInt8>, elements:UInt)->(value:Dictionary<String, AnyObject>, bytesRead:UInt)
{
    var bytes = bytesIn
    var dict = Dictionary<String, AnyObject>(minimumCapacity: Int(elements))
    var bytesRead:UInt = 0
    for i in 0..elements
    {
        let keyResults = parseBytes(bytes)
        bytesRead += keyResults.bytesRead;
        
        let key = NSString(data: keyResults.value as NSData, encoding: NSUTF8StringEncoding)
        bytes = bytes[Int(keyResults.bytesRead)..bytes.count]
        
        let valueResults = parseBytes(bytes)
        bytesRead += valueResults.bytesRead;
        let value : AnyObject = valueResults.value
        
        bytes = bytes[Int(valueResults.bytesRead)..bytes.count]
        dict[key] = value
    }
    
    return (dict, bytesRead)
}

func parseArray(bytesIn:Slice<UInt8>, headerSize:UInt)->(value:AnyObject, bytesRead:UInt)
{
    var elements:UInt = 0
    var headerBytes = bytesIn[0..Int(headerSize)].reverse()
    memcpy(&elements, headerBytes, headerSize)
    let results = parseArrayWithElements(bytesIn[Int(headerSize)..bytesIn.count], elements)
    
    return (results.value, results.bytesRead+headerSize)
}

func parseArrayWithElements(bytesIn:Slice<UInt8>, elements:UInt)->(value:AnyObject, bytesRead:UInt)
{
    var bytesRead:UInt = 0
    var bytes = bytesIn
    var array = AnyObject[]()
    for i in 0..elements
    {
        let results = parseBytes(bytes)
        array.append(results.value)
        bytes = bytes[Int(results.bytesRead)..bytes.count]
        bytesRead += results.bytesRead
    }
    
    return (array, bytesRead)
}

func parseStr(bytes:Slice<UInt8>, headerSize:UInt)->(value:NSData, bytesRead:UInt)
{
    var length:UInt = 0
    var headerBytes = bytes[0..Int(headerSize)].reverse()
    memcpy(&length, headerBytes, headerSize)
    
    if (headerSize+length < UInt(bytes.count))
    {
        return (dataFromSlice(bytes[Int(headerSize)..Int(length+headerSize)]), length+headerSize)
    }
    
    return (NSData(), 1)
}

func error(errorMessage:String)
{
    println("error" + errorMessage)
}


///util

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

func hexFromData(data:NSData) ->String
{
    var string = ""
    let bytes = swiftByteArray(data)
    
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

func byteToString(byte:UInt8) -> String
{
    var string = ""
    var localByte = byte
    for j in 0..2
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

func hexStringToByteArray(stringIn:String) -> Array<UInt8>
{
    var hexString = ""
    for character in stringIn
    {
        if (character != " ")
        {
            hexString += character
        }
    }
    hexString = hexString.uppercaseString
    var bytes = UInt8[]()
    
    for var i:Int = 0; i < countElements(hexString); i += 2
    {
        var sub = hexString[i..i+2]
        var byte:UInt8 = charPairToByte(sub)
        bytes.append(byte)
    }
    
    return bytes
}

func charPairToByte(strIn:String) -> UInt8
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
                println("bad"+c)
        }
        byte = byte | number
    }
    
    return byte
}
