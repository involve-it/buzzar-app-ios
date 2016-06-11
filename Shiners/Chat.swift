//
//  Chat.swift
//  Shiners
//
//  Created by Yury Dorofeev on 6/11/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class Chat: NSObject, DictionaryInitializable, NSCoding {
    override init (){
        super.init()
    }
    
    required init (fields: NSDictionary?){
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
    }
    
    private struct PropertyKeys {
        
    }
}