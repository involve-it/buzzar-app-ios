//
//  RegisterUser.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class RegisterUser{
    open var username: String?
    open var email: String?
    open var password: String?
    
    init(username: String?, email: String?, password: String?){
        self.username = username
        self.email = email
        self.password = password
    }
    
    open func isValid() -> Bool{
        if self.username == nil || self.email == nil || self.password == nil{
            return false
        }
        
        return true
    }
    
    open func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["username"] = self.username as AnyObject?
        dict["email"] = self.email as AnyObject?
        dict["password"] = self.password as AnyObject?
        
        return dict
    }
}
