//
//  SettingsProfileTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/17/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class SettingsProfileTableViewController: UITableViewController {

    private var currentUser: User?
    private var meteorLoaded = false
    private var accountDetailsPending = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if ConnectionHandler.Instance.status == .Connected {
            self.accountUpdated(nil)
        } else {
            if CachingHandler.Instance.status != .Complete {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
            } else if let currentUser = CachingHandler.Instance.currentUser {
                self.currentUser = currentUser
                //self.refreshUser()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.AccountUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accountUpdated), name: NotificationManager.Name.UserUpdated.rawValue, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showOfflineData(){
        if !self.meteorLoaded {
            self.currentUser = CachingHandler.Instance.currentUser
            //self.refreshUser()
            ThreadHelper.runOnMainThread {
                self.tableView.reloadData()
            }
        }
    }
    
    func accountUpdated(object: AnyObject?){
        self.meteorLoaded = true
        self.currentUser = AccountHandler.Instance.currentUser
        //self.refreshUser()
        ThreadHelper.runOnMainThread {
            self.tableView.reloadData()
            
            if self.accountDetailsPending {
                self.setLoading(false)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("profileController")
                self.navigationController?.pushViewController(vc, animated: true);
            }
        }
    }
    
    

    // MARK: - Table view data source

    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }****/

    /*
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }****/

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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 4 {
            let alertViewController = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .ActionSheet)
            alertViewController.addAction(UIAlertAction(title: "Log out", style: .Destructive, handler: { (_) in
                AccountHandler.Instance.logoff(){ success in
                    if (success){
                        self.currentUser = nil;
                        //self.refreshUser();
                        /*dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData();
                        })*/
                        self.navigationController?.popViewControllerAnimated(true)
                    } else {
                        self.showAlert("Error", message: "An error occurred")
                    }
                };
            }))
            
            alertViewController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(alertViewController, animated: true, completion: nil)
        }
    }
    
    //MARK: - Action
   

}
