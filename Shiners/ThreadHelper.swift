//
//  Helper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class ThreadHelper{
    public class func runOnMainThread (callback: () -> Void){
        dispatch_async(dispatch_get_main_queue(), {
            callback()
        });
    }
    
    public class func runOnBackgroundThread(callback: () -> Void){
        let background_queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        dispatch_async(background_queue) { 
            callback()
        }
    }
}