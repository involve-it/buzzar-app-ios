//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController, SearchViewControllerDelegate{
    private var posts = [Post]();
    
    @IBOutlet weak var lcTxtSearchBoxLeft: NSLayoutConstraint!
    @IBOutlet var segmFilter: UISegmentedControl!
    @IBOutlet weak var txtSearchBox: UITextField!
    @IBOutlet var searchView: UIView!
    var searchViewController: NewSearchViewController?
    
    private var meteorLoaded = false;
    
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
        self.searchView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        
        if ConnectionHandler.Instance.status == .Connected {
            self.meteorLoaded = true
            self.posts = ConnectionHandler.Instance.postsCollection.posts;
        } else {
            if CachingHandler.Instance.status != .Complete {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
            } else if let posts = CachingHandler.Instance.postsAll {
                self.posts = posts
            }
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
    
    @objc private func meteorConnected(notification: NSNotification){
        self.meteorLoaded = true
        self.posts = ConnectionHandler.Instance.postsCollection.posts
        self.tableView.separatorStyle = .SingleLine;
        ThreadHelper.runOnMainThread { 
            self.tableView.reloadData()
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
            if ConnectionHandler.Instance.status == .Connected{
                cell = tableView.dequeueReusableCellWithIdentifier("noPosts")
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
