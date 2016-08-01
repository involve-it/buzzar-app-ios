//
//  ImageCachingHandler.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import AWSS3

let S3BucketName = "shiners/v1.0/public/images";

public class ImageCachingHandler{
    private static let imagesDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent("images")
    private static let contentsFile = ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent("contents")
    
    private var images: Dictionary<String, ImageEntity> = [:]
    //private var imagesPendingUpload: Dictionary<NSURL, LocalImageEntity> = [:]
    private var failedUrls: [String] = []
    private let lockQueue = dispatch_queue_create("org.buzzar.app.Shiners.imageCachingHandler", nil);
    private static let MAX_COUNT = 30;
    public static let defaultPhoto = UIImage(named: "no-image-placeholder.jpg");
    public static let defaultAccountImage = UIImage(named: "show_offliners.png");
    
    private init(){
        self.configureAws()
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
    
    public func saveImage(image: UIImage, callback: (success: Bool, imageUrl: String?) -> Void) -> Void{
        ThreadHelper.runOnBackgroundThread {
            if let imageEntity = self.saveImageToLocalStorage(image) {
                self.uploadPhotoToAmazon(ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(imageEntity.filename), contentType: imageEntity.contentType!, callback: { (url) in
                    if let _ = url{
                        imageEntity.setUrl(url!)
                        self.savedImages[url!] = imageEntity
                        self.saveContentsFile()
                        callback(success: true, imageUrl: url!)
                    } else {
                        callback(success: false, imageUrl: nil)
                    }
                })
            } else {
                callback(success: false, imageUrl: nil)
            }
        }
    }
        
    public func getImageFromUrl (imageUrl: String?, defaultImage: UIImage? = ImageCachingHandler.defaultPhoto, callback: (image: UIImage?) ->Void) -> Bool{
        var loading = false;
        if let url = imageUrl?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            if let image = self.get(url){
                //NSLog("From memory cache: \(imageUrl)")
                callback(image: image);
            } else if self.failedUrls.contains(url) {
                //NSLog("Failed URL: \(imageUrl)")
                callback(image: defaultImage)
            } else if self.savedImages.keys.contains(url) {
                ThreadHelper.runOnBackgroundThread({
                    if let cachedImage = self.loadImageFromLocalCache(url){
                        callback(image: cachedImage)
                    } else {
                        callback(image: defaultImage)
                    }
                })
            } else {
                let nsUrl = NSURL(string: url);
                loading = true;
                //NSLog("Downloading from url: \(imageUrl)")
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
        } else {
            callback(image: defaultImage)
        }
        
        return loading;
    }
    
    func configureAws(){
        // configure authentication with Cognito
        //        let cognitoPoolID = "us-east-1_ckxes1C2W";
        let cognitoPoolID = "us-east-1:611e9556-43f7-465d-a35b-57a31e11af8b";
        let region = AWSRegionType.USEast1;
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:region,
                                                                identityPoolId:cognitoPoolID)
        let configuration = AWSServiceConfiguration(region:region, credentialsProvider:credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration;
    }
    
    private func uploadPhotoToAmazon(url: NSURL, contentType: String, callback: (url: String?)->Void) {
        // See https://www.codementor.io/tips/5748713276/how-to-upload-images-to-aws-s3-in-swift
        // Setup a new swift project in Xcode and run pod install. Then open the created Xcode workspace.
        // Once AWSS3 framework is ready, we need to configure the authentication:
        
        //Add any image to your project and get its URL like this:
        //let ext = "png"
        //let imageURL = NSBundle.mainBundle().URLForResource("lock_open", withExtension: ext)!;
        
        // Prepare the actual uploader:
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = url
        uploadRequest.key = NSProcessInfo.processInfo().globallyUniqueString //+ "." + ext
        uploadRequest.bucket = S3BucketName
        uploadRequest.contentType = contentType
        
        // push img to server:
        let transferManager = AWSS3TransferManager.defaultS3TransferManager();
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                print("Upload failed ❌ (\(error))");
            }
            if let exception = task.exception {
                print("Upload failed ❌ (\(exception))");
            }
            if task.result != nil {
                let urlString = "https://s3.amazonaws.com/\(S3BucketName)/\(uploadRequest.key!)"
                //let s3URL = NSURL(string: urlString)!;
                print("Uploaded to:\n\(urlString)");
                //let data = NSData(contentsOfURL: s3URL);
                //let image = UIImage(data: data!);
                callback(url: urlString)
            }
            else {
                print("Unexpected empty result.")
                callback(url: nil)
            }
            return nil
        }
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
    
    private func saveImageToLocalStorage(image: UIImage) -> LocalImageEntity?{
        let filename = NSUUID().UUIDString
        let url = ImageCachingHandler.imagesDirectory.URLByAppendingPathComponent(filename)
        
        if let imageData = UIImagePNGRepresentation(image) {
            do {
                try imageData.writeToURL(url, options: NSDataWritingOptions.DataWritingAtomic)
                
                return LocalImageEntity(fileName: filename, contentType: self.getContentType(imageData))
                
                //self.imagesPendingUpload[url] = imageEntity
            }
            catch {
                NSLog("Error writing image file: \(filename) for URL: \(url)")
                return nil
            }
            
        }
        return nil
    }
    
    private func getContentType(data: NSData) -> String{
        var c:UInt8 = 0
        data.getBytes(&c, length: 1)
        
        switch (c) {
        case 0xFF:
            return "image/jpeg";
        case 0x89:
            return "image/png";
        case 0x47:
            return "image/gif";
        /*case 0x49:
            break;*/
        case 0x42:
            return "image/bmp";
        case 0x4D:
            return "image/tiff";
        default:
            return "image/png";
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
        let filename: String
        let contentType: String?
        var url: String!
        
        func setUrl(url: String){
            self.url = url
        }
        
        init (url: String, filename: String){
            self.timestamp = NSDate()
            self.url = url
            self.filename = filename
            self.contentType = nil
            super.init()
        }
        
        init (fileName: String, contentType: String){
            self.filename = fileName
            self.timestamp = NSDate()
            self.contentType = contentType
            super.init()
        }
        
        @objc required init(coder aDecoder: NSCoder) {
            self.contentType = nil
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