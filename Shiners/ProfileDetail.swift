//
//  ProfileDetail.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class ProfileDetail: MeteorDocument{
    public var userId: String?;
    public var key: String?;
    public var value: String?;
    public var policy: String?;
}