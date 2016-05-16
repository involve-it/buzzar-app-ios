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
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(myPostsUpdated), name: NotificationManager.Name.MyPostsUpdated.rawValue, object: nil)
        myPosts = ConnectionHandler.Instance.posts.myPosts;
        if (myPosts.count == 0){
            //self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .None;
        } else {
            //self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .SingleLine;
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateMyPosts), forControlEvents: .ValueChanged)
    }
    
    func updateMyPosts(){
        ConnectionHandler.Instance.posts.getMyPosts(false) { (success, errorId, errorMessage, result) in
            self.myPostsUpdated();
        }
    }
    
    func myPostsUpdated(){
        self.refreshControl?.endRefreshing()
        self.myPosts = ConnectionHandler.Instance.posts.myPosts;
        self.tableView.separatorStyle = .SingleLine;
        self.tableView.reloadData()
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, myPosts.count);
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (myPosts.count == 0){
            if (indexPath.row == 0){
                return self.tableView.dequeueReusableCellWithIdentifier("noPosts")!
            }
        }
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("post") as! PostsTableViewCell
        let post: Post = ConnectionHandler.Instance.postsCollection.itemAtIndex(indexPath.row);
        
        cell.txtTitle.text = post.title;
        cell.txtDetails.text = post.descr;
        if let price = post.price where post.price != "" {
            cell.txtPrice.text = "$\(price)";
        } else {
            cell.txtPrice.text = "";
        }
        
        let loading = ImageCachingHandler.Instance.getImage(post.imageIds?[0]) { (image) in
            dispatch_async(dispatch_get_main_queue(), {
                if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? PostsTableViewCell{
                    cellToUpdate.imgPhoto?.image = image;
                }
            })
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultImage;
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
}
