//
//  Photo.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class Photo: NSObject, NSCoding {
    open var id: String?
    open var original: String?
    open var thumbnail: String?
    
    public override init(){
        super.init()
    }
    
    public init(fields: NSDictionary?){
        super.init()
        
        self.original = fields?.value(forKey: PropertyKeys.original) as? String
        self.thumbnail = fields?.value(forKey: PropertyKeys.thumbnail) as? String
        self.id = fields?.value(forKey: PropertyKeys.id) as? String
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKeys.id) as? String
        self.original = aDecoder.decodeObject(forKey: PropertyKeys.original) as? String
        self.thumbnail = aDecoder.decodeObject(forKey: PropertyKeys.thumbnail) as? String
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: PropertyKeys.id)
        aCoder.encode(self.original, forKey: PropertyKeys.original)
        aCoder.encode(self.thumbnail, forKey: PropertyKeys.thumbnail)
    }
    
    open func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        dict[PropertyKeys.id] = self.id as AnyObject?
        dict[PropertyKeys.original] = self.original as AnyObject?
        dict[PropertyKeys.thumbnail] = self.thumbnail as AnyObject?
        
        return dict
    }
    
    fileprivate struct PropertyKeys{
        static let id = "_id"
        //todo: rename to 'original'
        static let original = "data"
        static let thumbnail = "thumbnail"
    }
}
