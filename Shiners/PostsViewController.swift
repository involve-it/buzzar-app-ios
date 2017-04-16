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
    
    func updateFiltering(_ filtering: Bool){
        if (filtering){
            self.refreshControl = nil
        } else {
            self.refreshControl = UIRefreshControl()
            self.refreshControl?.addTarget(self, action: #selector(getNearby), for: .valueChanged)
        }
    }
    
    func showPostDetails(_ index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        self.performSegue(withIdentifier: "postDetails", sender: self)
    }
    
    func postsUpdated(posts: [Post], currentLocation: CLLocationCoordinate2D?) {
        ThreadHelper.runOnMainThread {
            if (self.mainViewController.posts.count == 0){
                //self.tableView.scrollEnabled = false;
                self.tableView.separatorStyle = .none;
            } else {
                //self.tableView.scrollEnabled = true;
                self.tableView.separatorStyle = .singleLine;
            }
            
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "postDetails"){
            AppAnalytics.logEvent(.NearbyPostsScreen_List_PostSelected)
            self.mainViewController.searchBar.endEditing(true)
            let vc:PostDetailsViewController = segue.destination as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = self.mainViewController.posts[index];
            
            if let currentLocation = self.mainViewController.currentLocation {
                //current location
                let curLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                post.outDistancePost = post.getDistanceFormatted(curLocation)
            }
            
            vc.post = post;
            
            
            vc.pendingCommentsAsyncId = CommentsHandler.Instance.getCommentsAsync(post.id!, skip: 0)
            if ConnectionHandler.Instance.isNetworkConnected(){
                vc.subscriptionId = AccountHandler.Instance.subscribeToCommentsForPost(post.id!)
            }
            
        } else if (segue.identifier == "searchSegue"){
            self.searchViewController = segue.destination as? NewSearchViewController
            self.searchViewController?.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.NearbyPosts_List)
        //Set background collor to default value
        self.navigationController?.navigationBar.barTintColor = UIColor(white: 249/255, alpha: 1)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.refreshControl?.endRefreshing()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainViewController = self.parent as! PostsMainViewController
        
        if (self.mainViewController.posts.count == 0){
            //self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .none;
        } else {
            //self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .singleLine;
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(forceLayout), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(getNearby), for: .valueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            self.registerForPreviewing(with: self, sourceView: view)
        }
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func getNearby(){
        AppAnalytics.logEvent(.NearbyPostsScreen_List_GetMore)
        self.mainViewController.getNearby();
    }
    
    func appDidBecomeActive(){
        self.refreshControl?.endRefreshing()
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else {return nil}
        guard let cell = self.tableView.cellForRow(at: indexPath) else {return nil}
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "postDetails") as? PostDetailsViewController
        
        let post = self.mainViewController.posts[indexPath.row];
        viewController?.post = post
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.show(viewControllerToCommit, sender: self)
    }
    
    func forceLayout(){
        self.searchView.frame = self.view.bounds;
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        //self.view.layoutIfNeeded()
        self.view.layoutSubviews()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if self.mainViewController.posts.count == 0 {
            if (self.mainViewController.errorMessage != nil || (self.mainViewController.meteorLoaded && self.self.mainViewController.locationAcquired)){
                let errorCell = tableView.dequeueReusableCell(withIdentifier: "postsError") as! ErrorCell
                errorCell.lblMessage.text = self.mainViewController.errorMessage ?? NSLocalizedString("There are no posts around you", comment: "There are no posts around you")
                cell = errorCell
            } else if self.mainViewController.filtering{
                let errorCell = tableView.dequeueReusableCell(withIdentifier: "postsError") as! ErrorCell
                if let _ = self.mainViewController.searchTimer {
                    errorCell.lblMessage.text = NSLocalizedString("Searching...", comment: "Searching...")
                } else {
                    errorCell.lblMessage.text = self.mainViewController.errorMessage ?? NSLocalizedString("Can't find any posts matching your search criteria", comment: "Can't find any posts matching your search criteria")
                }
                cell = errorCell
            } else if self.mainViewController.loadingPosts {
                cell = tableView.dequeueReusableCell(withIdentifier: "waitingPosts")
            } else {
                let errorCell = tableView.dequeueReusableCell(withIdentifier: "postsError") as! ErrorCell
                errorCell.lblMessage.text =  NSLocalizedString("There are no posts around you", comment: "There are no posts around you")
                cell = errorCell
            }
        } else if indexPath.row == self.mainViewController.posts.count && self.mainViewController.loadingMorePosts{
            cell = tableView.dequeueReusableCell(withIdentifier: "morePosts")
        } else {
            let postCell: PostsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "post") as! PostsTableViewCell;
            let post: Post = self.mainViewController.posts[indexPath.row];
            
            //Post title
            postCell.txtTitle.text = post.title;
            
            //Post description
            if let textDescription = post.removedHtmlFromPostDescription(post.descr) {
                postCell.txtDetails.text = textDescription
            } else {
                postCell.txtDetails.text = ""
            }
            
            //Post category
            if let category = post.type?.rawValue {
                postCell.categoryViewOfPost.isHidden = false
                postCell.imgSeparatorOfCategory.isHidden = false
                postCell.categoryViewOfPost.layer.cornerRadius = 2.0
                postCell.categoryOfPost.text = category
                
                switch category {
                case "connect": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0xFA5F56)
                case "trade": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0x9B9C9C)
                case "jobs": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0x76C9E8)
                case "trainings": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0xD08BBC)
                case "housing": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0xBDCE3A)
                case "events": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0xEB7434)
                case "services": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0xA7D1AE)
                case "help": postCell.categoryViewOfPost.backgroundColor = UIColor(netHex: 0x5DA293)
                default:
                    break
                }
                
            } else {
                postCell.categoryViewOfPost.isHidden = true
                postCell.imgSeparatorOfCategory.isHidden = true
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
            } else {
                postCell.txtPostDistance.text = "..."
            }
            
            if let price = post.price, post.price != "" {
                postCell.txtPrice.text = "$\(price)";
            } else {
                postCell.txtPrice.text = "";
            }
            var loading = false
            if let url = post.getMainPhoto()?.original {
                loading = ImageCachingHandler.Instance.getImageFromUrl(url) { (image) in
                    DispatchQueue.main.async(execute: {
                        if let cellToUpdate = tableView.cellForRow(at: indexPath) as? PostsTableViewCell{
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == self.mainViewController.posts.count && self.mainViewController.loadingMorePosts {
            return 44
        } else {
            return 92
        }
    }
    
    func displayLoadingMore() {
        ThreadHelper.runOnMainThread {
            if self.tableView(self.tableView, numberOfRowsInSection: 0) == self.mainViewController.posts.count {
                self.tableView.insertRows(at: [IndexPath(row: self.mainViewController.posts.count, section: 0)], with: .automatic)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = max(1, self.mainViewController.posts.count);
        if self.mainViewController.loadingMorePosts && self.mainViewController.posts.count != 0 {
            count += 1
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !self.mainViewController.filtering && indexPath.row >= self.mainViewController.posts.count - Int(AccountHandler.NEARBY_POSTS_PAGE_SIZE / 3) && !self.mainViewController.noMorePosts && !self.mainViewController.loadingPosts && self.mainViewController.allPosts.count >= AccountHandler.NEARBY_POSTS_PAGE_SIZE {
            self.mainViewController.getMore()
        }
    }
    
    func didApplyFilter() {
        self.closeSearchView()
    }
    
    func closeSearchView(){
        self.txtSearchBox.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
           // self.segmFilter.alpha = 1
            self.txtSearchBox.alpha = 0
            self.searchView.alpha = 0
        }, completion: { (_) in
            self.searchView.removeFromSuperview()
            self.tableView.isScrollEnabled = true
        }) 
    }
    
    func openSearchView(){
        self.searchView.frame = self.view.bounds;
        self.tableView.isScrollEnabled = false
        
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        self.searchView.alpha = 0
        self.view.addSubview(self.searchView)
        
        self.txtSearchBox.becomeFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
            //self.segmFilter.alpha = 0
            self.txtSearchBox.alpha = 1
            self.searchView.alpha = 1
            
        }, completion: { (_) in
            
        }) 
    }
    
    
    // MARK: action
    @IBAction func btnSearchClick(_ sender: AnyObject) {
        
        if (self.segmFilter.alpha == 0){
            self.closeSearchView()
        } else {
            self.openSearchView()
        }
        
    }
    
    @IBAction func unwindPosts(_ segue: UIStoryboardSegue){
        print("unwind")
    }
}








