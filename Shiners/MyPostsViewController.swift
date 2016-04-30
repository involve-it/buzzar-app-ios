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
        if (myPosts.count == 0){
            self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .None;
        } else {
            self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .SingleLine;
        }
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
        
        //temp
        return self.tableView.dequeueReusableCellWithIdentifier("noPosts")!
    }
}
