//
//  MyPostDetailsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

let cssStyle = "<style> h2 {color:red} p {font-size:10pt;}  </style>"

public class MyPostDetailsViewController: UIViewController, UIWebViewDelegate, MKMapViewDelegate {
    
    
    @IBOutlet weak var webviewHeightConstraint: NSLayoutConstraint!
    
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
    
    //Page control for svImage
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var postDescription: UIWebView!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtViews: UILabel!
    @IBOutlet weak var txtUsername: UILabel!
    @IBOutlet weak var txtPostCreated: UILabel!
    @IBOutlet weak var txtPostDistance: UILabel!
    @IBOutlet weak var txtPostLocationFormattedAddress: UILabel!
    @IBOutlet weak var postType: UIButton!
    @IBOutlet weak var avatarUser: UIImageView!
    
    @IBAction func btnShare_Click(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post: \(ConnectionHandler.baseUrl)/post/\(self.post.id!)", NSURL(string: "\(ConnectionHandler.baseUrl)/post/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeOpenInIBooks, UIActivityTypeSaveToCameraRoll];
        navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.postDescription.delegate = self
        
        self.navigationItem.title = post?.title
        
        //Title
        self.txtTitle.text = post?.title
        self.txtTitle.sizeToFit()
        
        //Description
        self.postDescription.scrollView.scrollEnabled = false
        if let htmlString = post?.descr {
            self.postDescription.loadHTMLString(cssStyle + htmlString, baseURL: nil)
        } else {
            self.postDescription.loadHTMLString("", baseURL: nil)
        }
        
        //Username
        if let username = post.user?.username {
            self.txtUsername.text = username
        }
        
        //Avatar image
        self.avatarUser.contentMode = .ScaleToFill
        if let avatarUrlString = post.user?.imageUrl{
            if ImageCachingHandler.Instance.getImageFromUrl(avatarUrlString, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                ThreadHelper.runOnMainThread({
                    self.avatarUser.image = image
                })
            }){
                self.avatarUser.image = ImageCachingHandler.defaultAccountImage
            }
        } else {
            self.avatarUser.image = ImageCachingHandler.defaultAccountImage
        }
        
        //Seen total
        if let seenTotal = post?.seenTotal {
            self.txtViews.text = "\(seenTotal)";
        }
        
        /*
         //Seen today
         if let seenToday = post?.seenToday{
         views+=" Today: \(seenToday)";
         }
         */
        
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
                                self.txtPostLocationFormattedAddress.text = "Address is not defined"
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
        
        
        //Page Conrol
        self.pageControl.numberOfPages = (post?.photos?.count)!
        self.pageControl.currentPage = 0
        self.pageControl.userInteractionEnabled = false
        //Page control becomes invisible when its numberOfPages changes to 1
        self.pageControl.hidesForSinglePage = true
        
        if (self.imagesScrollViewDelegate == nil){
            self.imagesScrollViewDelegate = ImagesScrollViewDelegate(mainView: self.view, scrollView: self.svImages, viewController: self, pageControl: self.pageControl);
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
    
    //After load content
    public func webViewDidFinishLoad(webView: UIWebView) {
        let contentSize = self.postDescription.scrollView.contentSize.height
        self.webviewHeightConstraint.constant = contentSize
    }
    
    
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editPost"{
            let vc = segue.destinationViewController as! UINavigationController
            let createVc = vc.viewControllers[0] as! NewPostViewController
            createVc.post = self.post
        }
    }
    

}
