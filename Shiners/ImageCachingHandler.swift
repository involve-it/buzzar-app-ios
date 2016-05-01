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
    private var images: Dictionary<String, ImageEntity> = [:]
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
    
    public func add(id: String, image: UIImage?){
        if (image != nil){
            dispatch_sync(lockQueue){
                if (self.images.count == ImageCachingHandler.MAX_COUNT){
                    if let id = self.findOldestId() {
                        self.images.removeValueForKey(id);
                    }
                }
                self.images[id] = ImageEntity(id: id, image: image!);
            }
        }
    }
    
    public func get(id: String) -> UIImage?{
        var image: UIImage?;
        dispatch_sync(lockQueue){
            image = self.images[id]?.image;
        }
        return image;
    }
    
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
                        let image = UIImage(data: data!);
                        self.add(id, image: image);
                        callback(image: image);
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
    
    public func getImageFromUrl (url: String, callback: (image: UIImage?) ->Void) -> Bool{
        var res = false;
        if let image = self.get(url){
            NSLog("From cache: \(url)")
            callback(image: image);
        } else {
            let nsUrl = NSURL(string: url);
            res = true;
            NSLog("Downloading from url: \(url)")
            NSURLSession.sharedSession().dataTaskWithURL(nsUrl!){data, response, error in
                if (error == nil && data != nil){
                    let image = UIImage(data: data!);
                    self.add(url, image: image);
                    callback(image: image);
                } else {
                    NSLog("Error: \(error)");
                    callback(image: ImageCachingHandler.defaultImage);
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