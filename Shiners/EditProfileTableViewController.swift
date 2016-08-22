//
//  EditProfileTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 8/18/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class EditProfileTableViewController: UITableViewController, UITextViewDelegate {

    
    @IBOutlet weak var fNameView: UIView!
    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    
    
    @IBOutlet weak var txtBioPlaceholder: UITextView!
    let txtBioPlaceholderText = "Bio (optional)"
    let txtPlaceHolderColor = UIColor.lightGrayColor()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtBioPlaceholder.delegate = self
        
        //Placeholder
        txtBioPlaceholder.text = txtBioPlaceholderText
        txtBioPlaceholder.textColor = txtPlaceHolderColor
        
        //TODO: Need global constant
        txtBioPlaceholder.font = UIFont(name: "Helvetica Neue", size: 17.0)
        
        txtPlaceholderSelectedTextRange(txtBioPlaceholder)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidLayoutSubviews() {
        // Creates the bottom border
        //TODO: Make a function
        let borderBottom = CALayer()
        let borderWidth = CGFloat(1.0)
        let borderColor = UIColor(red: 164/255, green: 162/255, blue: 169/255, alpha: 0.3).CGColor
        
        borderBottom.borderColor = borderColor
        borderBottom.frame = CGRect(x: 0, y: fNameView.frame.height - 0.5, width: fNameView.frame.width , height: fNameView.frame.height - 0.5)
        borderBottom.borderWidth = borderWidth
        
        fNameView.layer.addSublayer(borderBottom)
        fNameView.layer.masksToBounds = true
    }

    // MARK: Cancel action
    @IBAction func btn_Cancel(sender: UIBarButtonItem) {
        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("settingsUserProfile")
        self.navigationController?.pushViewController(vc, animated: true)
         */
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let currentText: NSString = txtBioPlaceholder.text
        let updateText = currentText.stringByReplacingCharactersInRange(range, withString: text)
        
        if updateText.isEmpty {
            txtBioPlaceholder.text = txtBioPlaceholderText
            txtBioPlaceholder.textColor = txtPlaceHolderColor
            
           txtPlaceholderSelectedTextRange(txtBioPlaceholder)
            
            return false
        } else if (txtBioPlaceholder.textColor == txtPlaceHolderColor && !text.isEmpty)  {
            txtBioPlaceholder.text = nil
            txtBioPlaceholder.textColor = UIColor.blackColor()
        }
        
        
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if txtBioPlaceholder.textColor == txtPlaceHolderColor {
                txtPlaceholderSelectedTextRange(txtBioPlaceholder)
            }
        }
    }
    
    func txtPlaceholderSelectedTextRange(placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRangeFromPosition(placeholder.beginningOfDocument, toPosition: placeholder.beginningOfDocument)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        tableView.reloadData()
    }

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



