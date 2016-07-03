//
//  MessageToSend.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class MessageToSend {
    var message: String?
    var type = "message"
    var destinationUserId: String?
    
    func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        dict["message"] = message
        dict["type"] = type
        dict["destinationUserId"] = destinationUserId
        return dict
    }
}