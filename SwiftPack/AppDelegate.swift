//
//  AppDelegate.swift
//  SwiftPack
//
//  Created by brian on 8/4/14.
//  Copyright (c) 2014 RantLab. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!
    @IBOutlet var decodedView: NSTextView!


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        test();
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    func classFromType<T:NSObject>(type: T.Type) -> AnyObject!
    {
        return T.valueForKey("self")
    }
    
    @IBAction func readPasteBoard(x:AnyObject)
    {
        let pb = NSPasteboard.generalPasteboard()
        let clazz:AnyObject = classFromType(NSString.self)
        let items = pb.readObjectsForClasses([clazz], options:nil)
        
        for hexString in items
        {
            let bytes:Array<UInt8> = hexStringToByteArray(hexString as String)
            var result:AnyObject = unPackByteArray(bytes)
            decodedView.string = result.description
        }
    }
}

/*
- (IBAction)readPasteBoard:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:@[[NSString class]] options:@{}];
    NSString *textString = @"error";
    if (copiedItems != nil)
    {
        NSString *string = [copiedItems firstObject];
        NSData *bytes = [self hexToBytes:string];
        if (bytes)
        {
            id parsedPack = [RLMessagePack unpackData:bytes];
            if (parsedPack)
            {
                textString = [parsedPack description];
            }
            else
            {
                textString = @"unparsable";
            }
        }
        else
        {
            textString = @"empty";
        }
    }
    
    self.decodedView.string = textString;
}
*/

func test()
{
    let simpleHex = "82 A3 66 6F 6F A3 62 61 72 A3 62 61 7A 01"
    let msgPackCaseHex = "C2 C3 C0 00 CC 00 CD 00 00 CE 00 00 00 00 CF 00 00 00 00 00 00 00 00 D0 00 D1 00 00 D2 00 00 00 00 D3 00 00 00 00 00 00 00 00 FF D0 FF D1 FF FF D2 FF FF FF FF D3 FF FF FF FF FF FF FF FF 7F CC 7F CD 00 FF CE 00 00 FF FF CF 00 00 00 00 FF FF FF FF E0 D0 E0 D1 FF 80 D2 FF FF 80 00 D3 FF FF FF FF 80 00 00 00 CB 00 00 00 00 00 00 00 00 CB 80 00 00 00 00 00 00 00 CB 3F F0 00 00 00 00 00 00 CB BF F0 00 00 00 00 00 00 A1 61 DA 00 01 61 DB 00 00 00 01 61 A0 DA 00 00 DB 00 00 00 00 91 00 DC 00 01 00 DD 00 00 00 01 00 90 DC 00 00 DD 00 00 00 00 80 DE 00 00 DF 00 00 00 00 81 A1 61 61 DE 00 01 A1 61 61 DF 00 00 00 01 A1 61 61 91 90 91 91 A1 61"
    
    let simple = hexStringToByteArray(simpleHex)
    let msgPackCase = hexStringToByteArray(msgPackCaseHex)
    
    println("Simple MsgPack")
    var result:AnyObject = unPackByteArray(simple)
    println(result)
    
    //var bytes = pack(result)
    
    //print(bytes)
    println("MsgPack test case")
    result = unPackByteArray(msgPackCase)
    println(result)
}