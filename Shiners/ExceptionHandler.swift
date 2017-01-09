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
    static let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(ExceptionHandler.EX_LOG_FILENAME)
    class func saveException(_ ex: NSException){
        let message = ex.reason
        //let stack = ex.callStackReturnAddresses
        let symbols = ex.callStackSymbols
        
        var file = (message ?? "(null reason)") + "\n\n"
        symbols.forEach { (line) in
            file += "\(line)\n"
        }
        
        ExceptionHandler.cleanUp()
        do {
            try file.write(toFile: ExceptionHandler.path.relativePath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch{
            print ("Error saving error log")
        }
    }
    
    class func cleanUp() {
        do {
            if FileManager.default.fileExists(atPath: ExceptionHandler.path.relativePath) {
                try FileManager.default.removeItem(at: path)
            }
        }
        catch{
            print ("Error cleaning error log")
        }
    }
    
    class func hasLastCrash() -> Bool{
        return FileManager.default.fileExists(atPath: ExceptionHandler.path.relativePath)
    }
    
    @objc class func submitReport(){
        if ConnectionHandler.Instance.isNetworkConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            do {
                let log = try String(contentsOfFile: path.relativePath, encoding: String.Encoding.utf8)
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
            NotificationCenter.default.addObserver(self, selector: #selector(submitReport), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
}
