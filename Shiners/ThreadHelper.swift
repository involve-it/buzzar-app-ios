//
//  Helper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class ThreadHelper{
    open class func runOnMainThread (_ callback: @escaping () -> Void){
        DispatchQueue.main.async(execute: {
            callback()
        });
    }
    
    open class func runOnBackgroundThread(_ callback: @escaping () -> Void){
        let background_queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        background_queue.async { 
            callback()
        }
    }
}
