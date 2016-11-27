//
//  Post.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation

public class Post: NSObject, DictionaryInitializable, NSCoding{
    public var id: String?
    public var title: String?
    public var photos: [Photo]?
    public var descr: String?
    public var price: String?
    public var seenTotal: Int?
    public var seenToday: Int?
    public var type: AdType?
    public var locations: [Location]?
    public var url: String?
    public var anonymousPost: Bool?
    public var endDate: NSDate?
    public var user: User?
    public var visible: Bool?
    public var timestamp: NSDate?
    public var trainingCategory: String?
    public var sectionLearning: String?
    public var near: Bool?
    
    public var outDistancePost: String?
    
    var comments = [Comment]()
    
    public override init(){
        super.init()
    }
    
    init(id: String, fields: NSDictionary?){
        super.init()
        self.id = id;
        
        self.update(fields);
    }
    
    public required init(fields: NSDictionary?){
        super.init()
        self.update(fields);
    }
    
    public func isLive() -> Bool{
        if let online = self.user?.isOnline() where online, let near = self.near where near {
            return true
        }
        
        return false
    }
    
    public func removedHtmlFromPostDescription( postDescription: String? ) -> String? {
        if postDescription == nil { return nil }
        return postDescription!.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
    }
    
    public func update(fields: NSDictionary?){
        if let id = fields?.valueForKey(PropertyKey.id) as? String {
            self.id = id
        }
        
        if let type = fields?.valueForKey(PropertyKey.type) as? String {
            self.type = AdType(rawValue: type)
        }
        
        if let details = fields?.valueForKey(PropertyKey.details) as? NSDictionary {
            self.title = details.valueForKey(PropertyKey.title) as? String
            
            self.descr = details.valueForKey(PropertyKey.description) as? String
            self.anonymousPost = details.valueForKey(PropertyKey.anonymousPost) as? Bool
            self.url = details.valueForKey(PropertyKey.url) as? String
            
            
            if let photos = details.valueForKey(PropertyKey.photoUrls) as? NSArray {
                self.photos = [Photo]()
                for photoUrl in photos {
                    if let url = photoUrl as? String {
                        let photoObj = Photo()
                        photoObj.original = url
                        self.photos!.append(photoObj)
                    }
                }
            } else if let photos = details.valueForKey(PropertyKey.photos) as? NSArray{
                self.photos = [Photo]()
                for photo in photos {
                    if let photoFields = photo as? NSDictionary{
                        let photoObj = Photo(fields: photoFields)
                        if photoObj.original != nil{
                            self.photos!.append(photoObj)
                        }
                    }
                }
            }
            
            if let locations = details.valueForKey(PropertyKey.locations) as? NSArray {
                self.locations = [Location]()
                for location in locations {
                    if let locationFields = location as? NSDictionary{
                        self.locations?.append(Location(fields: locationFields))
                    }
                }
            }
            
            self.price = details.valueForKey(PropertyKey.price) as? String
        }
        
        if let stats = fields?.valueForKey(PropertyKey.stats) as? NSDictionary{
            if let seenTotal = stats.valueForKey(PropertyKey.seenTotal)as? Int{
                self.seenTotal = seenTotal;
            } else {
                self.seenTotal = 0
            }
            if let seenToday = stats.valueForKey(PropertyKey.seenToday) as? Int{
                self.seenToday = seenToday;
            } else {
                self.seenToday = 0
            }
        }
        if let presences = fields?.valueForKey("presences") as? NSDictionary {
            if let dynamicPresence = presences.valueForKey("dynamic") as? String where dynamicPresence == "close"{
                self.near = true
            } else if let staticPresence = presences.valueForKey("static") as? String where staticPresence == "close"{
                self.near = true
            }
        }
        
        if let statusFields = fields?.valueForKey(PropertyKey.status) as? NSDictionary{
            if let visible = statusFields.valueForKey(PropertyKey.visible) as? String where visible == PropertyKey.visible {
                self.visible = true
            } else {
                self.visible = false
            }
        }
        
        if let userFields = fields?.valueForKey(PropertyKey.user) as? NSDictionary {
            self.user = User(fields: userFields)
        }
        if let endDateMilliseconds = fields?.valueForKey(PropertyKey.endDate) as? Double {
            self.endDate = NSDate(timeIntervalSince1970: endDateMilliseconds / 1000)
        }
        if let timestampMillisecnods = fields?.valueForKey(PropertyKey.timestamp) as? Double {
            self.timestamp = NSDate(timeIntervalSince1970: timestampMillisecnods / 1000)
        }
    }
    
