//
//  ExceptionHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/10/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class ExceptionHandler{
    static let EX_LOG_FILENAME = "lastexceptionlog"
    static let path = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent(ExceptionHandler.EX_LOG_FILENAME)
    class func saveException(ex: NSException){
        let message = ex.reason
        //let stack = ex.callStackReturnAddresses
        let symbols = ex.callStackSymbols
        
        var file = (message ?? "(null reason)") + "\n\n"
        symbols.forEach { (line) in
            file += "\(line)\n"
        }
        
        ExceptionHandler.cleanUp()
        do {
            try file.writeToFile(ExceptionHandler.path.relativePath!, atomically: false, encoding: NSUTF8StringEncoding)
        }
        catch{
            print ("Error saving error log")
        }
    }
    
    class func cleanUp() {
        do {
            if NSFileManager.defaultManager().fileExistsAtPath(ExceptionHandler.path.relativePath!) {
                try NSFileManager.defaultManager().removeItemAtURL(path)
            }
        }
        catch{
            print ("Error cleaning error log")
        }
    }
    
    class func hasLastCrash() -> Bool{
        return NSFileManager.defaultManager().fileExistsAtPath(ExceptionHandler.path.relativePath!)
    }
    
    @objc class func submitReport(){
        if ConnectionHandler.Instance.status == .Connected {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            do {
                let log = try String(contentsOfFile: path.relativePath!, encoding: NSUTF8StringEncoding)
                ConnectionHandler.Instance.users.errorLog(log, callback: { (success, errorId, errorMessage, result) in
                    if !success {
                        print ("error sending log")
                    }
                })
            }
            catch{
                
            }
            
            ExceptionHandler.cleanUp()
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(submitReport), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        }
    }
}