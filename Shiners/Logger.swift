//
//  Logger.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/8/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class Logger {
    private static var log = [String]()
    
    class func log(message: String){
        Logger.log.append(message)
    }
    
    class func getLog() -> [String] {
        return [String](Logger.log)
    }
}