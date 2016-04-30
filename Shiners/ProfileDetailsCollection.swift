//
//  ProfileDetailsCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class ProfileDetailsCollection: MeteorCollection<ProfileDetail>{
    public static let LAST_NAME = "lastName";
    public static let FIRST_NAME = "firstName";
    
    public init() {
        super.init(name: "profileDetails")
    }
    
    public func getProfileDetail(userId: String, key: String) -> String?{
        var value: String?;
        
        for profileDetail in self.sorted {
            if profileDetail.userId == userId && profileDetail.key == key{
                value = profileDetail.value;
                break;
            }
        }
        
        return value;
    }
}