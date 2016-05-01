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
        "One day", "Two days", "Week", "Two weeks", "Month", "Year"
    ]
    
    private init(){
        
    }
    
    private static var instance: ConstantValuesHandler = ConstantValuesHandler();
    public static var Instance: ConstantValuesHandler {
        return instance;
    }
}