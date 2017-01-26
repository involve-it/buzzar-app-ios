//
//  Post.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class Post: NSObject, DictionaryInitializable, NSCoding{
    open var id: String?
    open var title: String?
    open var photos: [Photo]?
    open var descr: String?
    open var price: String?
    open var seenTotal: Int?
    open var seenToday: Int?
    open var type: AdType?
    open var locations: [Location]?
    open var url: String?
    open var anonymousPost: Bool?
    open var endDate: Date?
    open var user: User?
    open var visible: Bool?
    open var timestamp: Date?
    open var trainingCategory: String?
    open var sectionLearning: String?
    open var near: Bool?
    open var likes: Int?
    open var liked: Bool?
    
    open var outDistancePost: String?
    
    open var commentsRequested = false
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
    
    open func isLive() -> Bool{
        if let online = self.user?.isOnline(), online, let near = self.near, near {
            return true
        }
        
        return false
    }
    
    open func removedHtmlFromPostDescription( _ postDescription: String? ) -> String? {
        if postDescription == nil { return nil }
        return postDescription!.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func updateFrom(post: Post){
        self.id = post.id
        self.title = post.title
        if let photos = post.photos {
            self.photos = Array(photos)
        }
        self.descr = post.descr
        self.price = post.price
        self.seenTotal = post.seenTotal
        self.seenToday = post.seenToday
        self.type = post.type
        if let locations = post.locations {
            self.locations = Array(locations)
        }
        //self.url = post.url
        self.anonymousPost = post.anonymousPost
        self.endDate = post.endDate
        
        //self.user = post.user
        self.visible = post.visible
        self.timestamp = post.timestamp
        //self.trainingCategory = post.trainingCategory
        //self.sectionLearning = post.sectionLearning
        //self.near = post.near
        //self.likes = post.likes
        //self.liked = post.liked
    }
    
    open func update(_ fields: NSDictionary?){
        if let id = fields?.value(forKey: PropertyKey.id) as? String {
            self.id = id
        }
        
        if let type = fields?.value(forKey: PropertyKey.type) as? String {
            self.type = AdType(rawValue: type)
        }
        
        if let details = fields?.value(forKey: PropertyKey.details) as? NSDictionary {
            self.title = details.value(forKey: PropertyKey.title) as? String
            
            self.descr = details.value(forKey: PropertyKey.description) as? String
            self.anonymousPost = details.value(forKey: PropertyKey.anonymousPost) as? Bool
            self.url = details.value(forKey: PropertyKey.url) as? String
            
            
            if let photos = details.value(forKey: PropertyKey.photoUrls) as? NSArray {
                self.photos = [Photo]()
                for photoUrl in photos {
                    if let url = photoUrl as? String {
                        let photoObj = Photo()
                        photoObj.original = url
                        self.photos!.append(photoObj)
                    }
                }
            } else if let photos = details.value(forKey: PropertyKey.photos) as? NSArray{
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
            
            if let locations = details.value(forKey: PropertyKey.locations) as? NSArray {
                self.locations = [Location]()
                for location in locations {
                    if let locationFields = location as? NSDictionary{
                        self.locations?.append(Location(fields: locationFields))
                    }
                }
            }
            
            self.price = details.value(forKey: PropertyKey.price) as? String
        }
        
        self.likes = fields?.value(forKey: PropertyKey.likes) as? Int
        self.liked = fields?.value(forKey: PropertyKey.liked) as? Bool
        
        if let stats = fields?.value(forKey: PropertyKey.stats) as? NSDictionary{
            if let seenTotal = stats.value(forKey: PropertyKey.seenTotal)as? Int{
                self.seenTotal = seenTotal;
            } else {
                self.seenTotal = 0
            }
            if let seenToday = stats.value(forKey: PropertyKey.seenToday) as? Int{
                self.seenToday = seenToday;
            } else {
                self.seenToday = 0
            }
        }
        if let presences = fields?.value(forKey: "presences") as? NSDictionary {
            if let dynamicPresence = presences.value(forKey: "dynamic") as? String, dynamicPresence == "close"{
                self.near = true
            } else if let staticPresence = presences.value(forKey: "static") as? String, staticPresence == "close"{
                self.near = true
            }
        }
        
        if let statusFields = fields?.value(forKey: PropertyKey.status) as? NSDictionary{
            if let visible = statusFields.value(forKey: PropertyKey.visible) as? String, visible == PropertyKey.visible {
                self.visible = true
            } else {
                self.visible = false
            }
        }
        
        if let userFields = fields?.value(forKey: PropertyKey.user) as? NSDictionary {
            self.user = User(fields: userFields)
        }
        if let endDateMilliseconds = fields?.value(forKey: PropertyKey.endDate) as? Double {
            self.endDate = Date(timeIntervalSince1970: endDateMilliseconds / 1000)
        } else {
            self.endDate = (fields?.value(forKey: PropertyKey.endDate) as? NSDictionary)?.javaScriptDateFromFirstElement() as Date?
        }
        if let timestampMillisecnods = fields?.value(forKey: PropertyKey.timestamp) as? Double {
            self.timestamp = Date(timeIntervalSince1970: timestampMillisecnods / 1000)
        } else {
            self.timestamp = (fields?.value(forKey: PropertyKey.timestamp) as? NSDictionary)?.javaScriptDateFromFirstElement() as Date?
        }
    }
    
    open func getMainPhoto() -> Photo? {
        if self.photos?.count > 0 {
            return self.photos?[0]
        }
        
        return nil
    }
    
    @objc public required init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeObject(forKey: PropertyKey.id) as? String
        self.title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String
        self.descr = aDecoder.decodeObject(forKey: PropertyKey.description) as? String
        self.price = aDecoder.decodeObject(forKey: PropertyKey.price) as? String
        if aDecoder.containsValue(forKey: PropertyKey.seenTotal){
            self.seenTotal = aDecoder.decodeObject(forKey: PropertyKey.seenTotal) as? Int
        }
        if aDecoder.containsValue(forKey: PropertyKey.seenToday){
            self.seenTotal = aDecoder.decodeObject(forKey: PropertyKey.seenToday) as? Int
        }
        self.photos = aDecoder.decodeObject(forKey: PropertyKey.photos) as? [Photo]
        if let type = aDecoder.decodeObject(forKey: PropertyKey.type) as? String {
            self.type = AdType(rawValue: type)
        }
        
        self.locations = aDecoder.decodeObject(forKey: PropertyKey.locations) as? [Location]
        self.url = aDecoder.decodeObject(forKey: PropertyKey.url) as? String
        if aDecoder.containsValue(forKey: PropertyKey.anonymousPost){
            self.anonymousPost = aDecoder.decodeBool(forKey: PropertyKey.anonymousPost)
        }
        self.endDate = aDecoder.decodeObject(forKey: PropertyKey.endDate) as? Date
        self.user = aDecoder.decodeObject(forKey: PropertyKey.user) as? User
        if aDecoder.containsValue(forKey: PropertyKey.visible){
            self.visible = aDecoder.decodeBool(forKey: PropertyKey.visible)
        }
        if aDecoder.containsValue(forKey: PropertyKey.near){
            self.near = aDecoder.decodeBool(forKey: PropertyKey.near)
        }
        self.timestamp = aDecoder.decodeObject(forKey: PropertyKey.timestamp) as? Date
        if aDecoder.containsValue(forKey: PropertyKey.likes){
            self.likes = aDecoder.decodeObject(forKey: PropertyKey.likes) as? Int
        }
        if aDecoder.containsValue(forKey: PropertyKey.liked){
            self.liked = aDecoder.decodeBool(forKey: PropertyKey.liked)
        }
        
        super.init()
    }
    
    @objc open func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: PropertyKey.id)
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(photos, forKey: PropertyKey.photos)
        aCoder.encode(descr, forKey: PropertyKey.description)
        aCoder.encode(price, forKey: PropertyKey.price)
        if let seenTotal = self.seenTotal{
            aCoder.encode(seenTotal, forKey: PropertyKey.seenTotal)
        }
        if let seenToday = self.seenToday{
            aCoder.encode(seenToday, forKey: PropertyKey.seenToday)
        }
        aCoder.encode(type?.rawValue, forKey: PropertyKey.type)
        aCoder.encode(locations, forKey: PropertyKey.locations)
        aCoder.encode(url, forKey: PropertyKey.url)
        if let anonymousPost = self.anonymousPost{
            aCoder.encode(anonymousPost, forKey: PropertyKey.anonymousPost)
        }
        
        aCoder.encode(endDate, forKey: PropertyKey.endDate)
        aCoder.encode(user, forKey: PropertyKey.user)
        if let visible = self.visible{
            aCoder.encode(visible, forKey: PropertyKey.visible)
        }
        if let near = self.near{
            aCoder.encode(near, forKey: PropertyKey.near)
        }
        
        aCoder.encode(timestamp, forKey: PropertyKey.timestamp)
        if let likes = self.likes {
            aCoder.encode(likes, forKey: PropertyKey.likes)
        }
        if let liked = self.liked {
            aCoder.encode(liked, forKey: PropertyKey.liked)
        }
    }
    
    func getDistanceFormatted(_ currentLocation: CLLocation) -> String? {
        var distanceFormatted: String?
        //Post location
        if let locations = self.locations {
            for location in locations {
                if let lat = location.lat, let lng = location.lng {
                    distanceFormatted = currentLocation.distanceFromLocationFormatted(CLLocation(latitude: lat, longitude: lng))
                    
                    if location.placeType == .Dynamic {
                        break
                    }
                }
            }
        }
        
        return distanceFormatted
    }
    
    func getPostLocationType() -> Location.PlaceType? {
        return self.getPostLocation()?.placeType
    }
    
    func getPostLocation() -> Location? {
        var loc: Location? = nil
        if let locations = self.locations {
            for location in locations {
                loc = location
                
                if location.placeType == .Dynamic {
                    break
                }
            }
        }
        return loc
    }
    
    func getPostCategoryImageName() -> String {
        var imageName: String!
        let locationType = self.getPostLocationType() ?? .Static
        if let postType = self.type?.rawValue {
            imageName = "\(locationType.rawValue)-\(self.isLive() ? "live" : "offline")-flag-" + "\(postType)"
        } else {
            imageName = "\(locationType.rawValue)-\(self.isLive() ? "live" : "offline")-flag-jobs"
        }
        return imageName
    }
    
    func getDistance(_ currentLocation: CLLocation) -> Double? {
        var distance: Double?
        //Post location
        if let locations = self.locations {
            for location in locations {
                if let lat = location.lat, let lng = location.lng {
                    distance = currentLocation.distance(from: CLLocation(latitude: lat, longitude: lng))
                    
                    if location.placeType == .Dynamic {
                        break
                    }
                }
            }
        }
        
        return distance
    }
    
    open func toDictionary() -> Dictionary<String, AnyObject>{
        var dict = Dictionary<String, AnyObject>()
        
        dict[PropertyKey.id] = self.id as AnyObject?
        dict[PropertyKey.type] = self.type?.rawValue as AnyObject?
        
        if let endDate = self.endDate {
            dict[PropertyKey.endDate] = (endDate.timeIntervalSince1970 * 1000) as AnyObject?
        }
        if let timestamp = self.timestamp{
            dict[PropertyKey.timestamp] = (timestamp.timeIntervalSince1970 * 1000) as AnyObject?
        }
        
        var details = Dictionary<String, AnyObject>()
        details[PropertyKey.anonymousPost] = self.anonymousPost as AnyObject?
        if let locations = self.locations{
            var locationsArray = Array<Dictionary<String, AnyObject>>()
            for location in locations{
                locationsArray.append(location.toDictionary())
            }
            details[PropertyKey.locations] = locationsArray as AnyObject?
        }
        details[PropertyKey.title] = self.title as AnyObject?
        details[PropertyKey.description] = self.descr as AnyObject?
        details[PropertyKey.price] = self.price as AnyObject?
        if let photos = self.photos {
            var photosArray = Array<Dictionary<String, AnyObject>>()
            for photo in photos {
                photosArray.append(photo.toDictionary())
            }
            details[PropertyKey.photos] = photosArray as AnyObject?
        }
        dict[PropertyKey.details] = details as AnyObject?
        if let visible = self.visible, visible {
            var status = Dictionary<String, AnyObject>()
            status[PropertyKey.visible] = PropertyKey.visible as AnyObject?
            dict[PropertyKey.status] = status as AnyObject?
        } else {
            var status = Dictionary<String, AnyObject>()
            status[PropertyKey.visible] = false as AnyObject?
            dict[PropertyKey.status] = status as AnyObject?
        }
        
        if self.type == .Trainings {
            var trainingDetails = Dictionary<String, AnyObject>()
            trainingDetails[PropertyKey.trainingCategory] = self.trainingCategory as AnyObject?
            trainingDetails[PropertyKey.sectionLearning] = self.sectionLearning as AnyObject?
            dict[PropertyKey.trainingDetails] = trainingDetails as AnyObject?
        }
        
        return dict
    }
    
    fileprivate struct PropertyKey{
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
        static let likes = "likes"
        static let liked = "liked"
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
