//
//  ResponseErrorHelper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class ResponseHelper{
    static let errors = [900: "Internal error occurred"]
    
    open class func getErrorId(_ result: AnyObject?) -> Int?{
        if let fields = result as? NSDictionary, let error = fields.value(forKey: "error") as? NSDictionary, let errorId = error.value(forKey: "errorId") as? Int{
            return errorId
        }
        return nil
    }
    
    open class func getResult(_ result: AnyObject?) -> AnyObject?{
        if let fields = result as? NSDictionary, let res = fields.value(forKey: "result"){
            return res as AnyObject?
        }
        return nil
    }
    
    open class func isSuccessful(_ result: AnyObject?) -> Bool{
        if let fields = result as? NSDictionary, let success = fields.value(forKey: "success") as? Bool{
            return success
        }
        return false
    }
    
    open class func getErrorMessage(_ errorId: Int?) -> String{
        if let id = errorId {
            if let message = errors[id]{
                return message;
            } else {
                return errors[900]!
            }
        } else {
            return errors[900]!
        }
    }
    
    open class func getDefaultErrorMessage() -> String{
        return errors[900]!
    }
    
    open class func callHandler<T: DictionaryInitializable>(_ result: AnyObject?, handler: MeteorMethodCallback?) -> T?{
        if let fields = result as? NSDictionary, let success = fields.value(forKey: "success") as? Bool{
            if success, let result = fields.value(forKey: "result") as? NSDictionary {
                let concreteResult = T(fields: result)
                handler?(true, nil, nil, concreteResult)
                return concreteResult
            } else {
                let errorId = getErrorId(result)
                let message = self.getErrorMessage(errorId)
                handler?(false, errorId, message, nil)
            }
        } else {
            handler?(false, nil, getDefaultErrorMessage(), nil)
        }
        
        return nil
    }
    
    open class func callHandlerArray<T: DictionaryInitializable>(_ result: AnyObject?, handler: MeteorMethodCallback?) -> [T]?{
        if let fields = result as? NSDictionary, let success = fields.value(forKey: "success") as? Bool{
            if success {
                var concreteResults = [T]()
                if let result = fields.value(forKey: "result") as? NSArray{
                    for value in result {
                        if let objFields = value as? NSDictionary {
                            let concreteResult = T(fields: objFields)
                            concreteResults.append(concreteResult)
                        }
                    }
                }
                
                handler?(true, nil, nil, concreteResults)
                return concreteResults
            } else {
                let errorId = getErrorId(result)
                let message = self.getErrorMessage(errorId)
                handler?(false, errorId, message, nil)
            }
        } else {
            handler?(false, nil, getDefaultErrorMessage(), nil)
        }
        
        return nil
    }
}

public typealias MeteorMethodCallback = (_ success: Bool, _ errorId: Int?, _ errorMessage: String?, _ result: Any?) -> Void
