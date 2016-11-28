//
//  BeginnerViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

//let SEARCH_TOOLBAR_HEIGHT = CGFloat(44)

class PostsMainViewController: UIViewController, LocationHandlerDelegate, UISearchBarDelegate, UIToolbarDelegate {
    let locationHandler = LocationHandler()
    
    var allPosts = [Post]()
    var posts = [Post]()
    
    var filtering = false
    
    var currentLocation: CLLocationCoordinate2D?
    var pendingPostId: String?
    
    @IBOutlet var btnAddPost: UIBarButtonItem!
    var locationAcquired = false
    var errorMessage: String?
    var meteorLoaded = false
    
    @IBOutlet var typeSwitch: UISegmentedControl!
    @IBOutlet var contentView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    
    @IBOutlet var searchCriteriaToolbar: UIToolbar!
    @IBOutlet var btnSearch: UIBarButtonItem!
    
    var noMorePosts = false
    var loadingPosts = false
    var loadingMorePosts = false
    var staleLocation = false
    
    var searchViewController: NewSearchViewController?
    var currentViewController: UIViewController?
    
    @IBOutlet var searchCriteriaView: UIView!
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    //Identifier postStyle
    private var listInitialized = false
    private var mapInitialized = false
    private var searchToolbarHeight: CGFloat!
    
    lazy var listViewController: PostsViewController! = {
        let list = self.storyBoard.instantiateViewControllerWithIdentifier("postsViewController") as! PostsViewController
        self.listInitialized = true
        return list
    }()
    //Identifier mapStyle
    lazy var mapViewController: PostsMapViewController! = {
        let map = self.storyBoard.instantiateViewControllerWithIdentifier("mapViewControllerForPosts") as! PostsMapViewController
        self.mapInitialized = true
        return map
    }()
    
    enum PostsViewType: Int {
        case list = 0
        case Map
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.locationHandler.monitorSignificantLocationChanges()
        
        if AccountHandler.Instance.isLoggedIn() && !self.filtering {
            self.navigationItem.leftBarButtonItem = self.btnAddPost
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
        
        if filtering {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.posts.count > 0 && ConnectionHandler.Instance.isNetworkConnected() {
            self.checkPending(false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set index for segment
        self.typeSwitch.selectedSegmentIndex = PostsViewType.list.rawValue
        // Load viewController
        self.loadCurrentViewController(self.typeSwitch.selectedSegmentIndex)
        
        self.navigationItem.title = "Posts"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        self.locationHandler.delegate = self
        
        self.locationHandler.getLocationOnce(false)
        
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.getNearby()
        } else if CachingHandler.Instance.status != .Complete {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
        } else if let posts = CachingHandler.Instance.postsAll {
            self.allPosts = posts
            
            if self.filtering{
                self.searchBar(self.searchBar, textDidChange: (self.searchBar.text ?? ""))
            } else {
                self.posts = self.allPosts
            }
        }
        if let currentLocation = LocationHandler.lastLocation {
            self.currentLocation = currentLocation.coordinate
            self.locationAcquired = true
            self.getNearby()
            self.staleLocation = true
        }
        
        self.searchBar.showsCancelButton = true
        self.searchBar.delegate = self
        self.searchCriteriaToolbar.delegate = self
        self.searchToolbarHeight = self.searchCriteriaToolbar.frame.size.height
        self.searchCriteriaView.frame = CGRectMake(0, -self.searchToolbarHeight, self.navigationController!.navigationBar.frame.width, self.searchToolbarHeight)
        
        self.view.addSubview(self.searchCriteriaView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(connectionFailed), name: NotificationManager.Name.MeteorConnectionFailed.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorConnected), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorNetworkConnected), name: NotificationManager.Name.MeteorNetworkConnected.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(postAdded), name: NotificationManager.Name.NearbyPostAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(postRemoved), name: NotificationManager.Name.NearbyPostRemoved.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(postModified), name: NotificationManager.Name.NearbyPostModified.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(getNearby), name: NotificationManager.Name.NearbyPostsUpdated.rawValue, object: nil)
    }
    
    func connectionFailed(){
        self.loadingPosts = false
        self.loadingMorePosts = false
    }
    
    func postAdded(notification: NSNotification){
        if ConnectionHandler.Instance.isNetworkConnected(), let post = notification.object as? Post {
            if self.allPosts.indexOf({$0.id == post.id}) == nil {
                /*var posts = self.allPosts
                posts.append(post)
                posts = AccountHandler.Instance.sortNearbyPosts(posts)
                self.allPosts = posts
                self.refreshSearchResults()
                self.callRefreshDelegates()*/
                self.getNearby()
            }
        }
    }
    
