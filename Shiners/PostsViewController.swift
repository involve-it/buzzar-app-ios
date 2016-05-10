//
//  PostsViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController, SearchViewControllerDelegate{
    //private var posts:[Post] = [];
    //private var imageCache: Dictionary<String, UIImage> = [:]
    
    @IBOutlet weak var lcTxtSearchBoxLeft: NSLayoutConstraint!
    @IBOutlet var segmFilter: UISegmentedControl!
    @IBOutlet weak var txtSearchBox: UITextField!
    @IBOutlet var searchView: UIView!
    var searchViewController: NewSearchViewController?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "postDetails"){
            let vc:PostDetailsViewController = segue.destinationViewController as! PostDetailsViewController;
            let index = self.tableView.indexPathForSelectedRow!.row;
            let post = ConnectionHandler.Instance.postsCollection.itemAtIndex(index);
            vc.post = post;
            vc.navigationItem.title = "Post Details";
        } else if (segue.identifier == "searchSegue"){
            self.searchViewController = segue.destinationViewController as? NewSearchViewController
            self.searchViewController?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        self.searchView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
//        self.txtSearchBox.bounds = CGRectMake(0, 0, 1, self.txtSearchBox.bounds.height)
//        self.lcTxtSearchBoxLeft.constant = self.view.frame.width;
        ConnectionHandler.Instance.onConnected {
            self.tableView.reloadData();
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(forceLayout), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func forceLayout(){
        self.searchView.frame = self.view.bounds;
        self.searchViewController?.setContentInset(self.navigationController!, tabBarController: self.tabBarController!)
        //self.view.layoutIfNeeded()
        self.view.layoutSubviews()
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
