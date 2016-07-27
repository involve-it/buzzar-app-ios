//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit
import CoreLocation

class PostsViewController: UITableViewController, UIViewControllerPreviewingDelegate, SearchViewControllerDelegate, LocationHandlerDelegate{
    
    private var posts = [Post]();
    
    @IBOutlet weak var lcTxtSearchBoxLeft: NSLayoutConstraint!
    @IBOutlet var segmFilter: UISegmentedControl!
    @IBOutlet weak var txtSearchBox: UITextField!
    @IBOutlet var searchView: UIView!
    
    
    
    var searchViewController: NewSearchViewController?
    
    private var meteorLoaded = false;
    private var locationAcquired = false;
    private let locationHandler = LocationHandler()
    private var currentLocation: CLLocationCoordinate2D?
    private var errorMessage: String?
    
    var pendingPostId: String?
    
    @IBAction func unwindPosts(segue: UIStoryboardSegue){
    
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "postDetails"){
            let vc:MyPostDetailsViewController = segue.destinationViewController as! MyPostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = posts[index];
            
            if let currentLocation = self.currentLocation {
                //current location
                let curLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                post.outDistancePost = post.getDistanceFormatted(curLocation)
            }
            
            vc.post = post;
        } else if (segue.identifier == "searchSegue"){
            self.searchViewController = segue.destinationViewController as? NewSearchViewController
            self.searchViewController?.delegate = self
        }
    }
    
    func checkPending(){
        if let pendingPostId = self.pendingPostId, postIndex = self.posts.indexOf({$0.id == pendingPostId}){
            self.navigationController?.popToViewController(self, animated: false)
            let indexPath = NSIndexPath(forRow: postIndex, inSection: 0)
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
            self.performSegueWithIdentifier("postDetails", sender: self)
        }
        self.pendingPostId = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.posts.count > 0 && ConnectionHandler.Instance.status == .Connected{
            self.checkPending()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.locationHandler.monitorSignificantLocationChanges()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.locationHandler.stopMonitoringLocation()
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        self.locationHandler.delegate = self
        self.searchView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showPostsFromCollection), name: NotificationManager.Name.NearbyPostsSubscribed.rawValue, object: nil)
        
        //self.locationHandler.getLocationOnce()
        
        if CachingHandler.Instance.status != .Complete {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
        } else if let posts = CachingHandler.Instance.postsAll {
            self.posts = posts
        }
        
        if (self.posts.count == 0){
            //self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .None;
        } else {
            //self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .SingleLine;
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorConnected), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(requestLocation), forControlEvents: .ValueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("postDetails") as? PostDetailsViewController
        
        let post = posts[indexPath.row];
        viewController?.post = post
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.showViewController(viewControllerToCommit, sender: self)
    }
    
    func appDidBecomeActive(){
        if self.posts.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending()
        }
    }
    
    func requestLocation(){
        self.locationHandler.getLocationOnce(false)
    }
    
    /*func showPostsFromCollection(){
        self.meteorLoaded = true
        self.posts = AccountHandler.Instance.postsCollection.posts
        self.tableView.separatorStyle = .SingleLine;
        ThreadHelper.runOnMainThread {
            self.tableView.reloadData()
            self.checkPending()
        }
    }*/
    
    func locationReported(geocoderInfo: GeocoderInfo) {
        if geocoderInfo.denied {
            self.errorMessage = "Please allow location services in settings"
            ThreadHelper.runOnMainThread {
                self.tableView.reloadData()
            }
        } else if geocoderInfo.error {
            self.errorMessage = "An error occurred getting your current location"
            ThreadHelper.runOnMainThread {
                self.tableView.reloadData()
            }
        } else {
            self.currentLocation = geocoderInfo.coordinate
            self.locationAcquired = true
            
            if ConnectionHandler.Instance.status == .Connected {
                //self.subscribeToNearby()
                self.getNearby()
            }
        }
    }
    
    /*private func subscribeToNearby(){
        AccountHandler.Instance.subscribeToNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude, radius: 100);
    }*/
    
    private func getNearby(){
        AccountHandler.Instance.getNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude, radius: 100000) { (success, errorId, errorMessage, result) in
            ThreadHelper.runOnMainThread({
                self.refreshControl?.endRefreshing()
                if success {
                    self.errorMessage = nil
                    self.posts = result as! [Post]
                    self.tableView.reloadData()
                } else {
                    self.errorMessage = errorMessage
                    self.showAlert("Error", message: "Error updating posts")
                    self.tableView.reloadData()
                }
                self.checkPending()
            })
        }
    }
    
    @objc private func meteorConnected(notification: NSNotification){
        if self.locationAcquired {
            //self.subscribeToNearby()
            self.getNearby()
        }
    }
    
    func showOfflineData(){
        if !self.meteorLoaded {
            if let posts = CachingHandler.Instance.postsAll {
                self.posts = posts
                ThreadHelper.runOnMainThread {
                    self.tableView.separatorStyle = .SingleLine;
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func forceLayout(){
        self.searchView.frame = self.view.bounds;
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        //self.view.layoutIfNeeded()
        self.view.layoutSubviews()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if posts.count == 0 {
            if (self.errorMessage != nil || (self.meteorLoaded && self.locationAcquired)){
                let errorCell = tableView.dequeueReusableCellWithIdentifier("postsError") as! ErrorCell
                errorCell.lblMessage.text = self.errorMessage ?? "There are no posts around you"
                cell = errorCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("waitingPosts")
            }
        } else {
            let postCell: PostsTableViewCell = tableView.dequeueReusableCellWithIdentifier("post") as! PostsTableViewCell;
            let post: Post = posts[indexPath.row];
            
            postCell.txtTitle.text = post.title;
            postCell.txtDetails.text = post.descr;
            
            //Additional labels
            if let postCreated = post.timestamp {
                postCell.txtPostCreated.text = postCreated.toLocalizedString()
            } else {
                postCell.txtPostCreated.text = ""
            }
            
            //Post type
            if let locations = post.locations {
                for location in locations {
                    if location.placeType! == .Dynamic {
                        //Post Dynamic
                        let typeImage = (post.isLive()) ? "PostCell_Dynamic_Live" : "PostCell_Dynamic"
                        postCell.imgPostType.image = UIImage(named: typeImage)
                        break
                    } else {
                        //Post Static
                        let typeImage = (post.isLive()) ? "PostCell_Static_Live" : "PostCell_Static"
                        postCell.imgPostType.image = UIImage(named: typeImage)
                    }
                }
            }
            
            //Post disatance
            if let currentLocation = self.currentLocation {
                //current location
                let curLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                
                //Post location
                postCell.txtPostDistance.text = post.getDistanceFormatted(curLocation)
            }
            
            if let price = post.price where post.price != "" {
                postCell.txtPrice.text = "$\(price)";
            } else {
                postCell.txtPrice.text = "";
            }
            var loading = false
            if let url = post.getMainPhoto()?.original {
                loading = ImageCachingHandler.Instance.getImageFromUrl(url) { (image) in
                    dispatch_async(dispatch_get_main_queue(), {
                        if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? PostsTableViewCell{
                            cellToUpdate.imgPhoto?.image = image;
                        }
                    })
                }
            } else {
                postCell.imgPhoto.image = ImageCachingHandler.defaultPhoto;
            }
            if loading {
                postCell.imgPhoto.image = ImageCachingHandler.defaultPhoto;
            }
            cell = postCell
        }
        
        return cell;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, posts.count);
    }
    
    
    //Animation cell
    /*override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.alpha = 0
        UIView.animateWithDuration(0.2, animations: {cell.alpha = 1}, completion: nil)
    }*/
    
    func didApplyFilter() {
        self.closeSearchView()
    }
    
    func closeSearchView(){
        self.txtSearchBox.resignFirstResponder()
        UIView.animateWithDuration(0.4, animations: {
            self.segmFilter.alpha = 1
            self.txtSearchBox.alpha = 0
            self.searchView.alpha = 0
        }) { (_) in
            self.searchView.removeFromSuperview()
            self.tableView.scrollEnabled = true
        }
    }
    
    func openSearchView(){
        self.searchView.frame = self.view.bounds;
        self.tableView.scrollEnabled = false
        
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        self.searchView.alpha = 0
        self.view.addSubview(self.searchView)
        
        self.txtSearchBox.becomeFirstResponder()
        UIView.animateWithDuration(0.4, animations: {
            self.segmFilter.alpha = 0
            self.txtSearchBox.alpha = 1
            self.searchView.alpha = 1
            
        }) { (_) in
            
        }
    }
    
    
    @IBAction func btnSearchClick(sender: AnyObject) {
        if (self.segmFilter.alpha == 0){
            self.closeSearchView()
        } else {
            self.openSearchView()
        }
    }
}