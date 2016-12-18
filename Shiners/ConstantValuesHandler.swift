//
//  ConstantValuesHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

open class ConstantValuesHandler {
    
    open let adTypes = [
        Post.AdType.Jobs.rawValue: "Job market",
        Post.AdType.Trainings.rawValue: "Need or provide training",
        Post.AdType.Connect.rawValue: "Looking for connections",
        Post.AdType.Trade.rawValue: "Buy & sell",
        Post.AdType.Housing.rawValue: "Housing market",
        Post.AdType.Events.rawValue: "Local events",
        Post.AdType.Services.rawValue: "Need or provide service",
        Post.AdType.Help.rawValue: "Need or give help"
    ]
    
    open let connectionTypes = [
        Post.ConnectionType.Artists.rawValue: "Artists and other creative people",
        Post.ConnectionType.Friends.rawValue: "Friendship",
        Post.ConnectionType.Sport.rawValue: "Sport activities",
        Post.ConnectionType.Professionals.rawValue: "Professionals",
        Post.ConnectionType.Other.rawValue: "Other"
    ]
    
    open let trainingTypes = [
        Post.TrainingType.Learn.rawValue: "Learn",
        Post.TrainingType.Train.rawValue: "Train others"
    ]
    
    open let trainingCategoryTypes = [
        Post.TrainingCategoryType.Trainings.rawValue: "Trainings",
        Post.TrainingCategoryType.MasterClass.rawValue: "Master class",
        Post.TrainingCategoryType.Tutoring.rawValue: "Tutoring",
        Post.TrainingCategoryType.Courses.rawValue: "Courses",
        Post.TrainingCategoryType.School.rawValue: "School",
        Post.TrainingCategoryType.HighSchool.rawValue: "High school"
    ]
    
    open let housingTypes = [
        Post.HousingType.Roommates.rawValue: "Roommates",
        Post.HousingType.Rent.rawValue: "Renting",
        Post.HousingType.RentOut.rawValue: "Renting out",
        Post.HousingType.Buy.rawValue: "Buying",
        Post.HousingType.Sell.rawValue: "Selling"
    ]
    
    open let localEventTypes = [
        Post.LocalEventType.Provide.rawValue: "Provide",
        Post.LocalEventType.Need.rawValue: "Need"
    ]
    
    open let helpTypes = [
        Post.HelpType.LostMyPet.rawValue: "Lost my pet",
        Post.HelpType.NeedMoneyForFood.rawValue: "Need money for food",
        Post.HelpType.Emergency.rawValue: "Emergency Situation",
        Post.HelpType.Other.rawValue: "Other"
    ]
    
    open let categories = ["jobs", "trainings", "connect", "trade", "housing", "events", "services", "help"];
    
    open let postDateRanges = [
        "One day": 1.0 * 60 * 60 * 24, "Two days": 2.0 * 60 * 60 * 24, "Week": 7.0 * 60 * 60 * 24, "Two weeks": 14.0 * 60 * 60 * 24, "Month": 30.0 * 60 * 60 * 24, "Year": 365.0 * 60 * 60 * 24
    ]
    
    open let widgetUrls = [
        WidgetInfo(title: NSLocalizedString("New Post", comment: "Title, New Post"), url: ""),
        WidgetInfo(title: NSLocalizedString("Find a Friend", comment: "Title, Find a Friend"), url: "http://msg.webhop.org/locator?isiframe=true&userId=$$userId$$&lat=$$lat$$&lng=$$lng$$"),
        WidgetInfo(title: NSLocalizedString("Ask a Question", comment: "Title, Ask a Question"), url: "http://msg.webhop.org/locquestion?isiframe=true&userId=$$userId$$&lat=$$lat$$&lng=$$lng$$")
    ]
    
    open let currencies = [
        "USD", "RUR"
    ]
    
    fileprivate init(){
        
    }
    
    fileprivate static var instance: ConstantValuesHandler = ConstantValuesHandler();
    open static var Instance: ConstantValuesHandler {
        return instance;
    }
    
    open class WidgetInfo{
        let title: String
        let url: String
        
        init(title: String, url: String){
            self.title = title
            self.url = url
        }
    }
}
