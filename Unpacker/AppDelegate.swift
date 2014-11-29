//
//  AppDelegate.swift
//  Unpacker
//
//  Created by brian on 11/29/14.
//  Copyright (c) 2014 Rantlab. All rights reserved.
//

import Cocoa
import SwiftPack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{

    @IBOutlet weak var window: NSWindow!
    @IBOutlet var decodedView: NSTextView!


    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification)
    {
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
        
        var output = ""
        
        if let items = pb.readObjectsForClasses([clazz], options:nil)?
        {
            for hexString in items
            {
                let bytes:Array<UInt8> = Unpacker.hexStringToByteArray(hexString as String)
                if (bytes.count > 0)
                {
                    var result:AnyObject = Unpacker.unPackByteArray(bytes)
                    var description:String = result.description
                    if (description.utf16Count < 1)
                    {
                        description = "unparsable"
                    }
                        
                    output += description
                }
                else
                {
                    output += "empty"
                }
                
                output += "\n"
            }
        }
        
        decodedView.string = output
    }
}

