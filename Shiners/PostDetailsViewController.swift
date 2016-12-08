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
import JSQMessagesViewController

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
    //@IBOutlet weak var callWriteViewHeight: NSLayoutConstraint!
    
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
    
    var subscriptionId: String?
    

    @IBOutlet weak var btnAddComment: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var btnViewAllComments: UIButton!
    
    var pendingCommentsAsyncId: String?
    
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
        self.webviewHeightConstraint.constant = 1
        
        if !AccountHandler.Instance.isLoggedIn(){
            self.post.liked = false
        }
    
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
        self.btnViewAllComments.setTitle(NSLocalizedString("View all comments", comment: "View all comments").uppercaseString, forState: .Normal)
        //self.commentHeightCollectionView.constant = self.collectionViewHeight
        
        //Button likes
        self.btnLike.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        self.updateLikeButton()
        
        //Button add_comments
        self.btnAddComment.setImage(UIImage(named: "add_comments")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnAddComment.tintColor = UIColor(netHex: 0x4A4A4A)
        self.btnAddComment.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        
        //Comment Collection View
        //collectionView.registerClass(commentCollectionViewCell.self, forCellWithReuseIdentifier: commentCellId)
        collectionView.registerNib(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.delegate = self
        
        //Check UserId & Post's user id
        let ownPost = post.user?.id == AccountHandler.Instance.userId
        
        if ownPost {
            self.callWriteView.removeFromSuperview()
            //self.callWriteView.hidden = true
            //self.callWriteViewHeight.constant = 0.1
            //self.view.layoutIfNeeded()
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
        if !ownPost {
            if let username = post.user?.username {
                self.txtUsername.text = username
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(goUserProfile))
            let tap1 = UITapGestureRecognizer(target: self, action: #selector(goUserProfile))
            self.txtUsername.addGestureRecognizer(tap)
            self.avatarUser.addGestureRecognizer(tap1)
            
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
        if ownPost {
            //TODO: uncomment when Edit functionality is ready
            //self.navigationItem.rightBarButtonItems?.append(self.btnEdit)
            LocalNotificationsHandler.Instance.reportEventSeen(.MyPosts, id: self.post.id)
            LocalNotificationsHandler.Instance.reportActiveView(.MyPosts, id: self.post.id)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentsPageReceived), name: NotificationManager.Name.CommentsAsyncRequestCompleted.rawValue, object: nil)
        self.btnViewAllComments.hidden = true
        if let pendingCommentsAsyncId = self.pendingCommentsAsyncId {
            if let isCompleted = CommentsHandler.Instance.isCompleted(pendingCommentsAsyncId) where isCompleted {
                self.pendingCommentsAsyncId = nil
                if let comments = CommentsHandler.Instance.getCommentsByRequestId(pendingCommentsAsyncId) {
                    self.post.comments = comments
                    if comments.count > 3 {
                        self.btnViewAllComments.hidden = false
                    }
                }
            }
        }
        if self.subscriptionId == nil {
            if ConnectionHandler.Instance.isNetworkConnected() {
                self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorNetworkConnected), name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
            }
        }
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.CommentAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.CommentUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.CommentRemoved.rawValue, object: nil)
    }
    
    func meteorNetworkConnected(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
        if self.subscriptionId == nil {
            self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
        }
    }
    
    func commentRemoved(notification: NSNotification){
        ThreadHelper.runOnMainThread({
            if self.isVisible() {
                if let comment = notification.object as? Comment where comment.entityId == self.post.id,
                    let index = self.post.comments.indexOf({$0.id == comment.id}) {
                    if self.post.comments.count > 1 {
                        self.collectionView!.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                    } else {
                        self.collectionView!.reloadData()
                    }
                }
                if self.post.comments.count > 3 {
                    self.btnViewAllComments.hidden = false
                } else {
                    self.btnViewAllComments.hidden = true
                }
            }
        })
    }
    
    func updateLikeButton(){
        if (self.post.liked ?? false){
            self.btnLike.setImage(UIImage(named: "favorites_filled")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            self.btnLike.tintColor = UITabBar.appearance().tintColor
        } else {
            self.btnLike.setImage(UIImage(named: "icon_likes")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            self.btnLike.tintColor = UIColor(netHex: 0x4A4A4A)
        }
        
        var likeTitle = NSLocalizedString("Like", comment: "Like")
        if let likes = self.post.likes where likes > 0 {
            likeTitle += " (\(likes))"
        }
        self.btnLike.setTitle(likeTitle, forState: .Normal)
    }
    
    func commentUpdated(notification: NSNotification){
        if let comment = notification.object as? Comment where comment.entityId == self.post.id!, let index = self.post.comments.indexOf({$0.id == comment.id}) where index < 3 {
            ThreadHelper.runOnMainThread({
                if self.isVisible(){
                    self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                }
            })
        }
    }
    
    func appDidBecomeActive(){
        if ConnectionHandler.Instance.isNetworkConnected() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
            self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
        }
    }
    
    func newCommentReceived(notification: NSNotification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment where comment.entityId == self.post.id {
                if self.post.comments.indexOf({$0.id == comment.id}) == nil {
                    self.post.comments.insert(comment, atIndex: 0)
                }
                
                self.collectionView.reloadData()
                if self.post.comments.count > 3 {
                    self.btnViewAllComments.hidden = false
                } else {
                    self.btnViewAllComments.hidden = true
                }
            
                NotificationManager.sendNotification(NotificationManager.Name.PostCommentAddedLocally, object: comment)
            }
        })
    }
    
    func commentsPageReceived(notification: NSNotification){
        if let pendingCommentsAsyncId = self.pendingCommentsAsyncId where pendingCommentsAsyncId == notification.object as! String, let comments = CommentsHandler.Instance.getCommentsByRequestId(pendingCommentsAsyncId) {
            self.post.commentsRequested = true
            self.pendingCommentsAsyncId = nil
            self.post.comments = comments
        
            NotificationManager.sendNotification(.PostCommentsUpdated, object: self.post.id)
            ThreadHelper.runOnMainThread({
                self.collectionView.reloadData()
                //self.commentHeightCollectionView.constant = self.collectionView.contentSize.height
                if comments.count > 3 {
                    self.btnViewAllComments.hidden = false
                }
            })
        }
    }
    
    //Comment cell configure
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        self.commentHeightCollectionView.constant = self.collectionView.contentSize.height
        if self.pendingCommentsAsyncId == nil {
            if post.comments.count == 0{
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCommentMessage", forIndexPath: indexPath) as! CommentCollectionViewMessageCell
                cell.lblMessage.text = NSLocalizedString("There are no comments to this post", comment: "There are no comments to this post")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(commentCellId, forIndexPath: indexPath) as! commentCollectionViewCell
                
                cell.userAvatar.backgroundColor = UIColor(netHex: 0x8F8E94)
                cell.userAvatar.image = ImageCachingHandler.defaultAccountImage
                
                let comment = self.post.comments[indexPath.row]
                cell.userComment.text = comment.text
                cell.username = comment.username!
                cell.commentId = comment.id!
                cell.commentWritten = JSQMessagesTimestampFormatter.sharedFormatter().timestampForDate(comment.timestamp!)
                cell.labelUserInfoConfigure()
                cell.commentId = comment.id!
                cell.btnLike.tag = indexPath.row
                cell.btnLike.removeTarget(self, action: #selector(self.btnLikeComment_Click(_:)), forControlEvents: .TouchUpInside)
                cell.btnLike.addTarget(self, action: #selector(self.btnLikeComment_Click(_:)), forControlEvents: .TouchUpInside)
                cell.setLikes(AccountHandler.Instance.isLoggedIn(), count: comment.likes ?? 0, liked: comment.liked ?? false)
                if let user = comment.user {
                    ImageCachingHandler.Instance.getImageFromUrl(user.imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                        ThreadHelper.runOnMainThread({
                            cell.userAvatar.image = image
                        })
                    })
                }
                
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCommentMessage", forIndexPath: indexPath) as! CommentCollectionViewMessageCell
            cell.lblMessage.text = NSLocalizedString("Loading comments", comment: "Loading comments")
            return cell
        }
        
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.pendingCommentsAsyncId == nil {
            return max(1, min(self.post.comments.count, 3))
        } else {
            return 1
        }
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if self.post.comments.count > 0 {
            let comment = self.post.comments[indexPath.row]
            let size = CGSizeMake(collectionView.frame.width - 60, 1000)
            let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
            
            let estimatedRect = NSString(string: comment.text!).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13)], context: nil)
            
            let newSize = CGSize(width: collectionView.frame.width, height: max(estimatedRect.height, 40) + 20)
            
            return newSize
        }
        else {
            return CGSize(width: collectionView.frame.width, height: 44)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        if AccountHandler.Instance.isLoggedIn() {
            let comment = self.post.comments[indexPath.row]
            let actionController = UIAlertController(title: NSLocalizedString("Comment", comment: "Comment"), message: NSLocalizedString("What would you like to do?", comment: "What would you like to do?"), preferredStyle: .ActionSheet)
            var title = NSLocalizedString("Like", comment: "Like")
            if comment.liked ?? false {
                title = NSLocalizedString("Unlike", comment: "Unlike")
            }
            
            actionController.addAction(UIAlertAction(title: title, style: .Default, handler: { (action) in
                self.doLikeComment(indexPath.row)
            }))
            
            if comment.userId == AccountHandler.Instance.userId || self.post.user!.id! == AccountHandler.Instance.userId {
                actionController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .Destructive, handler: { (action) in
                    if self.isNetworkReachable() {
                        self.doDeleteComment(indexPath.row)
                    }
                }))
            }
            actionController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil))
            
            self.presentViewController(actionController, animated: true, completion: nil)
        }
    }
    
    func btnLikeComment_Click(sender: UIButton){
        let row = sender.tag
        if self.isNetworkReachable() {
            self.doLikeComment(row)
        }
    }
    
    func doLikeComment(index: Int){
        let comment = self.post.comments[index]
        if comment.liked ?? false {
            comment.liked = false
            comment.likes = (comment.likes ?? 0) - 1
            
            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            
            ConnectionHandler.Instance.posts.unlikeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = true
                    comment.likes = (comment.likes ?? 0) + 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible() {
                            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        } else {
            comment.liked = true
            comment.likes = (comment.likes ?? 0) + 1
            
            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            
            ConnectionHandler.Instance.posts.likeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = false
                    comment.likes = (comment.likes ?? 0) - 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible(){
                            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        }
        
    }
    
    func doDeleteComment(index: Int){
        let comment = self.post.comments.removeAtIndex(index)
        
        self.collectionView!.reloadData()
        
        ConnectionHandler.Instance.posts.deleteComment(comment.id!) { (success, errorId, errorMessage, result) in
            if !success {
                ThreadHelper.runOnMainThread({
                    self.post.comments.insert(comment, atIndex: index)
                    if self.isVisible() {
                        self.collectionView!.reloadData()
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                    }
                })
            }
        }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(newCommentReceived), name: NotificationManager.Name.CommentAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentUpdated), name: NotificationManager.Name.CommentUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentRemoved), name: NotificationManager.Name.CommentRemoved.rawValue, object: nil)
        if let annotation = self.annotation{
            self.postMapLocation.selectAnnotation(annotation, animated: false)
        }
        self.collectionView.reloadData()
        if self.post.comments.count > 3 {
            self.btnViewAllComments.hidden = false
        } else {
            self.btnViewAllComments.hidden = true
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
        } else if identifier == "allCommentsNew" && !AccountHandler.Instance.isLoggedIn(){
            self.displayNotLoggedInMessage()
            return false
        } else {
            return true
        }
    }
    
    func displayNotLoggedInMessage(){
        let alertController = UIAlertController(title: NSLocalizedString("You are not logged in", comment: "Alert title, you are not logged in"), message: NSLocalizedString("Please log in to leave a comment or like a post", comment: "Please log in to leave a comment or like a post"), preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: "Login"), style: .Default, handler: { (action) in
            CATransaction.begin()
            CATransaction.setCompletionBlock({ 
                NotificationManager.sendNotification(NotificationManager.Name.DisplaySettings, object: nil)
            })
            self.navigationController?.popToRootViewControllerAnimated(true)
            CATransaction.commit()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
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
        } else if segue.identifier == "allComments" || segue.identifier == "allCommentsNew" {
            let nc = segue.destinationViewController as! UINavigationController
            let vc = nc.viewControllers[0] as! CommentsViewController
            if self.post.comments.count > CommentsHandler.DEFAULT_PAGE_SIZE {
                self.post.comments.removeLast()
                vc.moreCommentsAvailable = true
            }
            vc.post = self.post
            vc.loadingComments = (self.pendingCommentsAsyncId != nil)
            if segue.identifier == "allCommentsNew" {
                vc.addingComment = true
            }
        }
    }
    
    @IBAction func btnLike_Click(sender: AnyObject) {
        if AccountHandler.Instance.isLoggedIn() {
            if (self.post.liked ?? false) {
                self.post.liked = false
                self.post.likes = (self.post.likes ?? 0) - 1
                
                ConnectionHandler.Instance.posts.unlikePost(self.post.id!, callback: { (success, errorId, errorMessage, result) in
                    if !success {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        self.post.liked = true
                        self.post.likes = (self.post.likes ?? 0) + 1
                        ThreadHelper.runOnMainThread({ 
                            self.updateLikeButton()
                        })
                    }
                })
            } else {
                self.post.liked = true
                self.post.likes = (self.post.likes ?? 0) + 1
                ConnectionHandler.Instance.posts.likePost(self.post.id!, callback: { (success, errorId, errorMessage, result) in
                    if !success {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        self.post.liked = false
                        self.post.likes = (self.post.likes ?? 0) - 1
                        ThreadHelper.runOnMainThread({
                            self.updateLikeButton()
                        })
                    }
                })
            }
            self.updateLikeButton()
        } else {
            self.displayNotLoggedInMessage()
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

