//
//  ResponseErrorHelper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class ResponseErrorHelper{
    public class func getError(result: AnyObject?) -> Int?{
        if let fields = result as? NSDictionary, error = fields.valueForKey("error") as? NSDictionary, errorId = error.valueForKey("errorId") as? Int{
            return errorId
        }
        return nil
    }
}