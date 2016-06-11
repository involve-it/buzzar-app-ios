//
//  Message.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class Message: NSObject, DictionaryInitializable, NSCoding {
    var id: String?
    
    override init() {
        super.init()
    }
    
    convenience init(id: String, fields: NSDictionary?){
        self.init(fields: fields)
        self.id = id
    }
    
    required init(fields: NSDictionary?){
        super.init()
        self.update(fields)
    }
    
    func update(fields: NSDictionary?){
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
    private struct PropertyKeys {
        
    }
    
    func toDictionary() -> Dictionary<String, AnyObject>{
        return [:]
    }
}