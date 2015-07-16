//
//  Packer.swift
//  SwiftPack
//
//  Created by brian on 7/1/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Foundation
import SwiftPack


public class Packer
{
    //@todo research the most effiecant array type for this
    class func pack(thing:Any) -> [UInt8]
    {
        return pack(thing, bytes: Array<UInt8>())
    }
    
    class func pack(thing:Any, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        
        switch thing
        {
        case let string as String:
            localBytes = packString(string, bytes: bytes)
            
        case let dictionary as Dictionary<String, Any>:
            localBytes = packDictionary(dictionary, bytes: bytes)
            
        case let array as Array<Any>:
            localBytes = packArray(array, bytes: bytes)
            
        case let uint as UInt:
            localBytes += packUInt(UInt64(uint))
            
        case let int as Int:
            localBytes += packInt(int)
            
        case let float as Float:
            localBytes += packFloat(float)
            
        case let double as Double:
            localBytes += packDouble(double)
            
        case let binary as [UInt8]:
            localBytes = packBin(binary, bytes: bytes)
            
        case let bool as Bool:
            let value: UInt8 = bool ? 0xc3 : 0xc2
            localBytes = [value]
            
        default:
            print("Error: Can't pack type \(thing)")
        }
        
        return localBytes
    }
    
    class func packUInt(var uint:UInt64) -> [UInt8]
    {
        var size:Int!
        var formatByte: UInt8!
        switch uint {
        case 0...127:
            return [UInt8(uint)]
            
        case UInt64(UInt8.min)...UInt64(UInt8.max):
            size = sizeof(UInt8.self)
            formatByte = 0xcc
            
        case UInt64(UInt16.min)...UInt64(UInt16.max):
            size = sizeof(UInt16.self)
            formatByte = 0xcd
            
        case UInt64(UInt32.min)...UInt64(UInt32.max):
            size = sizeof(Int32.self)
            formatByte = 0xce
            
        default:
            size = sizeof(UInt64.self)
            formatByte = 0xcf
        }
        
        var data = [UInt8](count: size, repeatedValue: 0)
        memcpy(&data, &uint, size)
        return [formatByte] + Array(data.reverse())
    }
    
    class func packInt(var int:Int) -> [UInt8]
    {
        var size:Int!
        var formatByte: UInt8!
        switch int {
        case -32..<0, 0...127:
            return unsafeBitCast([int], [UInt8].self)
            
        case Int(Int8.min)...Int(Int8.max):
            size = sizeof(Int8.self)
            formatByte = 0xd0
            
        case Int(Int16.min)...Int(Int16.max):
            size = sizeof(Int16.self)
            formatByte = 0xd1
            
        case Int(Int32.min)...Int(Int32.max):
            size = sizeof(Int32.self)
            formatByte = 0xd2
            
        default:
            size = sizeof(Int64.self)
            formatByte = 0xd3
        }
        
        var data = [Int8](count: size, repeatedValue: 0)
        memcpy(&data, &int, size)
        return [formatByte] + unsafeBitCast(Array(data.reverse()), [UInt8].self)
    }
    
    class func packFloat(float:Float) -> [UInt8]
    {
        let localBytes:Array<UInt8> = copyBytes(float, length: sizeof(Float))
        return [0xCA] + Array(localBytes.reverse())
    }
    
    class func packDouble(double:Double) -> [UInt8]
    {
        let localBytes:Array<UInt8> = copyBytes(double, length: sizeof(Double))
        return [0xCB] + Array(localBytes.reverse())
    }
    
    class func packBin(bin:[UInt8], bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        let length = Int32(bin.count)
        if (length < 0x10)
        {
            localBytes.append(UInt8(0xC4))
        }
        else if (length < 0x100)
        {
            localBytes.append(UInt8(0xC5))
        }
        else
        {
            localBytes.append(UInt8(0xC6))
        }
        
        localBytes += lengthBytes(length)
        localBytes += bin
        
        return localBytes
    }
    
    class func packString(string:String, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes:Array<UInt8> = bytes
        
        var stringBuff = [UInt8]()
        stringBuff += string.utf8
        
        let length = stringBuff.count
        if (length < 0x20)
        {
            localBytes.append(UInt8(0xA0 | UInt8(length)))
        }
        else
        {
            if (length < 0x10)
            {
                localBytes.append(UInt8(0xD9))
            }
            else if (length < 0x100)
            {
                localBytes.append(UInt8(0xDA))
            }
            else
            {
                localBytes.append(UInt8(0xDB))
            }
            
            localBytes += lengthBytes(Int32(length))
        }
        
        localBytes += stringBuff
        
        return localBytes
    }
    
    class func packArray(array:Array<Any>, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        let items = Int32(array.count)
        if (items < 0x10)
        {
            localBytes.append(UInt8(0x90 | UInt8(items)))
        }
        else
        {
            if (items < 0x100)
            {
                localBytes.append(UInt8(0xDC))
            }
            else
            {
                localBytes.append(UInt8(0xDD))
            }
            
            localBytes += lengthBytes(items)
        }
        
        for item in array
        {
            localBytes = pack(item, bytes: localBytes)
        }
        
        return localBytes
    }
    
    class func packDictionary(dict:Dictionary<String, Any>, bytes:[UInt8]) -> [UInt8]
    {
        var localBytes = bytes
        let elements = Int32(dict.count)
        if (elements < 0x10)
        {
            localBytes.append(UInt8(0x80 | UInt8(elements)))
        }
        else
        {
            if (elements < 0x100)
            {
                localBytes.append(UInt8(0xDE))
            }
            else
            {
                localBytes.append(UInt8(0xDF))
            }
            localBytes += lengthBytes(elements)
        }
        
        for (key, value) in dict
        {
            localBytes = pack(key, bytes: localBytes)
            localBytes = pack(value, bytes: localBytes)
        }
        
        return localBytes
    }
    
    class func lengthBytes(lengthIn:Int32) -> Array<UInt8>
    {
        var length:CLong = CLong(lengthIn)
        var lengthBytes:Array<UInt8> = Array<UInt8>()
        
        switch (length)
        {
        case 0..<0x10:
            lengthBytes.append(UInt8(length))
            
        case 0x10..<0x100:
            lengthBytes = Array<UInt8>(count:2, repeatedValue:0)
            memcpy(&lengthBytes, &length, 2)
            lengthBytes = Array(lengthBytes.reverse())
            
        case 0x100..<0x10000:
            lengthBytes = Array<UInt8>(count:4, repeatedValue:0)
            memcpy(&lengthBytes, &length, 4)
            lengthBytes = Array(lengthBytes.reverse())
            
        default:
            error("Unknown length")
        }
        
        return lengthBytes
    }
    
    class func copyBytes<T>(value:T, length:Int) -> [UInt8]
    {
        var localValue = value
        var intBytes:Array<UInt8> = Array<UInt8>(count:length, repeatedValue:0)
        memcpy(&intBytes, &localValue, Int(length))
        
        return intBytes
    }
}
