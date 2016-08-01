//
//  SecurityHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 7/29/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class SecurityHandler{
    private static let DEVICE_ID_KEY = "org.buzzar.app:DEVICE_ID_KEY"
    private static var deviceId: String!
    
    class func setDeviceId(){
        if let id = KeychainWrapper.stringForKey(DEVICE_ID_KEY){
            deviceId = id
        } else {
            deviceId = NSUUID().UUIDString
            KeychainWrapper.setString(deviceId, forKey: DEVICE_ID_KEY)
        }
    }
    
    class func getDeviceId() -> String{
        return deviceId
    }
}