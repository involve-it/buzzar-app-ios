//
//  ImageCachingHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit

public class ImageCachingHandler{
    private static let imagesDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent("images")
    private static let contentsFile = ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent("contents")
    
    private var images: Dictionary<String, ImageEntity> = [:]
    private var failedUrls: [String] = []
    private let lockQueue = dispatch_queue_create("org.buzzar.app.Shiners.imageCachingHandler", nil);
    private static let MAX_COUNT = 30;
    public static let defaultImage = UIImage(named: "clipping_picture.png");
    public static let defaultAccountImage = UIImage(named: "show_offliners.png");
    
    private init(){
        
    }
    
    private static var instance: ImageCachingHandler = ImageCachingHandler();
    public class var Instance: ImageCachingHandler {
        return instance;
    }
    
    internal func add(id: String, image: UIImage){
        dispatch_sync(lockQueue){
            if (self.images.count == ImageCachingHandler.MAX_COUNT){
                if let id = self.findOldestId() {
                    self.images.removeValueForKey(id);
                }
            }
            self.images[id] = ImageEntity(id: id, image: image);
        }
    }
    
    private func get(id: String) -> UIImage?{
        var image: UIImage?;
        dispatch_sync(lockQueue){
            image = self.images[id]?.image;
        }
        return image;
    }
    
    //will be deprecated after server refactoring
    public func getImage(imageId: String?, callback: (image: UIImage?) -> Void) -> Bool{
        var res = false;
        if let id = imageId {
            if let image = self.get(id){
                NSLog("From cache: \(id)")
                callback(image: image);
            } else if let imageUrl = ConnectionHandler.Instance.imagesCollection.findOne(id)?.data,
                nsUrl = NSURL(string: imageUrl){
                res = true;
                NSLog("Downloading by id: \(id)")
                NSURLSession.sharedSession().dataTaskWithURL(nsUrl){data, response, error in
                    if (error == nil && data != nil){
                        if let image = UIImage(data: data!){
                            self.add(id, image: image);
                            callback(image: image);
                        } else {
                            callback(image: ImageCachingHandler.defaultImage);
                        }
                    } else {
                        NSLog("Error: \(error)");
                        callback(image: ImageCachingHandler.defaultImage);
                    }
                }.resume()
            } else {
                callback(image: ImageCachingHandler.defaultImage);
            }
        } else {
            callback(image: ImageCachingHandler.defaultImage);
        }
        return res;
    }
    
    public func getImageFromUrl (url: String, defaultImage: UIImage? = ImageCachingHandler.defaultImage, callback: (image: UIImage?) ->Void) -> Bool{
        var res = false;
        if let image = self.get(url){
            NSLog("From memory cache: \(url)")
            callback(image: image);
        } else if self.failedUrls.contains(url) {
            NSLog("Failed URL: \(url)")
            callback(image: defaultImage)
        } else if self.savedImages.keys.contains(url) {
            ThreadHelper.runOnBackgroundThread({
                callback(image: self.loadImageFromLocalCache(url))
            })
        } else {
            let nsUrl = NSURL(string: url);
            res = true;
            NSLog("Downloading from url: \(url)")
            NSURLSession.sharedSession().dataTaskWithURL(nsUrl!){data, response, error in
                if (error == nil && data != nil){
                    if let image = UIImage(data: data!){
                        self.add(url, image: image);
                        self.saveImageToLocalCache(url, image: image)
                        
                        callback(image: image);
                    } else {
                        self.failedUrls.append(url)
                        callback(image: defaultImage);
                    }
                } else {
                    NSLog("Error: \(error)");
                    self.failedUrls.append(url)
                    callback(image: defaultImage);
                }
            }.resume()
        }
            
        return res;
    }
    
    private func findOldestId() -> String?{
        var oldest:NSDate?, id: String?;
        for imageEntity in images{
            if oldest == nil || oldest!.compare(imageEntity.1.timestamp) == NSComparisonResult.OrderedAscending{
                id = imageEntity.0;
                oldest = imageEntity.1.timestamp;
            }
        }
        return id;
    }
    
