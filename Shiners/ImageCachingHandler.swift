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

open class ImageCachingHandler{
    fileprivate static let imagesDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("images")
    fileprivate static let contentsFile = ImageCachingHandler.imagesDirectory.appendingPathComponent("contents")
    
    fileprivate var images: Dictionary<String, ImageEntity> = [:]
    //private var imagesPendingUpload: Dictionary<NSURL, LocalImageEntity> = [:]
    fileprivate var failedUrls: [String] = []
    fileprivate static let NON_RETRY_ERRORS = [NSURLErrorBadURL, NSURLErrorUnsupportedURL, NSURLErrorDataLengthExceedsMaximum, NSURLErrorUserAuthenticationRequired, NSURLErrorCannotDecodeContentData, NSURLErrorCannotParseResponse, NSURLErrorFileDoesNotExist];
    fileprivate let lockQueue = DispatchQueue(label: "org.buzzar.app.Shiners.imageCachingHandler", attributes: []);
    fileprivate static let MAX_COUNT = 50;
    open static let defaultPhoto = UIImage(named: "no-image-placeholder.jpg");
    open static let defaultAccountImage = UIImage(named: "show_offliners.png");
    
    fileprivate init(){
        self.configureAws()
    }
    
    fileprivate static var instance: ImageCachingHandler = ImageCachingHandler();
    open class var Instance: ImageCachingHandler {
        return instance;
    }
    
    internal func add(_ id: String, image: UIImage){
        lockQueue.sync{
            if (self.images.count == ImageCachingHandler.MAX_COUNT){
                if let id = self.findOldestId() {
                    self.images.removeValue(forKey: id);
                }
            }
            self.images[id] = ImageEntity(id: id, image: image);
        }
    }
    
    fileprivate func get(_ id: String) -> UIImage?{
        var image: UIImage?;
        lockQueue.sync{
            image = self.images[id]?.image;
        }
        return image;
    }
    
    open func saveImage(_ image: UIImage, callback: @escaping (_ success: Bool, _ imageUrl: String?) -> Void) -> UploadDelegate?{
        if let imageEntity = self.saveImageToLocalStorage(image) {
            let request = self.uploadPhotoToAmazon(ImageCachingHandler.imagesDirectory.appendingPathComponent(imageEntity.filename), contentType: imageEntity.contentType!, callback: { (url) in
                if let _ = url{
                    imageEntity.setNewUrl(url!)
                    self.savedImages[url!] = imageEntity
                    self.saveContentsFile()
                    callback(true, url!)
                } else {
                    callback(false, nil)
                }
            })
            return UploadDelegate(uploadRequest: request)
        } else {
            callback(false, nil)
            return nil
        }
    }
        
    open func getImageFromUrl (_ imageUrl: String?, defaultImage: UIImage? = ImageCachingHandler.defaultPhoto, callback: @escaping (_ image: UIImage?) ->Void) -> Bool{
        var loading = false;
        if let url = imageUrl?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            if let image = self.get(url){
                //NSLog("From memory cache: \(imageUrl)")
                callback(image);
            } else if self.failedUrls.contains(url) {
                //NSLog("Failed URL: \(imageUrl)")
                callback(defaultImage)
            } else if self.savedImages.keys.contains(url) {
                ThreadHelper.runOnBackgroundThread({
                    if let cachedImage = self.loadImageFromLocalCache(url){
                        callback(cachedImage)
                    } else {
                        callback(defaultImage)
                    }
                })
            } else {
                let nsUrl = URL(string: url);
                loading = true;
                //NSLog("Downloading from url: \(imageUrl)")
                URLSession.shared.dataTask(with: nsUrl!, completionHandler: {data, response, error in
                    if (error == nil && data != nil){
                        if let image = UIImage(data: data!){
                            self.add(url, image: image);
                            self.saveImageToLocalCache(url, image: image)
                            
                            callback(image);
                        } else {
                            self.failedUrls.append(url)
                            callback(defaultImage);
                        }
                    } else {
                        if (error != nil){
                            print("Error: \(error)");
                            if let _ = ImageCachingHandler.NON_RETRY_ERRORS.index(of: error!._code){
                                self.failedUrls.append(url)
                            }
                        }
                        callback(defaultImage);
                    }
                }).resume()
            }
        } else {
            callback(defaultImage)
        }
        