    public func getMainPhoto() -> Photo? {
        if self.photos?.count > 0 {
            return self.photos?[0]
        }
        
        return nil
    }
    
    @objc public required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObjectForKey(PropertyKey.id) as? String
        self.title = aDecoder.decodeObjectForKey(PropertyKey.title) as? String
        self.descr = aDecoder.decodeObjectForKey(PropertyKey.description) as? String
        self.price = aDecoder.decodeObjectForKey(PropertyKey.price) as? String
        if aDecoder.containsValueForKey(PropertyKey.seenTotal){
            self.seenTotal = aDecoder.decodeObjectForKey(PropertyKey.seenTotal) as? Int
        }
        if aDecoder.containsValueForKey(PropertyKey.seenToday){
            self.seenTotal = aDecoder.decodeObjectForKey(PropertyKey.seenToday) as? Int
        }
        self.photos = aDecoder.decodeObjectForKey(PropertyKey.photos) as? [Photo]
        if let type = aDecoder.decodeObjectForKey(PropertyKey.type) as? String {
            self.type = AdType(rawValue: type)
        }
        
        self.locations = aDecoder.decodeObjectForKey(PropertyKey.locations) as? [Location]
        self.url = aDecoder.decodeObjectForKey(PropertyKey.url) as? String
        if aDecoder.containsValueForKey(PropertyKey.anonymousPost){
            self.anonymousPost = aDecoder.decodeBoolForKey(PropertyKey.anonymousPost)
        }
        self.endDate = aDecoder.decodeObjectForKey(PropertyKey.endDate) as? NSDate
        self.user = aDecoder.decodeObjectForKey(PropertyKey.user) as? User
        if aDecoder.containsValueForKey(PropertyKey.visible){
            self.visible = aDecoder.decodeBoolForKey(PropertyKey.visible)
        }
        if aDecoder.containsValueForKey(PropertyKey.near){
            self.near = aDecoder.decodeBoolForKey(PropertyKey.near)
        }
        self.timestamp = aDecoder.decodeObjectForKey(PropertyKey.timestamp) as? NSDate
        
