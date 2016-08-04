//
//  MyPostsViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class MyPostsViewController: UITableViewController, UIViewControllerPreviewingDelegate{
    var myPosts = [Post]()
    
    var meteorLoaded = false
    var pendingPostId: String?
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(myPostsUpdated), name: NotificationManager.Name.MyPostsUpdated.rawValue, object: nil)
        self.myPosts = [Post]()
        if AccountHandler.Instance.status == .Completed {
            self.meteorLoaded = true
            if let myPosts = AccountHandler.Instance.myPosts{
                self.myPosts = myPosts
            } else {
                self.myPosts = [Post]()
            }
        } else {
            if CachingHandler.Instance.status != .Complete {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
            } else if let posts = CachingHandler.Instance.postsMy {
                self.myPosts = posts
            }
        }
        
        if (myPosts.count == 0){
            self.tableView.separatorStyle = .None;
        } else {
            self.tableView.separatorStyle = .SingleLine;
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateMyPosts), forControlEvents: .ValueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) else {return nil}
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("postDetails") as? PostDetailsViewController
        
        let post = myPosts[indexPath.row];
        viewController?.post = post
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.showViewController(viewControllerToCommit, sender: self)
    }
    
    /*public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.checkPending()
    }*/
    
    func appDidBecomeActive(){
        if self.myPosts.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending()
        }
    }
    
    @IBAction func unwindMyPosts(segue: UIStoryboardSegue){
        
    }
    
    @IBAction func btnEdit_Click(sender: AnyObject) {
        self.tableView.setEditing(true, animated: true)
    }
    
    func checkPending(){
        if let pendingPostId = self.pendingPostId, postIndex = self.myPosts.indexOf({$0.id == pendingPostId}){
            self.navigationController?.popToViewController(self, animated: false)
            let indexPath = NSIndexPath(forRow: postIndex, inSection: 0)
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
            self.performSegueWithIdentifier("myPostDetails", sender: self)
        }
        self.pendingPostId = nil
    }
    
    func showOfflineData(){
        if !self.meteorLoaded{
            if let posts = CachingHandler.Instance.postsMy{
                self.myPosts = posts
                ThreadHelper.runOnMainThread {
                    self.tableView.separatorStyle = .SingleLine;
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.myPosts.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending()
        }
    }
    
    func updateMyPosts(){
        AccountHandler.Instance.updateMyPosts { (success, errorId, errorMessage, result) in
            self.myPostsUpdated();
        }
    }
    
    func myPostsUpdated(){
        self.meteorLoaded = true
        if let myPosts = AccountHandler.Instance.myPosts{
            self.myPosts = myPosts
        } else {
            self.myPosts = [Post]()
        }
        ThreadHelper.runOnMainThread {
            self.refreshControl?.endRefreshing()
            self.tableView.separatorStyle = .SingleLine;
            self.tableView.reloadData()
            
            self.checkPending()
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, myPosts.count);
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (myPosts.count == 0){
            if ConnectionHandler.Instance.status == .Connected{
                return tableView.dequeueReusableCellWithIdentifier("noPosts")!
            } else {
                return tableView.dequeueReusableCellWithIdentifier("waitingPosts")!
            }
        }
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("post") as! PostsTableViewCell
        let post: Post = self.myPosts[indexPath.row];
        
        cell.txtTitle.text = post.title;
        cell.txtDetails.text = post.descr;
        
        //Post views
        if let txtViewCountPost = post.seenTotal {
            cell.txtViewCountPost.text = String(txtViewCountPost)
        } else {
            cell.txtViewCountPost.text = "0"
        }
        
        //Post type location
        if let locations = post.locations {
            for location in locations {
                if location.placeType! == .Dynamic {
                    //Post Dynamic
                    let typeImage = (post.isLive()) ? "PostCell_Dynamic_Live" : "PostCell_Dynamic"
                    cell.imgPostTypeLocation.image = UIImage(named: typeImage)
                    break
                } else {
                    //Post Static
                    let typeImage = (post.isLive()) ? "PostCell_Static_Live" : "PostCell_Static"
                    cell.imgPostTypeLocation.image = UIImage(named: typeImage)
                }
            }
        }
        
        //Post expires
        cell.txtExpiresPostCount.text = post.endDate?.toLeftExpiresDatePost()
        
        if let price = post.price where post.price != "" {
            cell.txtPrice.text = "$\(price)";
        } else {
            cell.txtPrice.text = "";
        }
        var loading = false;
        if let url = post.getMainPhoto()?.original {
            loading = ImageCachingHandler.Instance.getImageFromUrl(url) { (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? PostsTableViewCell{
                        cellToUpdate.imgPhoto?.image = image;
                    }
                })
            }
        } else {
            cell.imgPhoto.image = ImageCachingHandler.defaultPhoto;
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultPhoto;
        }
        
        return cell
    }
    
    public override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return !self.tableView.editing
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "myPostDetails"){
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = myPosts[index];
            vc.isOwnPost = true
            vc.post = post;
        }
    }
   
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var actions = [UITableViewRowAction]()
        
        let post = self.myPosts[indexPath.row]
        let title = (post.visible ?? false) ? "Hide" : "Show"
        
        var button = UITableViewRowAction(style: .Normal, title: title) { (action, indexPath) in
            print(title)
            let post = self.myPosts[indexPath.row]
            post.visible = !(post.visible ?? false)
            self.tableView.editing = false
            ConnectionHandler.Instance.posts.editPost(post, callback: { (success, errorId, errorMessage, result) in
                if success {
                    self.tableView.rectForRowAtIndexPath(indexPath)
                } else {
                    self.showAlert("Error", message: errorMessage)
                }
            })
        }
        
        actions.append(button)
        
        button = UITableViewRowAction(style: .Destructive, title: "Delete") { (action, indexPath) in
            print("delete")
            //self.tableView.editing = false
            let post = self.myPosts[indexPath.row]
            ConnectionHandler.Instance.posts.deletePost(post.id!) { success, errorId, errorMessage, result in
                if success {
                    self.myPosts.removeAtIndex(self.myPosts.indexOf({ (p) -> Bool in
                        return p.id == post.id
                    })!)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    
                    //AccountHandler.Instance.updateMyPosts()
                    
                } else {
                    self.showAlert("Error", message: errorMessage)
                }
            }
        }
        
        actions.append(button)
        
        return actions
    }
}
