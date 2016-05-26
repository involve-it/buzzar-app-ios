//
//  ConstantValuesHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

public class ConstantValuesHandler {
    public let adTypes = [
        "Job market", "Need or provide training", "Looking for connections", "Buy & sell", "Housing market", "Local events", "Need or provide service", "Need or give help"
    ]
    
    public let postDateRanges = [
        "One day": 1.0 * 60 * 60 * 24, "Two days": 2.0 * 60 * 60 * 24, "Week": 7.0 * 60 * 60 * 24, "Two weeks": 14.0 * 60 * 60 * 24, "Month": 30.0 * 60 * 60 * 24, "Year": 365.0 * 60 * 60 * 24
    ]
    
    private init(){
        
    }
    
    private static var instance: ConstantValuesHandler = ConstantValuesHandler();
    public static var Instance: ConstantValuesHandler {
        return instance;
    }
}