        return loading;
    }
    
    func configureAws(){
        // configure authentication with Cognito
        //        let cognitoPoolID = "us-east-1_ckxes1C2W";
        let cognitoPoolID = "us-east-1:611e9556-43f7-465d-a35b-57a31e11af8b";
        let region = AWSRegionType.usEast1;
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:region,
                                                                identityPoolId:cognitoPoolID)
        let configuration = AWSServiceConfiguration(region:region, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration;
    }
    
    fileprivate func uploadPhotoToAmazon(_ url: URL, contentType: String, callback: @escaping (_ url: String?) -> Void) -> AWSS3TransferManagerUploadRequest {
        // See https://www.codementor.io/tips/5748713276/how-to-upload-images-to-aws-s3-in-swift
        // Setup a new swift project in Xcode and run pod install. Then open the created Xcode workspace.
        // Once AWSS3 framework is ready, we need to configure the authentication:
        
        //Add any image to your project and get its URL like this:
        //let ext = "png"
        //let imageURL = NSBundle.mainBundle().URLForResource("lock_open", withExtension: ext)!;
        
        // Prepare the actual uploader:
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.body = url
        uploadRequest?.key = ProcessInfo.processInfo.globallyUniqueString //+ "." + ext
        uploadRequest?.bucket = S3BucketName
        uploadRequest?.contentType = contentType
        
        // push img to server:
        let transferManager = AWSS3TransferManager.default();
        
        transferManager!.upload(uploadRequest).continue ({ (task) -> Any? in
            if let error = task.error {
                print("Upload failed ❌ (\(error))");
            }
            if let exception = task.exception {
                print("Upload failed ❌ (\(exception))");
            }
            if task.result != nil {
                let urlString = "https://s3.amazonaws.com/\(S3BucketName)/\(uploadRequest!.key!)"
                //let s3URL = NSURL(string: urlString)!;
                print("Uploaded to:\n\(urlString)");
                //let data = NSData(contentsOfURL: s3URL);
                //let image = UIImage(data: data!);
                callback(urlString)
            }
            else {
                print("Unexpected empty result.")
                callback(nil)
            }
            return nil
        })
        
        return uploadRequest!
    }

    
    fileprivate func findOldestId() -> String?{
        var oldest:Date?, id: String?;
        for imageEntity in images{
            if oldest == nil || oldest!.compare(imageEntity.1.timestamp) == ComparisonResult.orderedAscending{
                id = imageEntity.0;
                oldest = imageEntity.1.timestamp;
            }
        }
        return id;
    }
    
    //local cache
    
    fileprivate var savedImages = [String: LocalImageEntity]()
    fileprivate static let maxLocallyCachedImagesCount = 50
    
    open func initLocalCache(){
        self.loadContentsFile()
    }
    
    fileprivate func saveImageToLocalCache(_ url: String, image: UIImage){
        if savedImages[url] == nil {
            let filename = UUID().uuidString
            
            if let imageData = UIImagePNGRepresentation(image) {
                do {
                    try imageData.write(to: ImageCachingHandler.imagesDirectory.appendingPathComponent(filename), options: NSData.WritingOptions.atomic)
                
                    let imageEntity = LocalImageEntity(url: url, filename: filename)
                    self.savedImages[url] = imageEntity
                }
                catch {
                    NSLog("Error writing image file: \(filename) for URL: \(url)")
                }
                
                if savedImages.count > ImageCachingHandler.maxLocallyCachedImagesCount {
                    if let oldest = self.savedImages.values.sorted(by: { return $0.0.timestamp.compare($0.1.timestamp) == ComparisonResult.orderedAscending }).first{
                        
                        do {
                            let fileManager = FileManager()
                            try fileManager.removeItem(at: ImageCachingHandler.imagesDirectory.appendingPathComponent(oldest.filename))
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
    
    fileprivate func saveImageToLocalStorage(_ image: UIImage) -> LocalImageEntity?{
        let filename = UUID().uuidString
        let url = ImageCachingHandler.imagesDirectory.appendingPathComponent(filename)
        
        if let imageData = UIImagePNGRepresentation(image) {
            do {
                try imageData.write(to: url, options: NSData.WritingOptions.atomic)
                
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
    
    fileprivate func getContentType(_ data: Data) -> String{
        var c:UInt8 = 0
        (data as NSData).getBytes(&c, length: 1)
        
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
    
    fileprivate func saveContentsFile(){
        NSKeyedArchiver.archiveRootObject(self.savedImages, toFile: ImageCachingHandler.contentsFile.path)
    }
    
    fileprivate func loadContentsFile(){
        if let contents = NSKeyedUnarchiver.unarchiveObject(withFile: ImageCachingHandler.contentsFile.path) as? [String:LocalImageEntity]{
            self.savedImages = contents
        }
        
        let fileManager = FileManager()
        
        if !(ImageCachingHandler.imagesDirectory as NSURL).checkPromisedItemIsReachableAndReturnError(nil) {
            do {
                try fileManager.createDirectory(at: ImageCachingHandler.imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch{
                NSLog("Unable to create images directory!")
            }
        }
        
        //delete orphans
        let directoryEnumerator = fileManager.enumerator(atPath: ImageCachingHandler.imagesDirectory.path)
        while let file = directoryEnumerator?.nextObject() as? String {
            if self.savedImages.values.map({ $0.filename }).index(of: file) == -1 {
                do {
                    try fileManager.removeItem(atPath: ImageCachingHandler.imagesDirectory.appendingPathComponent(file).path)
                }
                catch {
                    NSLog("Error deleting image @: \(file)")
                }
            }
        }
    }
    
    fileprivate func loadImageFromLocalCache(_ url: String) -> UIImage?{
        if let imageEntity = self.savedImages[url] {
            return UIImage(contentsOfFile: ImageCachingHandler.imagesDirectory.appendingPathComponent(imageEntity.filename).path)
        }
        
        return nil
    }
    
    fileprivate class LocalImageEntity: NSObject, NSCoding{
        let timestamp: Date
        let filename: String
        let contentType: String?
        var url: String!
        
        func setNewUrl(_ url: String){
            self.url = url
        }
        
        init (url: String, filename: String){
            self.timestamp = Date()
            self.url = url
            self.filename = filename
            self.contentType = nil
            super.init()
        }
        
        init (fileName: String, contentType: String){
            self.filename = fileName
            self.timestamp = Date()
            self.contentType = contentType
            super.init()
        }
        
        @objc required init(coder aDecoder: NSCoder) {
            self.contentType = nil
            self.timestamp = aDecoder.decodeObject(forKey: PropertyKeys.timestamp) as! Date
            self.url = aDecoder.decodeObject(forKey: PropertyKeys.url) as! String
            self.filename = aDecoder.decodeObject(forKey: PropertyKeys.filename) as! String
        }
        
        @objc fileprivate func encode(with aCoder: NSCoder) {
            aCoder.encode(self.timestamp, forKey: PropertyKeys.timestamp)
            aCoder.encode(self.url, forKey: PropertyKeys.url)
            aCoder.encode(self.filename, forKey: PropertyKeys.filename)
        }
        
        fileprivate class PropertyKeys{
            static let timestamp = "timestamp"
            static let url = "url"
            static let filename = "filename"
        }
    }
    
    fileprivate class ImageEntity{
        let timestamp: Date;
        let id: String;
        let image: UIImage;
        
        init (id: String, image: UIImage){
            self.timestamp = Date();
            self.id = id;
            self.image = image;
        }
    }
    
    open class UploadDelegate {
        var id: String?
        fileprivate var uploadRequest: AWSS3TransferManagerUploadRequest!
        init(uploadRequest: AWSS3TransferManagerUploadRequest){
            self.uploadRequest = uploadRequest
        }
        
        func abort(){
            if self.uploadRequest.state != .completed{
                self.uploadRequest.cancel()
            }
        }
    }
}
