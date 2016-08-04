//
//  PostDetailsViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

let cssStyle = "<style> h2 {color:red} p {font-size:10pt;}  </style>"

public class PostDetailsViewController: UIViewController, UIWebViewDelegate, MKMapViewDelegate, UIViewControllerPreviewingDelegate {
    
    
    @IBOutlet weak var webviewHeightConstraint: NSLayoutConstraint!
    
    public var post: Post!
    public var isOwnPost = false
    
    private var imagesScrollViewDelegate:ImagesScrollViewDelegate!;
    var postLocationDisplayed: Location?
    
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
    @IBOutlet weak var txtPostDateExpires: UILabel!
    @IBOutlet weak var txtViews: UILabel!
    @IBOutlet weak var txtUsername: UILabel!
    @IBOutlet weak var txtPostCreated: UILabel!
    @IBOutlet weak var txtPostDistance: UILabel!
    @IBOutlet weak var txtPostLocationFormattedAddress: UILabel!
    @IBOutlet weak var postType: UIButton!
    @IBOutlet weak var avatarUser: UIImageView!
    @IBOutlet weak var btnSendMessage: UIButton!
    
    func map_Clicked(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewControllerWithIdentifier("fullMap") as? FullMapViewController else { return }
        
        vc.geocoderInfo = GeocoderInfo()
        vc.geocoderInfo.address = self.postLocationDisplayed!.name
        vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
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
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post: \(ConnectionHandler.baseUrl)/post/\(self.post.id!)", NSURL(string: "\(ConnectionHandler.baseUrl)/post/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeOpenInIBooks, UIActivityTypeSaveToCameraRoll];
        navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = self.postMapLocation.gestureRecognizers![0]
        gestureRecognizer.addTarget(self, action: #selector(map_Clicked))

        self.postDescription.delegate = self
        
        self.navigationItem.title = post?.title
        
        //Check UserId & Post's user id
        self.btnSendMessage.hidden = !self.isOwnPost
        
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
        var views = ""
        
        if let seenTotal = post?.seenTotal {
            views = views + "\(seenTotal)";
        }
        
        self.txtViews.text = views;
        
        /*
         //Seen today
         if let seenToday = post?.seenToday{
         views+=" Today: \(seenToday)";
         }
         */
        
        //Post Created
        txtPostCreated.text = post.timestamp?.toLocalizedString()
        
        //Post Date Expires
        txtPostDateExpires.text = post.endDate?.toLeftExpiresDatePost()
        
        //Post Distance
        txtPostDistance.text = post.outDistancePost
        
        //MAP
        self.postMapLocation.zoomEnabled = false;
        self.postMapLocation.scrollEnabled = false;
        //self.postMapLocation.userInteractionEnabled = false;
        
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
            
            self.postLocationDisplayed = postLocation
            
            if let postLoc = postLocation, lat = postLoc.lat, lng = postLoc.lng {
                self.postMapLocation.hidden = false
                let location = CLLocation(latitude: lat, longitude: lng)
                self.annotation = MKPointAnnotation()
                self.annotation!.coordinate = location.coordinate
                self.annotation!.title = postLoc.name
                self.postMapLocation.showAnnotations([self.annotation!], animated: false)
                self.postMapLocation.selectAnnotation(self.annotation!, animated: false)
                
                geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                    if error != nil {
                        print("Reverse geocoder failed with error" + error!.localizedDescription)
                        return
                    }
                    
                    if let placemarks = placemarks {
                        let placemark = placemarks[0]
                        
                        if let name = placemark.name {
                            self.postLocationDisplayed?.name = name
                            ThreadHelper.runOnMainThread({
                                self.annotation!.title = name
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
                self.txtPostLocationFormattedAddress.text = "Address is not defined"
            }
        } else {
            self.postMapLocation.hidden = true
            self.txtPostLocationFormattedAddress.text = "Address is not defined"
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
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        //guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        if CGRectContainsPoint(self.postMapLocation.superview!.frame, location){
            guard let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("fullMap") as? FullMapViewController else {return nil}
            
            viewController.geocoderInfo = GeocoderInfo()
            viewController.geocoderInfo.address = self.postLocationDisplayed!.name
            viewController.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
            previewingContext.sourceRect = self.postMapLocation.frame
            
            return viewController
        } else {
            return nil
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let annotation = self.annotation{
            self.postMapLocation.selectAnnotation(annotation, animated: false)
        }
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        //self.presentViewController(viewControllerToCommit.navigationController!, animated: true, completion: nil)
        //self.showViewController(viewControllerToCommit, sender: self)
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }

    func updateScrollView(){
        let urls = post?.photos?.filter({ $0.original != nil }).map({ $0.original! });
        self.imagesScrollViewDelegate.setupScrollView(urls);
    }
    
    public override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "fullMapSegue"{
            return self.postLocationDisplayed != nil && self.postLocationDisplayed!.lat != nil && self.postLocationDisplayed!.lng != nil
        } else {
            return true
        }
    }
    
    //After load content
    public func webViewDidFinishLoad(webView: UIWebView) {
        let contentSize = self.postDescription.scrollView.contentSize.height
        self.webviewHeightConstraint.constant = contentSize
    }
    
    //fullMapSegue
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editPost"{
            let vc = segue.destinationViewController as! UINavigationController
            let createVc = vc.viewControllers[0] as! NewPostViewController
            createVc.post = self.post
        } else if segue.identifier == "fullMapSegue"{
            let nc = segue.destinationViewController as! UINavigationController
            let vc = nc.viewControllers[0] as! FullMapViewController
            vc.geocoderInfo = GeocoderInfo()
            vc.geocoderInfo.address = self.postLocationDisplayed!.name
            vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        }
    }
    

}
