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

let cssStyle = "<style> * {font-family: '-apple-system','HelveticaNeue'; font-size:10pt;} p {font-size:10pt;}  </style>"

public class PostDetailsViewController: UIViewController, UIWebViewDelegate, MKMapViewDelegate, UIViewControllerPreviewingDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    
    @IBOutlet weak var commentHeightCollectionView: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    let commentCellId = "cellComment"
    
    var collectionViewHeight:CGFloat = 0.0
    
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
    
    @IBOutlet weak var iconFavoritesCount: UIImageView!
    @IBOutlet weak var iconViewsCount: UIImageView!
    @IBOutlet weak var iconLocation: UIImageView!
    
    @IBOutlet weak var callStack: UIStackView!
    @IBOutlet weak var writeStack: UIStackView!
    
    @IBOutlet weak var callWriteView: UIView!
    @IBOutlet weak var callWriteViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var txtPostStatus: UILabel!
    
    let uiBlueColor = UIColor(red: 90/255, green: 177/255, blue: 231/255, alpha: 1)
    @IBOutlet weak var postStatusImage: UIImageView!
    
    //Page control for svImage
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var postDescription: UIWebView!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtPostDateExpires: UILabel!
    @IBOutlet weak var txtViews: UILabel!
    @IBOutlet weak var txtFavoritesCount: UILabel!
    @IBOutlet weak var txtUsername: UILabel!
    @IBOutlet weak var txtPostCreated: UILabel!
    @IBOutlet weak var txtPostDistance: UILabel!
    @IBOutlet weak var txtPostLocationFormattedAddress: UILabel!
    @IBOutlet weak var avatarUser: UIImageView!
    @IBOutlet weak var btnSendMessage: UIButton!
    

    @IBOutlet weak var btnAddComment: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var btnViewAllComments: UIButton!
    
    var phoneNumber: String?
    
    func map_Clicked(sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_FullScreenMap)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboard.instantiateViewControllerWithIdentifier("fullMap") as! UINavigationController
        let vc = nc.viewControllers[0] as! FullMapViewController
        
        vc.geocoderInfo = GeocoderInfo()
        vc.geocoderInfo.address = self.postLocationDisplayed!.name
        vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        
        self.presentViewController(nc, animated: true, completion: nil)
    }
    
    
    @IBAction func btnCall_Click(sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnCall_Clicked)
        if let phoneNumber = self.phoneNumber, url = NSURL(string: "tel://\(phoneNumber)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func btnSendMessage_Click(sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnMessage_Clicked)
        let alertController = UIAlertController(title: NSLocalizedString("New message", comment: "Alert title, New message"), message: nil, preferredStyle: .Alert);
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = NSLocalizedString("Message", comment: "Placeholder, Message")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: "Alert title, Send"), style: .Default, handler: { (action) in
            AppAnalytics.logEvent(.PostDetailsScreen_Msg_BtnSend_Clicked)
            if let text = alertController.textFields?[0].text where text != "" {
                alertController.resignFirstResponder()
                let message = MessageToSend()
                message.destinationUserId = self.post.user!.id
                message.message = alertController.textFields![0].text
                message.associatedPostId = self.post!.id
                ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                    if success {
                        AccountHandler.Instance.updateMyChats()
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    }
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert, title, Cancel"), style: .Cancel, handler: {action in
            AppAnalytics.logEvent(.PostDetailsScreen_Msg_BtnCancel_Clicked)
            alertController.resignFirstResponder()
        }));
        self.presentViewController(alertController, animated: true) {
            alertController.textFields![0].becomeFirstResponder()
        }
    }
    
    @IBAction func btnShare_Click(sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnShare_Clicked)
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post on Shiners: \(self.post.title!)", NSURL(string: "\(ConnectionHandler.publicUrl)/posts/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeOpenInIBooks, UIActivityTypeSaveToCameraRoll];
        navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    
        iconFavoritesCount.image = UIImage(named: "favorites_standart")?.imageWithRenderingMode(.AlwaysTemplate)
        iconFavoritesCount.tintColor = uiBlueColor
        
        iconViewsCount.image = UIImage(named: "view_eye")?.imageWithRenderingMode(.AlwaysTemplate)
        iconViewsCount.tintColor = uiBlueColor
        
        iconLocation.image = UIImage(named: "mouse_pointer")?.imageWithRenderingMode(.AlwaysTemplate)
        iconLocation.tintColor = uiBlueColor
        
        let gestureRecognizer = self.postMapLocation.gestureRecognizers![0]
        gestureRecognizer.addTarget(self, action: #selector(map_Clicked))

        self.postDescription.delegate = self
        
        self.postDescription.dataDetectorTypes = .Link
        
        self.navigationItem.title = post?.title
        
        //Button View all comments
        self.btnViewAllComments.setTitle("View all comments".uppercaseString, forState: .Normal)
        //self.commentHeightCollectionView.constant = self.collectionViewHeight
        
        //Button likes
        self.btnLike.setImage(UIImage(named: "icon_likes")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnLike.tintColor = UIColor(netHex: 0x4A4A4A)
        self.btnLike.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        
        //Button add_comments
        self.btnAddComment.setImage(UIImage(named: "add_comments")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnAddComment.tintColor = UIColor(netHex: 0x4A4A4A)
        self.btnAddComment.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        
        //Comment Collection View
        //collectionView.registerClass(commentCollectionViewCell.self, forCellWithReuseIdentifier: commentCellId)
        collectionView.registerNib(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        collectionView.backgroundColor = UIColor.whiteColor()
        
        
        
        
        //Check UserId & Post's user id
        let ownPost = post.user?.id == AccountHandler.Instance.userId
        
        if ownPost {
            self.callWriteView.hidden = true
            self.callWriteViewHeight.constant = 0
            self.view.layoutIfNeeded()
        } else {
            if let phoneNumberDetail = post.user?.getProfileDetail(.Phone), phoneNumber = phoneNumberDetail.value where !ownPost{
                self.phoneNumber = phoneNumber
                self.callStack.hidden = false
            } else {
                self.callStack.hidden = true
            }
            
            if !AccountHandler.Instance.isLoggedIn() {
                self.writeStack.hidden = true
            }
            
            let incrementTuple = SeenPostsHandler.updateSeenCounter(post.id!)
            if incrementTuple.incrementToday {
                post.seenToday = (post.seenToday ?? 0) + 1
            }
            if incrementTuple.incrementTotal{
                post.seenTotal = (post.seenTotal ?? 0) + 1
            }
            if incrementTuple.incrementTotal || incrementTuple.incrementToday {
                NotificationManager.sendNotification(NotificationManager.Name.PostUpdated, object: self.post.id)
            }
        }
        
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
        
        //GestureRecognizer on the username and on the avatar
        let tap = UITapGestureRecognizer(target: self, action: #selector(goUserProfile))
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(goUserProfile))
        self.txtUsername.addGestureRecognizer(tap)
        self.avatarUser.addGestureRecognizer(tap1)
        
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
        var views: String!
        
        if let seenTotal = post?.seenTotal {
            views = "\(seenTotal)";
        }
        self.txtViews.text = views ?? "1";
        
        //Favorites count
        
        self.txtFavoritesCount.text = ""
        
        /*
         //Seen today
         if let seenToday = post?.seenToday{
         views+=" Today: \(seenToday)";
         }
         */
        
        //Post Created
        if let postDateCreated = post.timestamp {
            //toLocalizedString()
            txtPostCreated.text = postDateCreated.timestampFormatterForDate().string
        }
        
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
                    //self.txtPostStatus.text = NSLocalizedString("Dynamic", comment: "Post status, Dynamic")
                    
                    //let typeImage = ( post.isLive() ) ? "PostType_Dynamic_Live" : "PostType_Dynamic"
                    let typeImage = ( post.isLive() ) ? "map_marker_live" : "map_marker"
                    self.postStatusImage.image = UIImage(named: typeImage)
                    
                    break
                    
                } else {
                    //if coordinateLocation.placeType! == .Static
                    postLocation = coordinateLocation
                    //self.txtPostStatus.text = NSLocalizedString("Static", comment: "Post status, Static")
                    
                    //let typeImage = ( post.isLive() ) ? "PostType_Static_Live" : "PostType_Static"
                    let typeImage = ( post.isLive() ) ? "map_marker_live" : "map_marker"
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
  
                            if placemark.formatAddress() != "" {
                                self.txtPostLocationFormattedAddress.text = placemark.formatAddress()
                            } else {
                                self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
                            }
                            
//                            if let formattedAddress = placemark.addressDictionary!["FormattedAddressLines"] {
//                                let allResults = (formattedAddress as! [String]).joinWithSeparator(", ")
//                                self.txtPostLocationFormattedAddress.text = allResults
//                            } else {
//                                self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
//                            }
                            
                        })
                    }
                })
            } else {
                self.postMapLocation.hidden = true
                self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
            }
        } else {
            self.postMapLocation.hidden = true
            self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
        }
        
        //POST TYPE
        /*if let txtPostType = post.type?.rawValue {
            postType.setTitle(txtPostType, forState: .Normal)
        }*/
        
        
        //Page Conrol
        self.pageControl.numberOfPages = (post?.photos?.count) ?? 1
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
        if self.post?.user?.id == AccountHandler.Instance.userId {
            //TODO: uncomment when Edit functionality is ready
            //self.navigationItem.rightBarButtonItems?.append(self.btnEdit)
            LocalNotificationsHandler.Instance.reportEventSeen(.MyPosts, id: self.post.id)
        }
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }
    
    //Comment cell configure
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(commentCellId, forIndexPath: indexPath) as! commentCollectionViewCell
        
        cell.userAvatar.backgroundColor = UIColor(netHex: 0x8F8E94)
        
        //let ss = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        
        if let cell = commentCollectionViewCell.fromNib() {
            let size = CGSizeMake(collectionView.frame.width, 1000)
            let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
            
            let estimatedRect = NSString(string: cell.userComment.text!).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13)], context: nil)
            
            self.commentHeightCollectionView.constant = (estimatedRect.height + 25) * CGFloat(collectionView.numberOfItemsInSection(0))
            
            return CGSize(width: collectionView.frame.width, height: estimatedRect.height + 25)
        }
        
        
        return CGSizeZero
        //return CGSize(width: collectionView.frame.width, height: view.frame.height)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
 
    
    
    
    
    
    
    
    
    
    
    
    
    func goUserProfile() {
        AppAnalytics.logEvent(.PostDetailsScreen_UserProfile)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboard.instantiateViewControllerWithIdentifier("settingsLogInUser") as! UINavigationController
        let vc = nc.viewControllers[0] as! ProfileTableViewController
        
        if let post = self.post {
            vc.extUser = post.user
            vc.postId = post.id
            self.presentViewController(nc, animated: true, completion: nil)
        } else {
            //error alert
            print("TAP USER ERRRORRRRR")
        }
        
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        //guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        if CGRectContainsPoint(self.postMapLocation.superview!.frame, location){
            guard let navController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("fullMap") as? UINavigationController else {return nil}
            guard let viewController = navController.viewControllers[0] as? FullMapViewController else {return nil}
            
            viewController.geocoderInfo = GeocoderInfo()
            viewController.geocoderInfo.address = self.postLocationDisplayed!.name
            viewController.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
            previewingContext.sourceRect = self.postMapLocation.frame
            
            return navController
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
        //self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        self.presentViewController(viewControllerToCommit, animated: true, completion: nil)
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
            //let vc = segue.destinationViewController as! UINavigationController
            //let createVc = vc.viewControllers[0] as! NewPostViewController
            //createVc.post = self.post
        } else if segue.identifier == "fullMapSegue"{
            AppAnalytics.logEvent(.PostDetailsScreen_FullScreenMap)
            let nc = segue.destinationViewController as! UINavigationController
            let vc = nc.viewControllers[0] as! FullMapViewController
            vc.geocoderInfo = GeocoderInfo()
            vc.geocoderInfo.address = self.postLocationDisplayed!.name
            vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        }
    }

}


// MARK: extension for CLPlacemark (formatter address)
extension CLPlacemark {
    
    func formatAddress() -> String {
        
        guard let addressDictionary = self.addressDictionary else {return ""}
        
        var formattedString: String = ""
        let street = addressDictionary["Street"] as? String
        //let city = addressDictionary["City"] as? String
        //let state = addressDictionary["State"] as? String
        //let postalCode = addressDictionary["ZIP"] as? String
        //let country = addressDictionary["Country"] as? String
        //let ISOCountryCode = addressDictionary["CountryCode"] as? String
        

        if let street = street {
            formattedString = formattedString + street
        }
        
//        if let state = state {
//            formattedString = formattedString + state + ", "
//        }
        
//        if let postalCode = postalCode {
//            formattedString = formattedString + postalCode + ", "
//        }
        
//        if let country = country {
//            formattedString = formattedString + country
//        }
        
        //formattedString = street! + ", " + state! + ", " + postalCode! + ", " + country!
        
        return formattedString
    }
}

