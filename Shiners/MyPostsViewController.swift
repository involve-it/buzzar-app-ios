//
//  MyPostsViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class MyPostsViewController: UITableViewController{
    var myPosts = [Post]()
    
    var meteorLoaded = false
    var pendingPostId: String?
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(myPostsUpdated), name: NotificationManager.Name.MyPostsUpdated.rawValue, object: nil)
        self.myPosts = [Post]()
        if AccountHandler.Instance.status == .Completed {
            self.meteorLoaded = true
            if let myPosts = AccountHandler.Instance.myPosts{
                self.myPosts = myPosts
            } else {
                self.myPosts = [Post]()
            }
            self.checkPending()
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
    }
    
    /*public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.checkPending()
    }*/
    
    func checkPending(){
        if let pendingPostId = self.pendingPostId, postIndex = self.myPosts.indexOf({$0.id == pendingPostId}){
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
        if let price = post.price where post.price != "" {
            cell.txtPrice.text = "$\(price)";
        } else {
            cell.txtPrice.text = "";
        }
        
        let loading = ImageCachingHandler.Instance.getImageFromUrl(post.getMainPhoto()?.original) { (image) in
            dispatch_async(dispatch_get_main_queue(), {
                if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? PostsTableViewCell{
                    cellToUpdate.imgPhoto?.image = image;
                }
            })
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultPhoto;
        }
        
        return cell
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "myPostDetails"){
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = myPosts[index];
            vc.post = post;
        }
    }
   
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
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
    }
}
