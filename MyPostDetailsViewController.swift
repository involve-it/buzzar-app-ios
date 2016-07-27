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
            
            // 2 Взять одну из postCoordinateLocation (array) или Динамик или Статик
            var latitude: CLLocationDegrees?
            var longitude: CLLocationDegrees?
            
            for coordinateLocation in postCoordinateLocation {
                
                if coordinateLocation.placeType! == .Dynamic {
                    latitude = coordinateLocation.lat
                    longitude = coordinateLocation.lng
                    
                    self.txtPostStatus.text = "Dynamic"
                    self.postStatusImage.image = UIImage(named: "PostType_Dynamic")
                } else if coordinateLocation.placeType! == .Static {
                    latitude = coordinateLocation.lat
                    longitude = coordinateLocation.lng
                    
                    self.txtPostStatus.text = "Static"
                    self.postStatusImage.image = UIImage(named: "PostType_Static")
                }
            }
            
            // 3 Вытаскиваем координаты
            //происходит ошибка если нет координат - нужно исправить
            let location = CLLocation(latitude: latitude!, longitude: longitude!)
            
            geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                if error != nil {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                
                if let placemarks = placemarks {
                    let placemark = placemarks[0]
                    
                    let anatation = MKPointAnnotation()
                    
                    if let name = placemark.name {
                        anatation.title = name
                    }
                    
                    
                    if let formattedAddress = placemark.addressDictionary!["FormattedAddressLines"] {
                        let allResults = (formattedAddress as! [String]).joinWithSeparator(", ")
                        self.txtPostLocationFormattedAddress.text = allResults
                    } else {
                        self.txtPostLocationFormattedAddress.text = "Address not defined"
                    }
                    
                    if let pmLocation = placemark.location {
                        anatation.coordinate = pmLocation.coordinate
                        
                        self.postMapLocation.showAnnotations([anatation], animated: true)
                        self.postMapLocation.selectAnnotation(anatation, animated: true)
                    }
                }
                
                
            })

            
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
