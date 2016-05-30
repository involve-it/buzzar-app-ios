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
        "Job market": "jobs", "Need or provide training": "trainings", "Looking for connections": "connect", "Buy & sell": "trade", "Housing market": "housing", "Local events": "events", "Need or provide service": "services", "Need or give help": "help"
    ]
    
    public let postDateRanges = [
        "One day": 1.0 * 60 * 60 * 24, "Two days": 2.0 * 60 * 60 * 24, "Week": 7.0 * 60 * 60 * 24, "Two weeks": 14.0 * 60 * 60 * 24, "Month": 30.0 * 60 * 60 * 24, "Year": 365.0 * 60 * 60 * 24
    ]
    
    public let currencies = [
        "USD", "RUR"
    ]
    
    private init(){
        
    }
    
    private static var instance: ConstantValuesHandler = ConstantValuesHandler();
    public static var Instance: ConstantValuesHandler {
        return instance;
    }
}