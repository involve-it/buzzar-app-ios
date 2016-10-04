//
//  BeginnerViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import CoreLocation

class PostsMainViewController: UIViewController, LocationHandlerDelegate {
    let locationHandler = LocationHandler()
    
    var posts = [Post]()
    var currentLocation: CLLocationCoordinate2D?
    var pendingPostId: String?
    
    @IBOutlet weak var btnAddPost: UIBarButtonItem!
    var locationAcquired = false
    var errorMessage: String?
    var meteorLoaded = false
    
    @IBOutlet weak var typeSwitch: UISegmentedControl!
    @IBOutlet var contentView: UIView!
    
    var searchViewController: NewSearchViewController?
    var currentViewController: UIViewController?
    
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    //Identifier postStyle
    private var listInitialized = false
    private var mapInitialized = false
    
    lazy var listViewController: UIViewController? = {
        let list = self.storyBoard.instantiateViewControllerWithIdentifier("postsViewController")
        self.listInitialized = true
        return list
    }()
    //Identifier mapStyle
    lazy var mapViewController: UIViewController? = {
        let map = self.storyBoard.instantiateViewControllerWithIdentifier("mapViewControllerForPosts")
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
        
        if AccountHandler.Instance.isLoggedIn(){
            self.navigationItem.leftBarButtonItem = self.btnAddPost
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.posts.count > 0 && ConnectionHandler.Instance.status == .Connected{
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
        
        if ConnectionHandler.Instance.status == .Connected{
            self.getNearby()
        } else if CachingHandler.Instance.status != .Complete {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
        } else if let posts = CachingHandler.Instance.postsAll {
            self.posts = posts
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorConnected), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
    }
    
    func accountUpdated(){
        if let currentLocation = self.currentLocation where AccountHandler.Instance.isLoggedIn(){
            //ConnectionHandler.Instance.reportLocation(currentLocation.latitude, lng: currentLocation.longitude, notify: false)
            AccountHandler.Instance.reportLocation(currentLocation.latitude, lng: currentLocation.longitude)
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
                self.callRefreshDelegates()
            }
        }
    }
    
    func appDidBecomeActive(){
        if ConnectionHandler.Instance.status == .Connected{
            self.getNearby()
            self.checkPending(false)
            self.locationHandler.getLocationOnce(false)
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
            self.errorMessage = NSLocalizedString("An error occurred getting your current location", comment: "Alert error, An error occurred getting your current location")
            ThreadHelper.runOnMainThread {
                //self.tableView.reloadData()
                self.callRefreshDelegates()
            }
        } else {
            self.currentLocation = geocoderInfo.coordinate
            self.locationAcquired = true
            
            //self.subscribeToNearby()
            self.getNearby()
            if AccountHandler.Instance.isLoggedIn(){
                ThreadHelper.runOnBackgroundThread({
                    //ConnectionHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude, notify: false)
                    AccountHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude)
                })
            }
        }
    }
    
    /*private func subscribeToNearby(){
     AccountHandler.Instance.subscribeToNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude, radius: 100);
     }*/
    
    func getNearby(){
        if ConnectionHandler.Instance.status == .Connected, let currentLocation = self.currentLocation {
            AccountHandler.Instance.getNearbyPosts(currentLocation.latitude, lng: currentLocation.longitude, radius: 100000) { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({
                    //self.refreshControl?.endRefreshing()
                    if success {
                        self.errorMessage = nil
                        self.posts = result as! [Post]
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
        self.locationHandler.stopMonitoringLocation()
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
    
    /*func closeSearchView(){
        self.txtSearchBox.resignFirstResponder()
        UIView.animateWithDuration(0.25, animations: {
            // self.segmFilter.alpha = 1
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
        UIView.animateWithDuration(0.25, animations: {
            //self.segmFilter.alpha = 0
            self.txtSearchBox.alpha = 1
            self.searchView.alpha = 1
            
        }) { (_) in
            
        }
    }*/
    
    @IBAction func postsViewTypeChanged(sender: UISegmentedControl) {
        self.currentViewController!.view.removeFromSuperview()
        self.currentViewController!.removeFromParentViewController()
        loadCurrentViewController(sender.selectedSegmentIndex)
    }
    
    @IBAction func btnSearchPosts(sender: UIBarButtonItem) {
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
