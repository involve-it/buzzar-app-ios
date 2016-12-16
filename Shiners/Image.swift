//
//  Image.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

open class Image: MeteorDocument{
    open var data: String?;
    open var thumbnail: String?;
    open var userId: String?;
    open var name: String?;
}