    func postRemoved(notification: NSNotification){
        if ConnectionHandler.Instance.isNetworkConnected(), let postId = notification.object as? String, index =  self.allPosts.indexOf({$0.id == postId}){
            self.allPosts.removeAtIndex(index)
            self.refreshSearchResults()
            self.callRefreshDelegates()
        }
    }
    
    func postModified(notification: NSNotification){
        if ConnectionHandler.Instance.isNetworkConnected(), let post = notification.object as? Post, index =  self.allPosts.indexOf({$0.id == post.id}){
            self.allPosts.removeAtIndex(index)
            self.allPosts.insert(post, atIndex: index)
            self.refreshSearchResults()
            self.callRefreshDelegates()
        }
    }
    
    func accountUpdated(){
        if let currentLocation = self.currentLocation where AccountHandler.Instance.isLoggedIn() && ConnectionHandler.Instance.status == .Connected{
            //ConnectionHandler.Instance.reportLocation(currentLocation.latitude, lng: currentLocation.longitude, notify: false)
            AccountHandler.Instance.reportLocation(currentLocation.latitude, lng: currentLocation.longitude){ (success, _, _, _) in
                if success {
                    self.getNearby()
                }
            }
        }
    }
    
    func meteorNetworkConnected(){
        if self.locationAcquired {
            self.getNearby()
        }
    }
    
    @objc private func meteorConnected(notification: NSNotification){
        if self.locationAcquired {
            if AccountHandler.Instance.isLoggedIn() && ConnectionHandler.Instance.status == .Connected && !self.staleLocation{
                ThreadHelper.runOnBackgroundThread({
                    //ConnectionHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude, notify: false)
                    AccountHandler.Instance.reportLocation(self.currentLocation!.latitude, lng: self.currentLocation!.longitude)
                })
            }
        }
    }
    
    func showOfflineData(){
        if !self.meteorLoaded {
            if let posts = CachingHandler.Instance.postsAll {
                self.allPosts = posts
                
                if self.filtering{
                    self.searchBar(self.searchBar, textDidChange: (self.searchBar.text ?? ""))
                } else {
                    self.posts = self.allPosts
                }
                
                self.callRefreshDelegates()
            }
        }
    }
    
    func appDidBecomeActive(){
        self.loadingPosts = false
        self.loadingMorePosts = false
        self.locationHandler.getLocationOnce(false)
        if ConnectionHandler.Instance.isNetworkConnected() {
            self.getNearby()
            self.checkPending(false)
        }
    }
    
