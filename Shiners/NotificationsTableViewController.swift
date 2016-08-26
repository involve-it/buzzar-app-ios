//
//  NotificationsTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NotificationsTableViewController: UITableViewController {

    
    @IBOutlet weak var cbNotifications: UISwitch!
    private var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AccountHandler.Instance.currentUser != nil {
            self.currentUser = AccountHandler.Instance.currentUser
        }

        //check notifications switch
        refreshNotification()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    @IBAction func cbNotifications_Changed(sender: UISwitch) {
        if let currentUser = self.currentUser {
            if sender.on && !UIApplication.sharedApplication().isRegisteredForRemoteNotifications(){
                self.showAlert("Notifications", message: "To receive notifications, please allow this in device Settings.");
                sender.on = false
            } else {
                let initialState = currentUser.enableNearbyNotifications
                currentUser.enableNearbyNotifications = sender.on
                
                AccountHandler.Instance.saveUser(currentUser) { (success, errorMessage) in
                    if (!success){
                        ThreadHelper.runOnMainThread({
                            self.showAlert("Error", message: "An error occurred while saving.")
                            self.currentUser?.enableNearbyNotifications = initialState
                            sender.on = initialState ?? false
                        })
                    }
                }
            }
        }
    }
    
    func refreshNotification() {
         if let enableNearbyNotifications = self.currentUser?.enableNearbyNotifications {
            self.cbNotifications.on = enableNearbyNotifications
         } else {
            self.cbNotifications.on = false
         }
    }
    
    
    // MARK: - Table view data source

/*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
*/
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
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
