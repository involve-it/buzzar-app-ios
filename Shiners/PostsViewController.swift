//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit
import CoreLocation

class PostsViewController: UITableViewController, SearchViewControllerDelegate, LocationHandlerDelegate{
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "postDetails"){
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = posts[index];
            vc.post = post;
        } else if (segue.identifier == "searchSegue"){
            self.searchViewController = segue.destinationViewController as? NewSearchViewController
            self.searchViewController?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        self.locationHandler.delegate = self
        self.searchView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showPostsFromCollection), name: NotificationManager.Name.NearbyPostsSubscribed.rawValue, object: nil)
        
        self.locationHandler.getLocationOnce()
        
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
    }
    
    func showPostsFromCollection(){
        self.meteorLoaded = true
        self.posts = ConnectionHandler.Instance.posts.postsCollection.posts
        self.tableView.separatorStyle = .SingleLine;
        ThreadHelper.runOnMainThread {
            self.tableView.reloadData()
        }
    }
    
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
                self.subscribeToNearby()
            }
        }
    }
    
    private func subscribeToNearby(){
        ConnectionHandler.Instance.posts.subscribeToNearbyPosts(self.currentLocation!.latitude, lng: self.currentLocation!.longitude, radius: 100);
    }
    
    @objc private func meteorConnected(notification: NSNotification){
        if self.locationAcquired {
            self.subscribeToNearby()
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
            }
            if loading {
                postCell.imgPhoto?.image = ImageCachingHandler.defaultImage;
            }
            cell = postCell
        }
        
        return cell;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, posts.count);
    }
    
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
