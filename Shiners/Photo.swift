//
//  Photo.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/21/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class Photo: NSObject, NSCoding {
    public var id: String?
    public var original: String?
    public var thumbnail: String?
    
    public override init(){
        super.init()
    }
    
    public init(fields: NSDictionary?){
        super.init()
        
        self.original = fields?.valueForKey(PropertyKeys.original) as? String
        self.thumbnail = fields?.valueForKey(PropertyKeys.thumbnail) as? String
        self.id = fields?.valueForKey(PropertyKeys.id) as? String
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKeys.id) as? String
        self.original = aDecoder.decodeObjectForKey(PropertyKeys.original) as? String
        self.thumbnail = aDecoder.decodeObjectForKey(PropertyKeys.thumbnail) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.id, forKey: PropertyKeys.id)
        aCoder.encodeObject(self.original, forKey: PropertyKeys.original)
        aCoder.encodeObject(self.thumbnail, forKey: PropertyKeys.thumbnail)
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        dict[PropertyKeys.id] = self.id
        dict[PropertyKeys.original] = self.original
        dict[PropertyKeys.thumbnail] = self.thumbnail
        
        return dict
    }
    
    private struct PropertyKeys{
        static let id = "_id"
        //todo: rename to 'original'
        static let original = "data"
        static let thumbnail = "thumbnail"
    }
}