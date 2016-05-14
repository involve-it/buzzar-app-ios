//
//  MessagesViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class MessagesViewController: UITableViewController{
    var dialogs = [Dialog]()
    
    public override func viewDidLoad() {
        //temp
        self.dialogs.append(Dialog())
        
        if (dialogs.count == 0){
            self.tableView.scrollEnabled = false;
            self.tableView.separatorStyle = .None;
        } else {
            self.tableView.scrollEnabled = true;
            self.tableView.separatorStyle = .SingleLine;
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, dialogs.count);
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (dialogs.count == 0){
            if (indexPath.row == 0){
                return self.tableView.dequeueReusableCellWithIdentifier("noMessages")!
            }
        }
        //temp
        //let dialog = dialogs[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("dialog") as! MessagesTableViewCell
        
        cell.imgPhoto.image = ImageCachingHandler.defaultAccountImage
        cell.lblTitle.text = "Ashot Arutyunyan"
        cell.lblLastMessage.text = "This is temporary last message that was sent or received."
        
        return cell
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dialog"{
            let selectedCell = self.tableView.cellForRowAtIndexPath(self.tableView.indexPathForSelectedRow!) as! MessagesTableViewCell;
            let viewController = segue.destinationViewController as! DialogViewController
            viewController.navigationItem.title = selectedCell.lblTitle.text
        }
    }
}
