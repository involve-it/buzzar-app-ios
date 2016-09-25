//
//  PostsViewControllerBase.swift
//  Shiners
//
//  Created by Yury Dorofeev on 9/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class PostsViewControllerBase: UIViewController, LocationHandlerDelegate{
    var posts = [Post]()
    let locationHandler = LocationHandler()
    private var locationAcquired = false
    var currentLocation: CLLocationCoordinate2D?
    private var errorMessage: String?
    var pendingPostId: String?
    private var meteorLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Posts"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        self.locationHandler.delegate = self
        //self.searchView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showPostsFromCollection), name: NotificationManager.Name.NearbyPostsSubscribed.rawValue, object: nil)
        
        self.locationHandler.getLocationOnce(false)
        
        if ConnectionHandler.Instance.status == .Connected{
            self.getNearby()
        } else if CachingHandler.Instance.status != .Complete {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
        } else if let posts = CachingHandler.Instance.postsAll {
            self.posts = posts
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(meteorConnected), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
    }
    
    @objc private func meteorConnected(notification: NSNotification){
        if self.locationAcquired {
            //self.subscribeToNearby()
            self.getNearby()
        }
    }
    
    func refreshView(){
        
    }
    
    func showOfflineData(){
        if !self.meteorLoaded {
            if let posts = CachingHandler.Instance.postsAll {
                self.posts = posts
                self.refreshView()
            }
        }
    }
    
    func appDidBecomeActive(){
        if self.posts.count > 0 && AccountHandler.Instance.status == .Completed{
            self.getNearby()
            self.checkPending(false)
        }
    }
    
    func locationReported(geocoderInfo: GeocoderInfo) {
        if geocoderInfo.denied {
            self.errorMessage = NSLocalizedString("Please allow location services in settings", comment: "Alert denied, Please allow location services in settings")
            ThreadHelper.runOnMainThread {
                //self.tableView.reloadData()
                self.refreshView()
            }
        } else if geocoderInfo.error {
            self.errorMessage = NSLocalizedString("An error occurred getting your current location", comment: "Alert error, An error occurred getting your current location")
            ThreadHelper.runOnMainThread {
                //self.tableView.reloadData()
                self.refreshView()
            }
        } else {
            self.currentLocation = geocoderInfo.coordinate
            self.locationAcquired = true
            
            //self.subscribeToNearby()
            self.getNearby()
            ThreadHelper.runOnBackgroundThread({
                ConnectionHandler.Instance.reportLocation(geocoderInfo.coordinate!.latitude, lng: geocoderInfo.coordinate!.longitude, notify: false)
            })
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
                        self.refreshView()
                        self.checkPending(true)
                    } else {
                        self.errorMessage = errorMessage
                        self.showAlert(NSLocalizedString("Error", comment: "Alert error, Error"), message: NSLocalizedString("Error updating posts", comment: "Alert message, Error updating posts"))
                        //self.tableView.reloadData()
                        self.refreshView()
                    }
                    
                })
            }
        } else {
            //self.refreshControl?.endRefreshing()
        }
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
    
    func displayPostDetails(index: Int){
    
    }
}