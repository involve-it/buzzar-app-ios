//
//  MyPostDetailsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/20/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

public class MyPostDetailsViewController: UITableViewController, MKMapViewDelegate {
    
    public var post: Post!
    private var imagesScrollViewDelegate:ImagesScrollViewDelegate!;
    
    //GRADIENT VIEW
    @IBOutlet weak var gradientView: GradientView!
    //MAP
    @IBOutlet weak var postMapLocation: MKMapView!
    var annotation: MKPointAnnotation?
    
    @IBOutlet weak var svImages: UIScrollView!
    @IBOutlet weak var btnEdit: UIBarButtonItem!
    
    @IBOutlet weak var txtPostStatus: UILabel!
    @IBOutlet weak var postStatusImage: UIImageView!
    
    
    @IBOutlet weak var txtDetails: UILabel!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtViews: UILabel!
    @IBOutlet weak var txtUsername: UILabel!
    @IBOutlet weak var txtPostCreated: UILabel!
    @IBOutlet weak var txtPostDistance: UILabel!
    @IBOutlet weak var txtPostLocationFormattedAddress: UILabel!
    @IBOutlet weak var postType: UIButton!
    @IBOutlet weak var avatarUser: UIImageView!
    
    @IBAction func btnSendMessage_Click(sender: AnyObject) {
        let alertController = UIAlertController(title: "New message", message: nil, preferredStyle: .Alert);
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Message"
        }
        
