//
//  Packer.swift
//  SwiftPack
//
//  Created by brian on 7/1/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Foundation

func pack(thing:Any) -> [UInt8]
{
    return pack(thing, Array<UInt8>())
}

func pack(thing:Any, bytes:[UInt8]) -> [UInt8]
{
    var localBytes = bytes
    
    if (thing is String)
    {
        localBytes = packString(thing as String, bytes)
    }
    else if (thing is Dictionary<String, Any>)
    {
        localBytes = packDictionary(thing as Dictionary<String, Any>, bytes)
    }
    else if (thing is Array<Any>)
    {
        localBytes = packArray(thing as Array<Any>, bytes)
    }
    else if (thing is Int)
    {
        localBytes = packInt(thing as Int64, bytes)
    }
    else if (thing is UInt)
    {
        localBytes = packUInt(thing as UInt64, bytes)
    }
    else if (thing is Float)
    {
        localBytes = packFloat(thing as Float, bytes)
    }
    else if (thing is Double)
    {
        localBytes = packDouble(thing as Double, bytes)
    }
    else if (thing is [UInt8])
    {
        localBytes = packBin(thing as [UInt8], bytes)
    }
    else
    {
        error("Can't pack type")
    }
    
    return localBytes
}

func packUInt(uint:UInt64, bytes:[UInt8]) -> [UInt8]
{
    switch (uint)
    {
        case 0..<0x80:
            return packFixnum(UInt8(uint), bytes)
        
        case 0x80..<0x10:
            return packUInt8(UInt8(uint), bytes)
            
        case 0x10..<0x100:
            return packUInt16(UInt16(uint), bytes)
            
        case 0x100..<0x10000:
            return packUInt32(UInt32(uint), bytes)
            
        default:
            return packUInt64(UInt64(uint), bytes)
    }
}

func packFixnum(uint:UInt8, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    localBytes += uint
    return localBytes
}

func packUInt8(uint:UInt8, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCC
    localBytes += uint
    return localBytes
}

func packUInt16(uint:UInt16, bytes:[UInt8]) -> [UInt8]
{
    var localInt = uint
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCD
    
    return copyBytes(uint, 2, localBytes)
}

func packUInt32(uint:UInt32, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCE
    
    return copyBytes(uint, 4, localBytes)
}

func packUInt64(uint:UInt64, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCF
    return copyBytes(uint, 8, localBytes)
}

func packInt(int:Int64, bytes:[UInt8]) -> [UInt8]
{
    switch (int)
    {
        case 0..<0x10:
            return packInt8(Int8(int), bytes)
        
        case 0x10..<0x100:
            return packInt16(Int16(int), bytes)
        
        case 0x10..<0x10000:
            return packInt32(Int32(int), bytes)

        default:
            return packInt64(Int64(int), bytes)
    }
}

func packInt8(int:Int8, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xD0
    localBytes += UInt8(int)
    return localBytes
}

func packInt16(int:Int16, bytes:[UInt8]) -> [UInt8]
{
    var localInt = UInt16(int)
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xD1
    
    return copyBytes(int, 2, localBytes)
}

func packInt32(int:Int32, bytes:[UInt8]) -> [UInt8]
{
    var localInt:UInt32 = UInt32(int)
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xD2
    
    return copyBytes(int, 4, localBytes)
}

func packInt64(int:Int64, bytes:[UInt8]) -> [UInt8]
{
    var localInt:UInt64 = UInt64(int)
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xD3
    
    return copyBytes(int, 8, localBytes)
}

func packFloat(float:Float, bytes:[UInt8]) -> [UInt8]
{
    var localFloat = float
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCA
    
    return copyBytes(localFloat, 4, localBytes)
}

func packDouble(float:Double, bytes:[UInt8]) -> [UInt8]
{
    var localFloat = float
    var localBytes:Array<UInt8> = bytes
    localBytes += 0xCB
    
    return copyBytes(localFloat, 8, localBytes)
}

func packBin(bin:[UInt8], bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    let length = Int32(countElements(localBytes))
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

func packString(string:String, bytes:[UInt8]) -> [UInt8]
{
    var localBytes:Array<UInt8> = bytes
    
    let cString:[CChar]? = string.cStringUsingEncoding(NSUTF8StringEncoding)
    if let cStr = cString
    {
        var length = Int32(countElements(cStr))-1
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
            
            localBytes += lengthBytes(length)
        }
        
        var strBytes = [UInt8](count: Int(length), repeatedValue: 0)
        
        memcpy(&strBytes, cStr, UInt(length))
        localBytes += strBytes
    }
    else
    {
        error("bad string")
    }
    
    return localBytes
}

func packArray(array:Array<Any>, bytes:[UInt8]) -> [UInt8]
{
    var localBytes = bytes
    var items = Int32(countElements(array))
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
       localBytes = pack(item, localBytes)
    }
    
    return localBytes
}

func packDictionary(dict:Dictionary<String, Any>, bytes:[UInt8]) -> [UInt8]
{
    var localBytes = bytes
    var elements = Int32(countElements(dict))
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
        localBytes = pack(key, localBytes)
        localBytes = pack(value, localBytes)
    }
    
    return localBytes
}

func lengthBytes(lengthIn:Int32) -> Array<UInt8>
{
    var length:CLong = CLong(lengthIn)
    var lengthBytes:Array<UInt8> = Array<UInt8>()

    switch (length)
    {
        case 0..<0x10:
            lengthBytes += (UInt8(length))
            
        case 0x10..<0x100:
            lengthBytes = Array<UInt8>(count:2, repeatedValue:0)
            memcpy(&lengthBytes, &length, 2)
            lengthBytes = lengthBytes.reverse()
            
        case 0x100..<0x10000:
            lengthBytes = Array<UInt8>(count:4, repeatedValue:0)
            memcpy(&lengthBytes, &length, 4)
            lengthBytes = lengthBytes.reverse()
            
        default:
            error("Unknown length")
    }
    
    return lengthBytes
}

func copyBytes<T>(value:T, length:Int, bytes:[UInt8]) -> [UInt8]
{
    var localValue = value
    var localBytes:Array<UInt8> = bytes
    var intBytes:Array<UInt8> = Array<UInt8>(count:length, repeatedValue:0)
    memcpy(&intBytes, &localValue, UInt(length))
    localBytes += intBytes
    
    return localBytes
}
