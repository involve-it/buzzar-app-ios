//
//  ResponseErrorHelper.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class ResponseHelper{
    static let errors = [900: "Internal error occurred"]
    
    public class func getErrorId(result: AnyObject?) -> Int?{
        if let fields = result as? NSDictionary, error = fields.valueForKey("error") as? NSDictionary, errorId = error.valueForKey("errorId") as? Int{
            return errorId
        }
        return nil
    }
    
    public class func getResult(result: AnyObject?) -> AnyObject?{
        if let fields = result as? NSDictionary, res = fields.valueForKey("result"){
            return res
        }
        return nil
    }
    
    public class func isSuccessful(result: AnyObject?) -> Bool{
        if let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
            return success
        }
        return false
    }
    
    public class func getErrorMessage(errorId: Int?) -> String{
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
    
    public class func getDefaultErrorMessage() -> String{
        return errors[900]!
    }
    
    public class func callHandler<T: DictionaryInitializable>(result: AnyObject?, handler: MeteorMethodCallback?) -> T?{
        if let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
            if (success){
                if let result = fields.valueForKey("result") as? NSDictionary {
                    let concreteResult = T(fields: result)
                    handler?(success: true, errorId: nil, errorMessage: nil, result: concreteResult)
                    return concreteResult
                }
            } else {
                let errorId = getErrorId(result)
                let message = self.getErrorMessage(errorId)
                handler?(success: false, errorId: errorId, errorMessage: message, result: nil)
            }
        } else {
            handler?(success: false, errorId: nil, errorMessage: getDefaultErrorMessage(), result: nil)
        }
        
        return nil
    }
    
    public class func callHandlerArray<T: DictionaryInitializable>(result: AnyObject?, handler: MeteorMethodCallback?) -> [T]?{
        if let fields = result as? NSDictionary, success = fields.valueForKey("success") as? Bool{
            if (success){
                if let result = fields.valueForKey("result") as? NSArray {
                    var concreteResults = [T]()
                    for value in result {
                        if let objFields = value as? NSDictionary {
                            let concreteResult = T(fields: objFields)
                            concreteResults.append(concreteResult)
                        }
                    }
                    
                    handler?(success: true, errorId: nil, errorMessage: nil, result: concreteResults)
                    return concreteResults
                }
            } else {
                let errorId = getErrorId(result)
                let message = self.getErrorMessage(errorId)
                handler?(success: false, errorId: errorId, errorMessage: message, result: nil)
            }
        } else {
            handler?(success: false, errorId: nil, errorMessage: getDefaultErrorMessage(), result: nil)
        }
        
        return nil
    }
}

public typealias MeteorMethodCallback = (success: Bool, errorId: Int?, errorMessage: String?, result: Any?) -> Void