        alertController.addAction(UIAlertAction(title: "Send", style: .Default, handler: { (action) in
            if let text = alertController.textFields?[0].text where text != "" {
                alertController.resignFirstResponder()
                let message = MessageToSend()
                message.destinationUserId = self.post.user!.id
                message.message = alertController.textFields![0].text
                ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                    if success {
                        AccountHandler.Instance.updateMyChats()
                    } else {
                        self.showAlert("Erorr", message: errorMessage)
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {action in
            alertController.resignFirstResponder()
        }));
        self.presentViewController(alertController, animated: true) { 
            alertController.textFields![0].becomeFirstResponder()
        }
    }
    
    @IBAction func btnShare_Click(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post: http://msg.webhop.org/post/\(self.post.id!)", NSURL(string: "http://msg.webhop.org/post/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeOpenInIBooks, UIActivityTypeSaveToCameraRoll];
        navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    
    public override func viewDidLoad() {
        self.navigationItem.title = post?.title
        
        //Title
        self.txtTitle.text = post?.title
        self.txtTitle.sizeToFit()
        
        //Description
        self.txtDetails.text = post?.descr
        self.txtDetails.sizeToFit()
        
        //Username
        if let username = post.user?.username {
            self.txtUsername.text = username
        }
        
        //Avatar image
        let avatarUrlString = post.user?.imageUrl
        if let checkedUrl = NSURL(string: avatarUrlString!) {
            avatarUser.contentMode = .ScaleToFill
            downloadImage(checkedUrl)
        }
        
        var views = ""
        
        //Seen total
        if let seenTotal = post?.seenTotal {
            views = views + "\(seenTotal)";
        }
        
        /*
         //Seen today
        if let seenToday = post?.seenToday{
            views+=" Today: \(seenToday)";
        }
        */
        
        self.txtViews.text = views;
        
        
        //Post Created
        txtPostCreated.text = post.timestamp?.toLocalizedString()
        
        //Post Distance
        txtPostDistance.text = post.outDistancePost
        
        //MAP
        self.postMapLocation.zoomEnabled = false;
        self.postMapLocation.scrollEnabled = false;
        self.postMapLocation.userInteractionEnabled = false;
        
        //POST LOCATION
        if let postCoordinateLocation = post.locations {
            let geoCoder = CLGeocoder()
            
            var postLocation:Location?
            
            for coordinateLocation in postCoordinateLocation {
                if coordinateLocation.placeType! == .Dynamic {
                    postLocation = coordinateLocation
                    self.txtPostStatus.text = "Dynamic"
                    
                    let typeImage = ( post.isLive() ) ? "PostType_Dynamic_Live" : "PostType_Dynamic"
                    self.postStatusImage.image = UIImage(named: typeImage)
                    
                    break
                    
                } else {
                    //if coordinateLocation.placeType! == .Static
                    postLocation = coordinateLocation
                    self.txtPostStatus.text = "Static"
                    
                    let typeImage = ( post.isLive() ) ? "PostType_Static_Live" : "PostType_Static"
                    self.postStatusImage.image = UIImage(named: typeImage)
                }
            }
            
            if let postLoc = postLocation, lat = postLoc.lat, lng = postLoc.lng {
                self.postMapLocation.hidden = false
                let location = CLLocation(latitude: lat, longitude: lng)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location.coordinate
                annotation.title = postLoc.name
                self.postMapLocation.showAnnotations([annotation], animated: false)
                self.postMapLocation.selectAnnotation(annotation, animated: false)
                
                geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                    if error != nil {
                        print("Reverse geocoder failed with error" + error!.localizedDescription)
                        return
                    }
                    
                    if let placemarks = placemarks {
                        let placemark = placemarks[0]
                        
                        if let name = placemark.name {
                            ThreadHelper.runOnMainThread({
                                annotation.title = name
                            })
                        }
                        
                        ThreadHelper.runOnMainThread({ 
                            if let formattedAddress = placemark.addressDictionary!["FormattedAddressLines"] {
                                let allResults = (formattedAddress as! [String]).joinWithSeparator(", ")
                                self.txtPostLocationFormattedAddress.text = allResults
                            } else {
                                self.txtPostLocationFormattedAddress.text = "Address not defined"
                            }
                        })
                    }
                })
            } else {
                self.postMapLocation.hidden = true
            }
        }
        
        //POST TYPE
        if let txtPostType = post.type?.rawValue {
                postType.setTitle(txtPostType, forState: .Normal)
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        if (self.imagesScrollViewDelegate == nil){
            self.imagesScrollViewDelegate = ImagesScrollViewDelegate(mainView: self.view, scrollView: self.svImages, viewController: self);
        }
        
        self.updateScrollView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateScrollView), name: UIDeviceOrientationDidChangeNotification, object: nil)
        if let index = self.navigationItem.rightBarButtonItems?.indexOf(self.btnEdit){
            self.navigationItem.rightBarButtonItems?.removeAtIndex(index)
        }
        if self.post?.user?.id == AccountHandler.Instance.currentUser?.id {
            self.navigationItem.rightBarButtonItems?.append(self.btnEdit)
        }
        
        
    }
    
    func updateScrollView(){
        let urls = post?.photos?.filter({ $0.original != nil }).map({ $0.original! });
        self.imagesScrollViewDelegate.setupScrollView(urls);
    }
    
    /* LOAD AVATAR FROM URL */
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL){
        //print("Download Started")
        //print("lastPathComponent: " + (url.lastPathComponent ?? ""))
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                //print(response?.suggestedFilename ?? "")
                //print("Download Finished")
                self.avatarUser.image = UIImage(data: data)
            }
        }
    }
    /* END load avatar from url */
    
    /*public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
      
         if indexPath.row == 0 {
            return 260;
        } else if indexPath.row == 1 {
            if (txtViews.text?.characters.count > 0) {
                return 52;
            } else {
                return 0;
            }
        } else if (indexPath.row == 3){
            if let height = post?.descr?.heightWithConstrainedWidth(self.view.frame.width - 16, font: self.txtDetails.font){
                return max(height, 60);
            } else {
                return 0
            }
        } else {
            return 150;
        }
        
    }*/
 
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editPost"{
            let vc = segue.destinationViewController as! UINavigationController
            let createVc = vc.viewControllers[0] as! NewPostViewController
            createVc.post = self.post
        }
    }
    
    
}
