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

open class PostDetailsViewController: UIViewController, UIWebViewDelegate, MKMapViewDelegate, UIViewControllerPreviewingDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var commentHeightCollectionView: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    let commentCellId = "cellComment"
    
    var collectionViewHeight:CGFloat = 0.0
    
    @IBOutlet weak var webviewHeightConstraint: NSLayoutConstraint!
    
    open var post: Post!
    open var isOwnPost = false
    
    fileprivate var imagesScrollViewDelegate:ImagesScrollViewDelegate!;
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
    var scrollToComments = false
        
    func map_Clicked(_ sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_FullScreenMap)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nc = storyboard.instantiateViewController(withIdentifier: "fullMap") as! UINavigationController
        let vc = nc.viewControllers[0] as! FullMapViewController
        
        vc.geocoderInfo = GeocoderInfo()
        vc.geocoderInfo.address = self.postLocationDisplayed!.name
        vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        
        self.present(nc, animated: true, completion: nil)
    }
    
    @IBAction func btnCall_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnCall_Clicked)
        if let phoneNumber = self.phoneNumber, let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func btnSendMessage_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnMessage_Clicked)
        let alertController = UIAlertController(title: NSLocalizedString("New message", comment: "Alert title, New message"), message: nil, preferredStyle: .alert);
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Message", comment: "Placeholder, Message")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: "Alert title, Send"), style: .default, handler: { (action) in
            AppAnalytics.logEvent(.PostDetailsScreen_Msg_BtnSend_Clicked)
            if let text = alertController.textFields?[0].text, text != "" {
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
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert, title, Cancel"), style: .cancel, handler: {action in
            AppAnalytics.logEvent(.PostDetailsScreen_Msg_BtnCancel_Clicked)
            alertController.resignFirstResponder()
        }));
        self.present(alertController, animated: true) {
            alertController.textFields![0].becomeFirstResponder()
        }
    }
    
    @IBAction func btnShare_Click(_ sender: AnyObject) {
        AppAnalytics.logEvent(.PostDetailsScreen_BtnShare_Clicked)
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post on Shiners: \(self.post.title!)", URL(string: "\(ConnectionHandler.publicUrl)/posts/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityType.print, UIActivityType.openInIBooks, UIActivityType.saveToCameraRoll];
        navigationController?.present(activityViewController, animated: true, completion: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.webviewHeightConstraint.constant = 1
        
        if !AccountHandler.Instance.isLoggedIn(){
            self.post.liked = false
        }
    
        iconFavoritesCount.image = UIImage(named: "favorites_standart")?.withRenderingMode(.alwaysTemplate)
        iconFavoritesCount.tintColor = uiBlueColor
        
        iconViewsCount.image = UIImage(named: "view_eye")?.withRenderingMode(.alwaysTemplate)
        iconViewsCount.tintColor = uiBlueColor
        
        iconLocation.image = UIImage(named: "mouse_pointer")?.withRenderingMode(.alwaysTemplate)
        iconLocation.tintColor = uiBlueColor
        
        let gestureRecognizer = self.postMapLocation.gestureRecognizers![0]
        gestureRecognizer.addTarget(self, action: #selector(map_Clicked))

        self.postDescription.delegate = self
        
        self.postDescription.dataDetectorTypes = .link
        
        self.navigationItem.title = post?.title
        
        //Button View all comments
        self.btnViewAllComments.setTitle(NSLocalizedString("View all comments", comment: "View all comments").uppercased(), for: UIControlState())
        //self.commentHeightCollectionView.constant = self.collectionViewHeight
        
        //Button likes
        self.btnLike.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        self.updateLikeButton()
        
        //Button add_comments
        self.btnAddComment.setImage(UIImage(named: "add_comments")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        self.btnAddComment.tintColor = UIColor(netHex: 0x4A4A4A)
        self.btnAddComment.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
        
        //Comment Collection View
        //collectionView.registerClass(commentCollectionViewCell.self, forCellWithReuseIdentifier: commentCellId)
        collectionView.register(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        
        //Check UserId & Post's user id
        let ownPost = post.user?.id == AccountHandler.Instance.userId
        
        if ownPost {
            self.callWriteView.removeFromSuperview()
            //self.callWriteView.hidden = true
            //self.callWriteViewHeight.constant = 0.1
            //self.view.layoutIfNeeded()
        } else {
            if let phoneNumberDetail = post.user?.getProfileDetail(.Phone), let phoneNumber = phoneNumberDetail.value, !ownPost{
                self.phoneNumber = phoneNumber
                self.callStack.isHidden = false
            } else {
                self.callStack.isHidden = true
            }
            
            if !AccountHandler.Instance.isLoggedIn() {
                self.writeStack.isHidden = true
            }
            
            let incrementTuple = SeenPostsHandler.updateSeenCounter(post.id!)
            if incrementTuple.incrementToday {
                post.seenToday = (post.seenToday ?? 0) + 1
            }
            if incrementTuple.incrementTotal{
                post.seenTotal = (post.seenTotal ?? 0) + 1
            }
            if incrementTuple.incrementTotal || incrementTuple.incrementToday {
                NotificationManager.sendNotification(NotificationManager.Name.PostUpdated, object: self.post.id as AnyObject?)
            }
        }
        
        //Title
        self.txtTitle.text = post?.title
        self.txtTitle.sizeToFit()
        
        //Description
        self.postDescription.scrollView.isScrollEnabled = false
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
            
            self.avatarUser.contentMode = .scaleToFill
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
        self.postMapLocation.isZoomEnabled = false;
        self.postMapLocation.isScrollEnabled = false;
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
            
            if let postLoc = postLocation, let lat = postLoc.lat, let lng = postLoc.lng {
                self.postMapLocation.isHidden = false
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
                self.postMapLocation.isHidden = true
                self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
            }
        } else {
            self.postMapLocation.isHidden = true
            self.txtPostLocationFormattedAddress.text = NSLocalizedString("Address is not defined", comment: "Location, Address is not defined")
        }
        
        //POST TYPE
        /*if let txtPostType = post.type?.rawValue {
            postType.setTitle(txtPostType, forState: .Normal)
        }*/
        
        
        //Page Conrol
        self.pageControl.numberOfPages = (post?.photos?.count) ?? 1
        self.pageControl.currentPage = 0
        self.pageControl.isUserInteractionEnabled = false
        //Page control becomes invisible when its numberOfPages changes to 1
        self.pageControl.hidesForSinglePage = true
        
        if (self.imagesScrollViewDelegate == nil){
            self.imagesScrollViewDelegate = ImagesScrollViewDelegate(mainView: self.view, scrollView: self.svImages, viewController: self, pageControl: self.pageControl);
        }
        
        self.updateScrollView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateScrollView), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        if let index = self.navigationItem.rightBarButtonItems?.index(of: self.btnEdit){
            self.navigationItem.rightBarButtonItems?.remove(at: index)
        }
        if ownPost {
            //TODO: uncomment when Edit functionality is ready
            //self.navigationItem.rightBarButtonItems?.append(self.btnEdit)
            LocalNotificationsHandler.Instance.reportEventSeen(.myPosts, id: self.post.id)
            LocalNotificationsHandler.Instance.reportActiveView(.myPosts, id: self.post.id)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(commentsPageReceived), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentsAsyncRequestCompleted.rawValue), object: nil)
        self.btnViewAllComments.isHidden = true
        if let pendingCommentsAsyncId = self.pendingCommentsAsyncId {
            if let isCompleted = CommentsHandler.Instance.isCompleted(pendingCommentsAsyncId), isCompleted {
                self.pendingCommentsAsyncId = nil
                if let comments = CommentsHandler.Instance.getCommentsByRequestId(pendingCommentsAsyncId) {
                    self.post.comments = comments
                    if comments.count > 3 {
                        self.btnViewAllComments.isHidden = false
                    }
                }
            }
        }
        if self.subscriptionId == nil {
            if ConnectionHandler.Instance.isNetworkConnected() {
                self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(meteorNetworkConnected), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
            }
        }
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            self.registerForPreviewing(with: self, sourceView: view)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.CommentAdded.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.CommentUpdated.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.CommentRemoved.rawValue), object: nil)
    }
    
    func meteorNetworkConnected(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
        if self.subscriptionId == nil {
            self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
        }
    }
    
    func commentRemoved(_ notification: Notification){
        ThreadHelper.runOnMainThread({
            if self.isVisible() {
                if let comment = notification.object as? Comment, comment.entityId == self.post.id,
                    let index = self.post.comments.index(where: {$0.id == comment.id}) {
                    self.post.comments.remove(at: index)
                    if self.post.comments.count > 1 {
                        self.collectionView!.deleteItems(at: [IndexPath(row: index, section: 0)])
                    } else {
                        self.collectionView!.reloadData()
                    }
                }
                if self.post.comments.count > 3 {
                    self.btnViewAllComments.isHidden = false
                } else {
                    self.btnViewAllComments.isHidden = true
                }
            }
        })
    }
    
    func updateLikeButton(){
        if (self.post.liked ?? false){
            self.btnLike.setImage(UIImage(named: "favorites_filled")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            self.btnLike.tintColor = UITabBar.appearance().tintColor
        } else {
            self.btnLike.setImage(UIImage(named: "icon_likes")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            self.btnLike.tintColor = UIColor(netHex: 0x4A4A4A)
        }
        
        var likeTitle = NSLocalizedString("Like", comment: "Like")
        if let likes = self.post.likes, likes > 0 {
            likeTitle += " (\(likes))"
        }
        self.btnLike.setTitle(likeTitle, for: UIControlState())
    }
    
    func commentUpdated(_ notification: Notification){
        if let comment = notification.object as? Comment, comment.entityId == self.post.id!, let index = self.post.comments.index(where: {$0.id == comment.id}), index < 3 {
            ThreadHelper.runOnMainThread({
                if self.isVisible(){
                    self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
                }
            })
        }
    }
    
    func appDidBecomeActive(){
        if ConnectionHandler.Instance.isNetworkConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
            self.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(self.post.id!)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorNetworkConnected.rawValue), object: nil)
        }
    }
    
    func newCommentReceived(_ notification: Notification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment, comment.entityId == self.post.id {
                if self.post.comments.index(where: {$0.id == comment.id}) == nil {
                    self.post.comments.insert(comment, at: 0)
                }
                
                self.collectionView.reloadData()
                if self.post.comments.count > 3 {
                    self.btnViewAllComments.isHidden = false
                } else {
                    self.btnViewAllComments.isHidden = true
                }
            }
        })
    }
    
    func commentsPageReceived(_ notification: Notification){
        if let pendingCommentsAsyncId = self.pendingCommentsAsyncId, pendingCommentsAsyncId == notification.object as! String, let comments = CommentsHandler.Instance.getCommentsByRequestId(pendingCommentsAsyncId) {
            self.post.commentsRequested = true
            self.pendingCommentsAsyncId = nil
            self.post.comments = comments
        
            NotificationManager.sendNotification(.PostCommentsUpdated, object: self.post.id as AnyObject?)
            ThreadHelper.runOnMainThread({
                self.collectionView.reloadData()
                //self.commentHeightCollectionView.constant = self.collectionView.contentSize.height
                if comments.count > 3 {
                    self.btnViewAllComments.isHidden = false
                }
            })
        }
    }
    
    //Comment cell configure
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        self.commentHeightCollectionView.constant = self.collectionView.contentSize.height
        if self.pendingCommentsAsyncId == nil {
            if post.comments.count == 0{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCommentMessage", for: indexPath) as! CommentCollectionViewMessageCell
                cell.lblMessage.text = NSLocalizedString("There are no comments to this post", comment: "There are no comments to this post")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: commentCellId, for: indexPath) as! commentCollectionViewCell
                
                cell.userAvatar.backgroundColor = UIColor(netHex: 0x8F8E94)
                cell.userAvatar.image = ImageCachingHandler.defaultAccountImage
                
                let comment = self.post.comments[indexPath.row]
                cell.userComment.text = comment.text
                cell.username = comment.username!
                cell.commentId = comment.id!
                cell.commentWritten = JSQMessagesTimestampFormatter.shared().timestamp(for: comment.timestamp! as Date!)
                cell.labelUserInfoConfigure()
                cell.commentId = comment.id!
                cell.btnLike.tag = indexPath.row
                cell.btnLike.removeTarget(self, action: #selector(self.btnLikeComment_Click(_:)), for: .touchUpInside)
                cell.btnLike.addTarget(self, action: #selector(self.btnLikeComment_Click(_:)), for: .touchUpInside)
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCommentMessage", for: indexPath) as! CommentCollectionViewMessageCell
            cell.lblMessage.text = NSLocalizedString("Loading comments", comment: "Loading comments")
            return cell
        }
        
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.pendingCommentsAsyncId == nil {
            return max(1, min(self.post.comments.count, 3))
        } else {
            return 1
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.post.comments.count > 0 {
            let comment = self.post.comments[indexPath.row]
            let size = CGSize(width: collectionView.frame.width - 60, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            
            let estimatedRect = NSString(string: comment.text!).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)], context: nil)
            
            let newSize = CGSize(width: collectionView.frame.width, height: max(estimatedRect.height, 40) + 20)
            
            return newSize
        }
        else {
            return CGSize(width: collectionView.frame.width, height: 44)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if AccountHandler.Instance.isLoggedIn() {
            let comment = self.post.comments[indexPath.row]
            let actionController = UIAlertController(title: NSLocalizedString("Comment", comment: "Comment"), message: NSLocalizedString("What would you like to do?", comment: "What would you like to do?"), preferredStyle: .actionSheet)
            var title = NSLocalizedString("Like", comment: "Like")
            if comment.liked ?? false {
                title = NSLocalizedString("Unlike", comment: "Unlike")
            }
            
            actionController.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
                self.doLikeComment(indexPath.row)
            }))
            
            if comment.userId == AccountHandler.Instance.userId || self.post.user!.id! == AccountHandler.Instance.userId {
                actionController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (action) in
                    if self.isNetworkReachable() {
                        self.doDeleteComment(indexPath.row)
                    }
                }))
            }
            actionController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
            
            self.present(actionController, animated: true, completion: nil)
        }
    }
    
    func btnLikeComment_Click(_ sender: UIButton){
        let row = sender.tag
        if self.isNetworkReachable() {
            self.doLikeComment(row)
        }
    }
    
    func doLikeComment(_ index: Int){
        let comment = self.post.comments[index]
        if comment.liked ?? false {
            comment.liked = false
            comment.likes = (comment.likes ?? 0) - 1
            
            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            
            ConnectionHandler.Instance.posts.unlikeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = true
                    comment.likes = (comment.likes ?? 0) + 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible() {
                            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        } else {
            comment.liked = true
            comment.likes = (comment.likes ?? 0) + 1
            
            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            
            ConnectionHandler.Instance.posts.likeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = false
                    comment.likes = (comment.likes ?? 0) - 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible(){
                            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        }
        
    }
    
    func doDeleteComment(_ index: Int){
        let comment = self.post.comments.remove(at: index)
        
        self.collectionView!.reloadData()
        
        ConnectionHandler.Instance.posts.deleteComment(comment.id!) { (success, errorId, errorMessage, result) in
            if !success {
                ThreadHelper.runOnMainThread({
                    self.post.comments.insert(comment, at: index)
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
        let nc = storyboard.instantiateViewController(withIdentifier: "settingsLogInUser") as! UINavigationController
        let vc = nc.viewControllers[0] as! ProfileTableViewController
        
        if let post = self.post {
            vc.extUser = post.user
            vc.postId = post.id
            self.present(nc, animated: true, completion: nil)
        } else {
            //error alert
            print("TAP USER ERRRORRRRR")
        }
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        //guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        if self.postMapLocation.superview!.frame.contains(location){
            guard let navController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "fullMap") as? UINavigationController else {return nil}
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
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentReceived), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentAdded.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(commentUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(commentRemoved), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentRemoved.rawValue), object: nil)
        if let annotation = self.annotation{
            self.postMapLocation.selectAnnotation(annotation, animated: false)
        }
        self.collectionView.reloadData()
        if self.post.comments.count > 3 {
            self.btnViewAllComments.isHidden = false
        } else {
            self.btnViewAllComments.isHidden = true
        }
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //self.presentViewController(viewControllerToCommit.navigationController!, animated: true, completion: nil)
        //self.showViewController(viewControllerToCommit, sender: self)
        //self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
        self.present(viewControllerToCommit, animated: true, completion: nil)
    }

    func updateScrollView(){
        let urls = post?.photos?.filter({ $0.original != nil }).map({ $0.original! });
        self.imagesScrollViewDelegate.setupScrollView(urls);
    }
    
    open override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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
        let alertController = UIAlertController(title: NSLocalizedString("You are not logged in", comment: "Alert title, you are not logged in"), message: NSLocalizedString("Please log in to leave a comment or like a post", comment: "Please log in to leave a comment or like a post"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: "Login"), style: .default, handler: { (action) in
            CATransaction.begin()
            CATransaction.setCompletionBlock({ 
                NotificationManager.sendNotification(NotificationManager.Name.DisplaySettings, object: nil)
            })
            self.navigationController?.popToRootViewController(animated: true)
            CATransaction.commit()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.scrollToComments {
            self.scrollView.scrollRectToVisible(CGRect(x: 0, y: self.scrollView.contentSize.height - 1, width: 1, height: 1), animated: true)
        }
    }
    
    //After load content
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        let contentSize = self.postDescription.scrollView.contentSize.height
        self.webviewHeightConstraint.constant = contentSize
    }
    
    //fullMapSegue
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editPost"{
            //let vc = segue.destinationViewController as! UINavigationController
            //let createVc = vc.viewControllers[0] as! NewPostViewController
            //createVc.post = self.post
        } else if segue.identifier == "fullMapSegue"{
            AppAnalytics.logEvent(.PostDetailsScreen_FullScreenMap)
            let nc = segue.destination as! UINavigationController
            let vc = nc.viewControllers[0] as! FullMapViewController
            vc.geocoderInfo = GeocoderInfo()
            vc.geocoderInfo.address = self.postLocationDisplayed!.name
            vc.geocoderInfo.coordinate = CLLocationCoordinate2D(latitude: self.postLocationDisplayed!.lat!, longitude: self.postLocationDisplayed!.lng!)
        } else if segue.identifier == "allComments" || segue.identifier == "allCommentsNew" {
            let nc = segue.destination as! UINavigationController
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
    
    @IBAction func btnLike_Click(_ sender: AnyObject) {
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