    func locationReported(geocoderInfo: GeocoderInfo) {
        if geocoderInfo.denied {
            self.errorMessage = NSLocalizedString("Please allow location services in settings", comment: "Alert denied, Please allow location services in settings")
            ThreadHelper.runOnMainThread {
                //self.tableView.reloadData()
                self.callRefreshDelegates()
            }
        } else if geocoderInfo.error {
            if self.staleLocation {
                self.errorMessage = NSLocalizedString("An error occurred getting your current location", comment: "Alert error, An error occurred getting your current location")
            
                ThreadHelper.runOnMainThread {
                    //self.tableView.reloadData()
                    self.callRefreshDelegates()
                }
            }
        } else {
            if self.currentLocation == nil || self.currentLocation?.latitude != geocoderInfo.coordinate?.latitude || self.currentLocation?.longitude != geocoderInfo.coordinate?.longitude || self.staleLocation{
                self.currentLocation = geocoderInfo.coordinate
                self.locationAcquired = true
                
                //self.subscribeToNearby()
                self.getNearby()
                self.staleLocation = false
                if AccountHandler.Instance.isLoggedIn() && ConnectionHandler.Instance.status == .Connected{
                    ThreadHelper.runOnBackgroundThread({
                        //ConnectionHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude, notify: false)
                        AccountHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude)
                    })
                }
                AccountHandler.Instance.subscribeToNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude)
            }
        }
    }
    
    /*private func subscribeToNearby(){
     AccountHandler.Instance.subscribeToNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude, radius: 100);
     }*/
    
    func getMore(){
        if ConnectionHandler.Instance.isNetworkConnected() && !self.loadingPosts, let currentLocation = self.currentLocation {
            self.loadingPosts = true
            self.loadingMorePosts = true
            self.callDisplayLoadingMore()
            AccountHandler.Instance.getNearbyPosts(currentLocation.latitude, lng: currentLocation.longitude, radius: 10000, skip: 0, take: self.allPosts.count + AccountHandler.NEARBY_POSTS_PAGE_SIZE + 1) { (success, errorId, errorMessage, result) in
                self.loadingPosts = false
                self.loadingMorePosts = false
                ThreadHelper.runOnMainThread({
                    if success {
                        self.errorMessage = nil
                        var posts = result as! [Post]
                        
                        if posts.count <= self.allPosts.count + AccountHandler.NEARBY_POSTS_PAGE_SIZE && posts.count != AccountHandler.NEARBY_POSTS_PAGE_SIZE{
                            self.noMorePosts = true
                        } else{
                            posts.removeLast()
                        }
                        self.allPosts = posts
                        
                        self.refreshSearchResults()
                    } else {
                        self.errorMessage = errorMessage
                        self.showAlert(NSLocalizedString("Error", comment: "Alert error, Error"), message: NSLocalizedString("Error updating posts", comment: "Alert message, Error updating posts"))
                        //self.tableView.reloadData()
                    }
                    self.callRefreshDelegates()
                })
            }
        }
    }
    
    func refreshSearchResults(){
        if self.filtering{
            self.searchBar(self.searchBar, textDidChange: (self.searchBar.text ?? ""))
        } else {
            self.posts = self.allPosts
        }
    }
    
    func refreshNearby(){
        self.getNearby(true)
    }
    
    func getNearby(refreshing: Bool = false){
        self.noMorePosts = false
        if ConnectionHandler.Instance.isNetworkConnected() && !self.loadingPosts, let currentLocation = self.currentLocation {
            self.loadingPosts = true
            var take = AccountHandler.NEARBY_POSTS_PAGE_SIZE + 1
            if refreshing {
                take = max(take, self.allPosts.count)
            }
            AccountHandler.Instance.getNearbyPosts(currentLocation.latitude, lng: currentLocation.longitude, radius: 10000, skip: 0, take: take) { (success, errorId, errorMessage, result) in
                self.loadingPosts = false
                ThreadHelper.runOnMainThread({
                    //self.refreshControl?.endRefreshing()
                    if success {
                        self.errorMessage = nil
                        self.allPosts = result as! [Post]
                        
                        if (self.allPosts.count <= AccountHandler.NEARBY_POSTS_PAGE_SIZE){
                            self.noMorePosts = true
                        } else {
                            self.allPosts.removeLast()
                        }
                        
                        self.refreshSearchResults()
                        
                        //self.tableView.reloadData()
                        self.callRefreshDelegates()
                        self.checkPending(true)
                    } else {
                        self.errorMessage = errorMessage
                        self.showAlert(NSLocalizedString("Error", comment: "Alert error, Error"), message: NSLocalizedString("Error updating posts", comment: "Alert message, Error updating posts"))
                        //self.tableView.reloadData()
                        self.callRefreshDelegates()
                    }
                    
                })
            }
        } else {
            //self.refreshControl?.endRefreshing()
        }
    }
    
    func callDisplayLoadingMore(){
        let viewController = viewControllerForSelectedSegmentIndex(self.typeSwitch.selectedSegmentIndex)
        (viewController as! PostsViewControllerDelegate).displayLoadingMore()
    }
    
    func callRefreshDelegates(){
        let viewController = viewControllerForSelectedSegmentIndex(self.typeSwitch.selectedSegmentIndex)
        (viewController as! PostsViewControllerDelegate).postsUpdated()
    }
    
    
    func displayPostDetails(index: Int){
        self.navigationController?.popToViewController(self, animated: false)
        let viewController = viewControllerForSelectedSegmentIndex(self.typeSwitch.selectedSegmentIndex)
        (viewController as! PostsViewControllerDelegate).showPostDetails(index)
    }
    
    func checkPending(stopAfter: Bool){
        if let pendingPostId = self.pendingPostId, postIndex = self.posts.indexOf({$0.id == pendingPostId}){
            self.navigationController?.popToViewController(self, animated: false)
            self.displayPostDetails(postIndex)
            //let indexPath = NSIndexPath(forRow: postIndex, inSection: 0)
            //self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
            //self.performSegueWithIdentifier("postDetails", sender: self)
            self.pendingPostId = nil
        }
        if stopAfter {
            self.pendingPostId = nil
        }
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        /*if let currentViewController = currentViewController {
            currentViewController.viewWillDisappear(animated)
        }*/
        if self.currentLocation != nil {
            self.locationHandler.stopMonitoringLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadCurrentViewController(index: Int) {
        if let vc = viewControllerForSelectedSegmentIndex(index) {
            self.addChildViewController(vc)
            
            vc.didMoveToParentViewController(self)
            
            vc.view.frame = self.contentView.bounds
            self.contentView.addSubview(vc.view)
            self.currentViewController = vc
            
            self.view.bringSubviewToFront(self.searchCriteriaView)
            
            (vc as! PostsViewControllerDelegate).postsUpdated()
        }
    }
    
    func viewControllerForSelectedSegmentIndex(index: Int) -> UIViewController? {
        var vc: UIViewController?
        let index = PostsViewType(rawValue: self.typeSwitch.selectedSegmentIndex)
        switch index! {
        case .list: vc = self.listViewController
        case .Map: vc = self.mapViewController
        }
        
        return vc
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    @IBAction func postsViewTypeChanged(sender: UISegmentedControl) {
        self.currentViewController!.view.removeFromSuperview()
        self.currentViewController!.removeFromParentViewController()
        loadCurrentViewController(sender.selectedSegmentIndex)
        if sender.selectedSegmentIndex == 0{
            AppAnalytics.logEvent(.NearbyPostsScreen_ListTabActive)
        } else {
            AppAnalytics.logEvent(.NearbyPostsScreen_MapTabActive)
        }
    }
    
    @IBAction func btnSearch_Click(sender: AnyObject) {
        AppAnalytics.logEvent(.NearbyPostsScreen_BtnSearch_Click)
        self.filtering = true
        if (self.typeSwitch.selectedSegmentIndex != 0){
            self.typeSwitch.selectedSegmentIndex = 0
            self.postsViewTypeChanged(self.typeSwitch)
        }
        self.listViewController.updateFiltering(true)
        self.searchBar.alpha = 0
        //self.searchBar.tintColor =
        self.navigationItem.setRightBarButtonItem(nil, animated: true)
        self.navigationItem.setLeftBarButtonItem(nil, animated: true)
        UIView.animateWithDuration(0.1, animations: {
            self.typeSwitch.alpha = 0
            }) { (finished) in
                self.navigationItem.titleView = self.searchBar
                UIView.animateWithDuration(0.1, animations: { 
                    self.searchBar.alpha = 1
                }, completion: { (finishedLast) in
                    self.searchBar.becomeFirstResponder()
                })
        }
        
        UIView.animateWithDuration(0.2, animations: {
            self.searchCriteriaView.frame.origin.y += self.searchToolbarHeight
            self.listViewController.tableView.frame.origin.y += self.searchToolbarHeight
        })
        
        if let searchText = self.searchBar.text where searchText != ""{
            self.searchBar(self.searchBar, textDidChange: searchText)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        AppAnalytics.logEvent(.NearbyPostsScreen_Search_Cancel)
        self.filtering =  false
        self.listViewController.updateFiltering(false)
        self.navigationItem.setRightBarButtonItem(self.btnSearch, animated: true)
        self.navigationItem.setLeftBarButtonItem(self.btnAddPost, animated: true)
        self.typeSwitch.alpha = 0
        
        UIView.animateWithDuration(0.2) {
            self.navigationItem.titleView = self.typeSwitch
            self.typeSwitch.alpha = 1
            
            self.searchCriteriaView.frame.origin.y -= self.searchToolbarHeight
            self.listViewController.tableView.frame.origin.y -= self.searchToolbarHeight
        }
        
        self.posts = self.allPosts
        self.listViewController.tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let searchTextLowered = searchText.lowercaseString
        if searchTextLowered != ""{
            self.posts = self.allPosts.filter({$0.title!.lowercaseString.containsString(searchTextLowered) || ($0.descr ?? "").lowercaseString.containsString(searchTextLowered)})
        } else {
            self.posts = self.allPosts
        }
        self.listViewController.tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "nearbyPosts_CreatePost"{
            AppAnalytics.logEvent(.NearbyPostsScreen_BtnNewPost_Click)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "searchSegue"){
            self.searchViewController = segue.destinationViewController as? NewSearchViewController
            self.searchViewController?.delegate = self
        }
    }*/
    

}
