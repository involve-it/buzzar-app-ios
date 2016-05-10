//
//  RegisterUser.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class RegisterUser{
    public var username: String?
    public var email: String?
    public var password: String?
    
    init(username: String?, email: String?, password: String?){
        self.username = username
        self.email = email
        self.password = password
    }
    
    public func isValid() -> Bool{
        if self.username == nil || self.email == nil || self.password == nil{
            return false
        }
        
        return true
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict["username"] = self.username
        dict["email"] = self.email
        dict["password"] = self.password
        
        return dict
    }
}