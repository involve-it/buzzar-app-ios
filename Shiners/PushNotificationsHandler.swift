//
//  PushNotificationsHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 7/17/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class PushNotificationsHandler{
    private static let PUSH_TOKEN = "shiners:push-token"
    
    class func saveToken(deviceToken: NSData) -> String{
        let token = deviceToken.hexString
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: PUSH_TOKEN)
        return token
    }
    
    class func getToken() -> String?{
        return NSUserDefaults.standardUserDefaults().objectForKey(PUSH_TOKEN) as? String
    }
}