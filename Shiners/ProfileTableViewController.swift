//
//  ProfileTableViewController.swift
//  
//
//  Created by Вячеслав on 8/16/16.
//
//

import UIKit

class ProfileTableViewController: UITableViewController {
    
    
    
    
    struct TableViewIdentifierCell {
        static let cellUserProfileNib = "cellUserProfile"
        static let cellAboutMe = "cellAboutMe"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Profile"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        tableView.registerNib(UINib(nibName: TableViewIdentifierCell.cellUserProfileNib, bundle: nil), forCellReuseIdentifier: TableViewIdentifierCell.cellUserProfileNib)
        
        tableView.registerNib(UINib(nibName: TableViewIdentifierCell.cellAboutMe, bundle: nil), forCellReuseIdentifier: TableViewIdentifierCell.cellAboutMe)
        
        
        tabelViewEstimatedRowHeight()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if (indexPath.row == 0) {

           let cell = tableView.dequeueReusableCellWithIdentifier(TableViewIdentifierCell.cellUserProfileNib, forIndexPath: indexPath) as! cellUserProfile
            
            return cell
        
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewIdentifierCell.cellAboutMe, forIndexPath: indexPath) as! cellAboutMe

            return cell
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tabelViewEstimatedRowHeight() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    
    // MARK: - Table view data source
    
    /*
     override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
     // #warning Incomplete implementation, return the number of sections
     return 0
     }
     
     override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     // #warning Incomplete implementation, return the number of rows
     return 2
     }
     */
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
