//
//  MyPostsViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class MyPostsViewController: UITableViewController, UIViewControllerPreviewingDelegate{
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
                let alertController = UIAlertController(title: NSLocalizedString("Delete Posts", comment: "Delete Posts"), message: NSLocalizedString("Are you sure you want to delete selected post(s)?", comment: "Alert message, Are you sure you want to delete selected posts?"), preferredStyle: .actionSheet);
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (action) in
                    //self.showAlert("Deleted", message: "Deleted")
                    var processedCount = 0
                    var successfulIndexPaths = [IndexPath]()
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
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil));
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func endEditIfDone(_ count: Int, processedCount: Int, allIndexPaths: [IndexPath]){
        if count == processedCount {
            if self.tableView.isEditing {
                ThreadHelper.runOnMainThread({ 
                    self.editAction(self.editButtonItem)
                })
            }
            ThreadHelper.runOnMainThread({
                if self.myPosts.count == 0{
                    let allExceptFirst = allIndexPaths.filter({$0.row != 0})
                    self.tableView.deleteRows(at: allExceptFirst, with: .none)
                    self.tableView.reloadData()
                } else {
                    self.tableView.deleteRows(at: allIndexPaths, with: .automatic)
                }
            })
            AccountHandler.Instance.updateMyPosts()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(myPostsUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.MyPostsUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(myPostUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.MyPostUpdated.rawValue), object: nil)
        self.btnDelete = UIBarButtonItem(title: NSLocalizedString("Delete", comment: "Delete"), style: UIBarButtonItemStyle.done, target: self, action: #selector(deletePosts))
        self.myPosts = [Post]()
        if AccountHandler.Instance.status == .completed {
            self.meteorLoaded = true
            if let myPosts = AccountHandler.Instance.myPosts{
                self.myPosts = myPosts
            } else {
                self.myPosts = [Post]()
            }
        } else {
            if CachingHandler.Instance.status != .complete {
                NotificationCenter.default.addObserver(self, selector: #selector(showOfflineData), name: NSNotification.Name(rawValue: NotificationManager.Name.OfflineCacheRestored.rawValue), object: nil)
            } else if let posts = CachingHandler.Instance.postsMy {
                self.myPosts = posts
            }
        }
        
        if (myPosts.count == 0){
            self.tableView.separatorStyle = .none;
        } else {
            self.tableView.separatorStyle = .singleLine;
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateMyPosts), for: .valueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            self.registerForPreviewing(with: self, sourceView: view)
        }
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.editButtonItem.action = #selector(editAction)
        
        if self.myPosts.count > 0{
            self.editButtonItem.isEnabled = true
        } else {
            self.editButtonItem.isEnabled = false
        }
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func myPostUpdated(notification: Notification){
        if let post = notification.object as? Post, let index =  self.myPosts.index(where: {$0.id == post.id}){
            let currentPost = self.myPosts[index]
            currentPost.updateFrom(post: post)
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
    
    func editAction(_ sender: UIBarButtonItem){
        AppAnalytics.logEvent(.MyPostsScreen_BtnEdit_Click)
        if self.tableView.isEditing{
            self.tableView.setEditing(false, animated: true)
            self.parent!.navigationItem.rightBarButtonItem = (self.parent as! ProfileMainViewController).btnAdd
            
            sender.title = NSLocalizedString("Edit", comment: "Edit")
        } else {
            self.tableView.setEditing(true, animated: true)
            self.parent!.navigationItem.rightBarButtonItem = self.btnDelete
            sender.title = NSLocalizedString("Done", comment: "Done")
        }
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else {return nil}
        guard let cell = self.tableView.cellForRow(at: indexPath) else {return nil}
        let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "postDetails") as? PostDetailsViewController
        
        let post = myPosts[indexPath.row];
        viewController?.post = post
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.show(viewControllerToCommit, sender: self)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.MyPosts)
        self.checkPending()
        self.refreshControl?.endRefreshing()
    }
    
    func appDidBecomeActive(){
        if self.myPosts.count > 0 && AccountHandler.Instance.status == .completed{
            self.checkPending()
        }
        self.refreshControl?.endRefreshing()
    }
    
    @IBAction func btnEdit_Click(_ sender: AnyObject) {
        self.tableView.setEditing(true, animated: true)
    }
    
    func checkPending(){
        if let pendingPostId = self.pendingPostId, let postIndex = self.myPosts.index(where: {$0.id == pendingPostId}){
            //self.navigationController?.popToViewController(self, animated: false)
            let indexPath = IndexPath(row: postIndex, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            self.performSegue(withIdentifier: "myPostDetails", sender: self)
        }
        self.pendingPostId = nil
    }
    
    func showOfflineData(){
        if !self.meteorLoaded{
            if let posts = CachingHandler.Instance.postsMy{
                self.myPosts = posts
                ThreadHelper.runOnMainThread {
                    self.tableView.separatorStyle = .singleLine;
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.myPosts.count > 0 && AccountHandler.Instance.status == .completed{
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
                self.editButtonItem.isEnabled = true
            } else {
                self.editButtonItem.isEnabled = false
            }
            self.refreshControl?.endRefreshing()
            self.tableView.separatorStyle = .singleLine;
            self.tableView.reloadData()
            
            self.checkPending()
        }
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, myPosts.count);
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (myPosts.count == 0){
            if self.meteorLoaded
            {
                return tableView.dequeueReusableCell(withIdentifier: "noPosts")!
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "waitingPosts")!
            }
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "post") as! PostsTableViewCell
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
        
        if let price = post.price, post.price != "" {
            cell.txtPrice.text = "$\(price)";
        } else {
            cell.txtPrice.text = "";
        }
        var loading = false;
        if let url = post.getMainPhoto()?.original {
            loading = ImageCachingHandler.Instance.getImageFromUrl(url) { (image) in
                ThreadHelper.runOnMainThread {
                    if tableView.indexPathsForVisibleRows?.index(where: {$0.row == indexPath.row}) != nil {
                        cell.imgPhoto.image = image
                    }
                }
            }
        } else {
            cell.imgPhoto.image = ImageCachingHandler.defaultPhoto;
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultPhoto;
        }
        
        return cell
    }
    
    open override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !self.tableView.isEditing
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "myPostDetails"){
            AppAnalytics.logEvent(.MyPostsScreen_PostSelected)
            let vc:PostDetailsViewController = segue.destination as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = myPosts[index];
            vc.isOwnPost = true
            vc.post = post;
            vc.pendingCommentsAsyncId = CommentsHandler.Instance.getCommentsAsync(post.id!, skip: 0)
            if (sender as? MyPostsViewController) == self {
                vc.scrollToComments = true
            }
        } else if segue.identifier == "myPosts_CreatePost"{
            AppAnalytics.logEvent(.MyPostsScreen_BtnNewPost_Click)
        }
    }
   
    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func deletePost(_ indexPath: IndexPath, callback: ((_ success: Bool) -> Void)? = nil) {
        let post = self.myPosts[indexPath.row]
        ConnectionHandler.Instance.posts.deletePost(post.id!) { success, errorId, errorMessage, result in
            if success {
                NotificationManager.sendNotification(.NearbyPostRemoved, object: post.id as AnyObject?)
                self.myPosts.remove(at: self.myPosts.index(where: { (p) -> Bool in
                    return p.id == post.id
                })!)
            } else {
                self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
            }
            callback?(success)
        }
    }
    
    open override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions = [UITableViewRowAction]()
        
        let post = self.myPosts[indexPath.row]
        let title = (post.visible ?? false) ? NSLocalizedString("Hide", comment: "Title, Hide") : NSLocalizedString("Show", comment: "Title, Show")
        
        var button = UITableViewRowAction(style: .normal, title: title) { (action, indexPath) in
            AppAnalytics.logEvent(.MyPostsScreen_SlideHide_Clicked)
            print(title)
            let post = self.myPosts[indexPath.row]
            post.visible = !(post.visible ?? false)
            self.tableView.isEditing = false
            ConnectionHandler.Instance.posts.editPost(post, callback: { (success, errorId, errorMessage, result) in
                if success {
                    if post.visible! {
                        NotificationManager.sendNotification(.NearbyPostAdded, object: post)
                    } else {
                        NotificationManager.sendNotification(.NearbyPostRemoved, object: post.id as AnyObject?)
                    }
                    self.tableView.rectForRow(at: indexPath)
                } else {
                    self.showAlert("Error", message: errorMessage)
                }
            })
        }
        
        actions.append(button)
        
        button = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Title, Delete")) { (action, indexPath) in
            AppAnalytics.logEvent(.MyPostsScreen_SlideDelete_Clicked)
            print("delete")
            //self.tableView.editing = false
            
            self.deletePost(indexPath) { success in
                if success {
                    if self.myPosts.count == 0{
                        self.tableView.reloadData()
                    } else {
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
        
        actions.append(button)
        
        return actions
    }
}
