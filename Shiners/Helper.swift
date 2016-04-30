//
//  Helper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class Helper{
    public class func runOnMainThread (callback: () -> Void){
        dispatch_async(dispatch_get_main_queue(), {
            callback();
        });
    }
}