    //local cache
    
    private var savedImages = [String: LocalImageEntity]()
    private static let maxLocallyCachedImagesCount = 50
    
    public func initLocalCache(){
        self.loadContentsFile()
    }
    
    private func saveImageToLocalCache(url: String, image: UIImage){
        if savedImages[url] == nil {
            let filename = NSUUID().UUIDString
            
            if let imageData = UIImagePNGRepresentation(image) {
                do {
                    try imageData.writeToURL(ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(filename), options: NSDataWritingOptions.DataWritingAtomic)
                
                    let imageEntity = LocalImageEntity(url: url, filename: filename)
                    self.savedImages[url] = imageEntity
                }
                catch {
                    NSLog("Error writing image file: \(filename) for URL: \(url)")
                }
                
                if savedImages.count > ImageCachingHandler.maxLocallyCachedImagesCount {
                    if let oldest = self.savedImages.values.sort({ return $0.0.timestamp.compare($0.1.timestamp) == NSComparisonResult.OrderedAscending }).first{
                        
                        do {
                            let fileManager = NSFileManager()
                            try fileManager.removeItemAtURL(ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(oldest.filename))
                        }
                        catch{
                            NSLog("Error deleting image file: \(oldest.filename) for URL: \(oldest.url)")
                        }
                    }
                }
                self.saveContentsFile()
            }
        }
    }
    
    private func saveContentsFile(){
        NSKeyedArchiver.archiveRootObject(self.savedImages, toFile: ImageCachingHandler.contentsFile.path!)
    }
    
    private func loadContentsFile(){
        if let contents = NSKeyedUnarchiver.unarchiveObjectWithFile(ImageCachingHandler.contentsFile.path!) as? [String:LocalImageEntity]{
            self.savedImages = contents
        }
        
        let fileManager = NSFileManager()
        
        if !ImageCachingHandler.imagesDirectory.checkPromisedItemIsReachableAndReturnError(nil) {
            do {
                try fileManager.createDirectoryAtURL(ImageCachingHandler.imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch{
                NSLog("Unable to create images directory!")
            }
        }
        
        //delete orphans
        let directoryEnumerator = fileManager.enumeratorAtPath(ImageCachingHandler.imagesDirectory.path!)
        while let file = directoryEnumerator?.nextObject() as? String {
            if self.savedImages.values.map({ $0.filename }).indexOf(file) == -1 {
                do {
                    try fileManager.removeItemAtPath(ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(file).path!)
                }
                catch {
                    NSLog("Error deleting image @: \(file)")
                }
            }
        }
    }
    
    private func loadImageFromLocalCache(url: String) -> UIImage?{
        if let imageEntity = self.savedImages[url] {
            return UIImage(contentsOfFile: ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(imageEntity.filename).path!)
        }
        
        return nil
    }
    
    private class LocalImageEntity: NSObject, NSCoding{
        let timestamp: NSDate
        let url: String
        let filename: String
        
        init (url: String, filename: String){
            self.timestamp = NSDate()
            self.url = url
            self.filename = filename
        }
        
        @objc required init(coder aDecoder: NSCoder) {
            self.timestamp = aDecoder.decodeObjectForKey(PropertyKeys.timestamp) as! NSDate
            self.url = aDecoder.decodeObjectForKey(PropertyKeys.url) as! String
            self.filename = aDecoder.decodeObjectForKey(PropertyKeys.filename) as! String
        }
        
        @objc private func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(self.timestamp, forKey: PropertyKeys.timestamp)
            aCoder.encodeObject(self.url, forKey: PropertyKeys.url)
            aCoder.encodeObject(self.filename, forKey: PropertyKeys.filename)
        }
        
        private class PropertyKeys{
            static let timestamp = "timestamp"
            static let url = "url"
            static let filename = "filename"
        }
    }
    
    private class ImageEntity{
        let timestamp: NSDate;
        let id: String;
        let image: UIImage;
        
        init (id: String, image: UIImage){
            self.timestamp = NSDate();
            self.id = id;
            self.image = image;
        }
    }
}