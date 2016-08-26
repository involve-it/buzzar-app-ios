//
//  ChangePasswordTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/26/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class ChangePasswordTableViewController: UITableViewController, UITextFieldDelegate {

    
    @IBOutlet weak var textFieldCurrentPassword: UITextField!
    @IBOutlet weak var textFieldNewPassword: UITextField!
    @IBOutlet weak var textFieldConfirmNewPassword: UITextField!
    
    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.setLoading(false, rightBarButtonItem: self.btnSave)
        
        self.tableView.separatorColor = UIColor.clearColor()
        textFieldConfigure([self.textFieldCurrentPassword, self.textFieldNewPassword, self.textFieldConfirmNewPassword])
        leftPaddingToTextField([self.textFieldCurrentPassword, self.textFieldNewPassword, self.textFieldConfirmNewPassword])
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    public func textFieldConfigure(textField: [UITextField]) {
        for item in textField {
            item.layer.cornerRadius = 4.0
        }
    }
    
    // TODO: - duplication code
    public func leftPaddingToTextField(array: [UITextField]) {
        
        for textField in array {
            let paddingView = UIView(frame: CGRectMake(0, 0, 15, textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = UITextFieldViewMode.Always
        }
        
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        //TODO: Make check textField isEmpty
        if (textField === self.textFieldCurrentPassword){
            self.textFieldNewPassword.becomeFirstResponder()
        } else if textField === self.textFieldNewPassword {
            self.textFieldConfirmNewPassword.becomeFirstResponder()
        } else if textField === self.textFieldConfirmNewPassword {
            self.changePassword()
            textField.resignFirstResponder()
        }
        
        return false
    }

    private func changePassword() {
        
    }
    
    
    // MARK: Action
    @IBAction func btn_Save(sender: UIBarButtonItem) {
        self.changePassword()
    }
    
    @IBAction func btn_Cancel(sender: UIBarButtonItem) {
            self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func btn_ForgotPassword(sender: UIButton) { }
    
    
    // MARK: - Table view data source
/*
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
