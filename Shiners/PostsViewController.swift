//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit
import CoreLocation

class PostsViewController: UITableViewController, UIViewControllerPreviewingDelegate, SearchViewControllerDelegate, PostsViewControllerDelegate{
    
    @IBOutlet weak var lcTxtSearchBoxLeft: NSLayoutConstraint!
    @IBOutlet var segmFilter: UISegmentedControl!
    @IBOutlet weak var txtSearchBox: UITextField!
    @IBOutlet var searchView: UIView!
    
    var currentUser: User?
    
    var searchViewController: NewSearchViewController?
    
    internal weak var mainViewController: PostsMainViewController!
    
    func updateFiltering(filtering: Bool){
        if (filtering){
            self.refreshControl = nil
        } else {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.addTarget(self, action: #selector(getNearby), forControlEvents: .ValueChanged)
        }
    }
    
    func showPostDetails(index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
        self.performSegueWithIdentifier("postDetails", sender: self)
    }
    
    func postsUpdated() {
        ThreadHelper.runOnMainThread {
            if (self.mainViewController.posts.count == 0){
                //self.tableView.scrollEnabled = false;
                self.tableView.separatorStyle = .None;
            } else {
                //self.tableView.scrollEnabled = true;
                self.tableView.separatorStyle = .SingleLine;
            }
            
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "postDetails"){
            self.mainViewController.searchBar.endEditing(true)
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = self.mainViewController.posts[index];
            
            if let currentLocation = self.mainViewController.currentLocation {
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set background collor to default value
        self.navigationController?.navigationBar.barTintColor = UIColor(white: 249/255, alpha: 1)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.translucent = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainViewController = self.parentViewController as! PostsMainViewController
        
        if (self.mainViewController.posts.count == 0){
            //self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .None;
        } else {
            //self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .SingleLine;
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(getNearby), forControlEvents: .ValueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func getNearby(){
        self.mainViewController.getNearby();
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("postDetails") as? PostDetailsViewController
        
        let post = self.mainViewController.posts[indexPath.row];
        viewController?.post = post
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.showViewController(viewControllerToCommit, sender: self)
    }
    
    func forceLayout(){
        self.searchView.frame = self.view.bounds;
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        //self.view.layoutIfNeeded()
        self.view.layoutSubviews()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if self.mainViewController.posts.count == 0 {
            if (self.mainViewController.errorMessage != nil || (self.mainViewController.meteorLoaded && self.self.mainViewController.locationAcquired)){
                let errorCell = tableView.dequeueReusableCellWithIdentifier("postsError") as! ErrorCell
                errorCell.lblMessage.text = self.mainViewController.errorMessage ?? NSLocalizedString("There are no posts around you", comment: "There are no posts around you")
                cell = errorCell
            } else if self.mainViewController.filtering{
                let errorCell = tableView.dequeueReusableCellWithIdentifier("postsError") as! ErrorCell
                errorCell.lblMessage.text = self.mainViewController.errorMessage ?? NSLocalizedString("Can't find any posts matching your search criteria", comment: "Can't find any posts matching your search criteria")
                cell = errorCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("waitingPosts")
            }
        } else {
            let postCell: PostsTableViewCell = tableView.dequeueReusableCellWithIdentifier("post") as! PostsTableViewCell;
            let post: Post = self.mainViewController.posts[indexPath.row];
            
            //Post title
            postCell.txtTitle.text = post.title;
            
            //Post description
            if let textDescription = post.removedHtmlFromPostDescription(post.descr) {
                postCell.txtDetails.text = textDescription
            } else {
                postCell.txtDetails.text = ""
            }
            
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
            if let currentLocation = self.mainViewController.currentLocation {
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
        return max(1, self.mainViewController.posts.count);
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
    }
    
    
    // MARK: action
    @IBAction func btnSearchClick(sender: AnyObject) {
        
        if (self.segmFilter.alpha == 0){
            self.closeSearchView()
        } else {
            self.openSearchView()
        }
        
    }
    
    @IBAction func unwindPosts(segue: UIStoryboardSegue){}
    
    
    
}
//
//
//// MARK: extension
//extension UIViewController: SWRevealViewControllerDelegate {
//    
//    /*public func configureOfLeftMenu() {
//        if self.revealViewController() != nil {
//            
//            self.revealViewController().delegate = self
//            
//            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
//            self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
//            
//            //Defines a width on the border of the view attached to the panGesturRecognizer where the gesture is allowed
//            self.revealViewController().draggableBorderWidth = CGFloat(80.0)
//            
//            self.revealViewController().rearViewRevealWidth = self.view.frame.width - 60
//            
//            
//        }
//    }
//    
//    public func addLeftBarButtonWithImage(buttonImage: UIImage) {
//        let leftButton: UIBarButtonItem = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.Plain, target: self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)))
//        
//        if navigationItem.leftBarButtonItems?.count > 0 {
//            navigationItem.leftBarButtonItems?.insert(leftButton, atIndex: 0)
//        } else {
//            navigationItem.leftBarButtonItem = leftButton
//        }
//        
//    }*/
//    
//    public func removeNavigationBarItem() {
//        self.navigationItem.leftBarButtonItem = nil
//        self.navigationItem.rightBarButtonItem = nil
//    }
//    
//    // MARK: - SWRevealViewController delegare
//    /*public func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
//        //print("position: \(position.hashValue)")
//        if position == .Right {
//            //print("menu will open")
//        } else {
//            //print("menu did close")
//        }
//
//    }
//    
//    public func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
//        //print("didMove")
//    }*/
//    
//}
//
//






