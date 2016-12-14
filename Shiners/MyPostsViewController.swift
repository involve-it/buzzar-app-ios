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
    
    @IBOutlet var btnAdd: UIBarButtonItem!
    var btnDelete: UIBarButtonItem!
    
    func deletePosts(){
        AppAnalytics.logEvent(.MyPostsScreen_BtnDelete_Clicked)
        if let indexPaths = self.tableView.indexPathsForSelectedRows {
            let count = indexPaths.count
            if count > 0 {
                let alertController = UIAlertController(title: NSLocalizedString("Delete Posts", comment: "Delete Posts"), message: NSLocalizedString("Are you sure you want to delete selected post(s)?", comment: "Alert message, Are you sure you want to delete selected posts?"), preferredStyle: .ActionSheet);
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .Destructive, handler: { (action) in
                    //self.showAlert("Deleted", message: "Deleted")
                    var processedCount = 0
                    var successfulIndexPaths = [NSIndexPath]()
                    indexPaths.forEach({ (indexPath) in
                        self.deletePost(indexPath, callback: { (success) in
                            processedCount += 1
                            if success {
                                successfulIndexPaths.append(indexPath)
                            }
                            self.endEditIfDone(count, processedCount: processedCount, allIndexPaths: successfulIndexPaths)
                        })
                    })
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil));
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func endEditIfDone(count: Int, processedCount: Int, allIndexPaths: [NSIndexPath]){
        if count == processedCount {
            if self.tableView.editing {
                ThreadHelper.runOnMainThread({ 
                    self.editAction(self.editButtonItem())
                })
            }
            ThreadHelper.runOnMainThread({
                if self.myPosts.count == 0{
                    let allExceptFirst = allIndexPaths.filter({$0.row != 0})
                    self.tableView.deleteRowsAtIndexPaths(allExceptFirst, withRowAnimation: .None)
                    self.tableView.reloadData()
                } else {
                    self.tableView.deleteRowsAtIndexPaths(allIndexPaths, withRowAnimation: .Automatic)
                }
            })
            AccountHandler.Instance.updateMyPosts()
        }
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(myPostsUpdated), name: NotificationManager.Name.MyPostsUpdated.rawValue, object: nil)
        self.btnDelete = UIBarButtonItem(title: NSLocalizedString("Delete", comment: "Delete"), style: UIBarButtonItemStyle.Done, target: self, action: #selector(deletePosts))
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
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.editButtonItem().action = #selector(editAction)
        
        if self.myPosts.count > 0{
            self.editButtonItem().enabled = true
        } else {
            self.editButtonItem().enabled = false
        }
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func editAction(sender: UIBarButtonItem){
        AppAnalytics.logEvent(.MyPostsScreen_BtnEdit_Click)
        if self.tableView.editing{
            self.tableView.setEditing(false, animated: true)
            self.parentViewController!.navigationItem.rightBarButtonItem = (self.parentViewController as! ProfileMainViewController).btnAdd
            
            sender.title = NSLocalizedString("Edit", comment: "Edit")
        } else {
            self.tableView.setEditing(true, animated: true)
            self.parentViewController!.navigationItem.rightBarButtonItem = self.btnDelete
            sender.title = NSLocalizedString("Done", comment: "Done")
        }
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
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.checkPending()
        self.refreshControl?.endRefreshing()
    }
    
    func appDidBecomeActive(){
        if self.myPosts.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending()
        }
        self.refreshControl?.endRefreshing()
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
            if self.myPosts.count > 0{
                self.editButtonItem().enabled = true
            } else {
                self.editButtonItem().enabled = false
            }
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
            if self.meteorLoaded
            {
                return tableView.dequeueReusableCellWithIdentifier("noPosts")!
            } else {
                return tableView.dequeueReusableCellWithIdentifier("waitingPosts")!
            }
        }
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("post") as! PostsTableViewCell
        let post: Post = self.myPosts[indexPath.row];
        
        cell.txtTitle.text = post.title;
        
        if let textDescription = post.removedHtmlFromPostDescription(post.descr) {
            cell.txtDetails.text = textDescription
        } else {
            cell.txtDetails.text = ""
        }
    
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
            AppAnalytics.logEvent(.MyPostsScreen_PostSelected)
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = myPosts[index];
            vc.isOwnPost = true
            vc.post = post;
            vc.pendingCommentsAsyncId = CommentsHandler.Instance.getCommentsAsync(post.id!, skip: 0)
        } else if segue.identifier == "myPosts_CreatePost"{
            AppAnalytics.logEvent(.MyPostsScreen_BtnNewPost_Click)
        }
    }
   
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func deletePost(indexPath: NSIndexPath, callback: ((success: Bool) -> Void)? = nil) {
        let post = self.myPosts[indexPath.row]
        ConnectionHandler.Instance.posts.deletePost(post.id!) { success, errorId, errorMessage, result in
            if success {
                NotificationManager.sendNotification(.NearbyPostRemoved, object: post.id)
                self.myPosts.removeAtIndex(self.myPosts.indexOf({ (p) -> Bool in
                    return p.id == post.id
                })!)
            } else {
                self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
            }
            callback?(success: success)
        }
    }
    
    public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var actions = [UITableViewRowAction]()
        
        let post = self.myPosts[indexPath.row]
        let title = (post.visible ?? false) ? NSLocalizedString("Hide", comment: "Title, Hide") : NSLocalizedString("Show", comment: "Title, Show")
        
        var button = UITableViewRowAction(style: .Normal, title: title) { (action, indexPath) in
            AppAnalytics.logEvent(.MyPostsScreen_SlideHide_Clicked)
            print(title)
            let post = self.myPosts[indexPath.row]
            post.visible = !(post.visible ?? false)
            self.tableView.editing = false
            ConnectionHandler.Instance.posts.editPost(post, callback: { (success, errorId, errorMessage, result) in
                if success {
                    if post.visible! {
                        NotificationManager.sendNotification(.NearbyPostAdded, object: post)
                    } else {
                        NotificationManager.sendNotification(.NearbyPostRemoved, object: post.id)
                    }
                    self.tableView.rectForRowAtIndexPath(indexPath)
                } else {
                    self.showAlert("Error", message: errorMessage)
                }
            })
        }
        
        actions.append(button)
        
        button = UITableViewRowAction(style: .Destructive, title: NSLocalizedString("Delete", comment: "Title, Delete")) { (action, indexPath) in
            AppAnalytics.logEvent(.MyPostsScreen_SlideDelete_Clicked)
            print("delete")
            //self.tableView.editing = false
            
            self.deletePost(indexPath) { success in
                if success {
                    if self.myPosts.count == 0{
                        self.tableView.reloadData()
                    } else {
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }
                }
            }
        }
        
        actions.append(button)
        
        return actions
    }
}