        super.init()
    }
    
    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey: PropertyKey.id)
        aCoder.encodeObject(title, forKey: PropertyKey.title)
        aCoder.encodeObject(photos, forKey: PropertyKey.photos)
        aCoder.encodeObject(descr, forKey: PropertyKey.description)
        aCoder.encodeObject(price, forKey: PropertyKey.price)
        if let seenTotal = self.seenTotal{
            aCoder.encodeInteger(seenTotal, forKey: PropertyKey.seenTotal)
        }
        if let seenToday = self.seenToday{
            aCoder.encodeInteger(seenToday, forKey: PropertyKey.seenToday)
        }
        aCoder.encodeObject(type?.rawValue, forKey: PropertyKey.type)
        aCoder.encodeObject(locations, forKey: PropertyKey.locations)
        aCoder.encodeObject(url, forKey: PropertyKey.url)
        if let anonymousPost = self.anonymousPost{
            aCoder.encodeBool(anonymousPost, forKey: PropertyKey.anonymousPost)
        }
        
        aCoder.encodeObject(endDate, forKey: PropertyKey.endDate)
        aCoder.encodeObject(user, forKey: PropertyKey.user)
        if let visible = self.visible{
            aCoder.encodeBool(visible, forKey: PropertyKey.visible)
        }
        if let near = self.near{
            aCoder.encodeBool(near, forKey: PropertyKey.near)
        }
        
        aCoder.encodeObject(timestamp, forKey: PropertyKey.timestamp)
    }
    
    func getDistanceFormatted(currentLocation: CLLocation) -> String? {
        var distanceFormatted: String?
        //Post location
        if let locations = self.locations {
            for location in locations {
                if let lat = location.lat, lng = location.lng {
                    distanceFormatted = currentLocation.distanceFromLocationFormatted(CLLocation(latitude: lat, longitude: lng))
                    
                    if location.placeType == .Dynamic {
                        break
                    }
                }
            }
        }
        
        return distanceFormatted
    }
    
    func getDistance(currentLocation: CLLocation) -> Double? {
        var distance: Double?
        //Post location
        if let locations = self.locations {
            for location in locations {
                if let lat = location.lat, lng = location.lng {
                    distance = currentLocation.distanceFromLocation(CLLocation(latitude: lat, longitude: lng))
                    
                    if location.placeType == .Dynamic {
                        break
                    }
                }
            }
        }
        
        return distance
    }
    
    public func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict[PropertyKey.id] = self.id
        dict[PropertyKey.type] = self.type?.rawValue
        
        if let endDate = self.endDate {
            dict[PropertyKey.endDate] = Int(endDate.timeIntervalSince1970 * 1000)
        }
        if let timestamp = self.timestamp{
            dict[PropertyKey.timestamp] = Int(timestamp.timeIntervalSince1970 * 1000)
        }
        
        var details = Dictionary<String, AnyObject>()
        details[PropertyKey.anonymousPost] = self.anonymousPost
        if let locations = self.locations{
            var locationsArray = Array<Dictionary<String, AnyObject>>()
            for location in locations{
                locationsArray.append(location.toDictionary())
            }
            details[PropertyKey.locations] = locationsArray
        }
        details[PropertyKey.title] = self.title
        details[PropertyKey.description] = self.descr
        details[PropertyKey.price] = self.price
        if let photos = self.photos {
            var photosArray = Array<Dictionary<String, AnyObject>>()
            for photo in photos {
                photosArray.append(photo.toDictionary())
            }
            details[PropertyKey.photos] = photosArray
        }
        dict[PropertyKey.details] = details
        if let visible = self.visible where visible {
            dict[PropertyKey.status] = [PropertyKey.visible: PropertyKey.visible]
        } else {
            dict[PropertyKey.status] = [PropertyKey.visible: false]
        }
        
        if self.type == .Trainings {
            var trainingDetails = Dictionary<String, AnyObject>()
            trainingDetails[PropertyKey.trainingCategory] = self.trainingCategory
            trainingDetails[PropertyKey.sectionLearning] = self.sectionLearning
            dict[PropertyKey.trainingDetails] = trainingDetails
        }
        
        return dict
    }
    
    private struct PropertyKey{
        static let id = "_id"
        static let title = "title"
        static let description = "description"
        static let price = "price"
        static let seenTotal = "seenTotal"
        static let seenToday = "seenToday"
        static let photos = "photos"
        static let type = "type"
        static let locations = "locations"
        static let url = "url"
        static let anonymousPost = "anonymousPost"
        static let endDate = "endDatePost"
        static let user = "user"
        static let visible = "visible"
        static let details = "details"
        static let stats = "stats"
        static let status = "status"
        static let timestamp = "timestamp"
        static let trainingCategory = "typeCategory"
        static let sectionLearning = "sectionLearning"
        static let trainingDetails = "trainingsDetails"
        static let jobDetails = "jobsDetails"
        static let photoUrls = "photosUrls"
        static let near = "near"
    }
    
    public enum AdType: String {
        case Jobs = "jobs"
        case Trainings = "trainings"
        case Connect = "connect"
        case Trade = "trade"
        case Housing = "housing"
        case Events = "events"
        case Services = "services"
        case Help = "help"
    }
    
    public enum ConnectionType: String{
        case Artists = "artists"
        case Friends = "friends"
        case Sport = "sport"
        case Professionals = "professionals"
        case Other = "other"
    }
    
    public enum TrainingType: String{
        case Learn = "learn"
        case Train = "train"
    }
    
    public enum TrainingCategoryType: String {
        case Trainings = "trainings"
        case MasterClass = "master-class"
        case Tutoring = "tutoring"
        case Courses = "courses"
        case School = "school"
        case HighSchool = "high-school"
    }
    
    public enum HousingType: String {
        case Roommates = "roommates"
        case Rent = "rent"
        case RentOut = "rentOut"
        case Buy = "buy"
        case Sell = "sell"
    }
    
    public enum LocalEventType: String {
        case Provide = "provide"
        case Need = "need"
    }
    
    public enum HelpType: String{
        case LostMyPet = "Lost my pet"
        case NeedMoneyForFood = "Need money for food"
        case Emergency = "Emergency"
        case Other = "Other"
    }
}