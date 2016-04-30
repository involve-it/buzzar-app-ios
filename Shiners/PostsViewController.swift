//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController{
    //private var posts:[Post] = [];
    //private var imageCache: Dictionary<String, UIImage> = [:]
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "postDetails"){
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = ConnectionHandler.Instance.postsCollection.itemAtIndex(index);
            vc.post = post;
            vc.navigationItem.title = "Post Details";
        }
    }
    
    override func viewDidLoad() {
        ConnectionHandler.Instance.onConnected { 
            self.tableView.reloadData();
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: PostsTableViewCell = tableView.dequeueReusableCellWithIdentifier("postListItem") as! PostsTableViewCell;
        let post: Post = ConnectionHandler.Instance.postsCollection.itemAtIndex(indexPath.row);
        
        cell.txtTitle.text = post.title;
        cell.txtDetails.text = post.description;
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
        
        return cell;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ConnectionHandler.Instance.postsCollection.count();
    }
}
