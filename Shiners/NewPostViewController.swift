//
//  NewPostViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NewPostViewController: UITableViewController{
    
    @IBOutlet weak var txtDescription: UITextView!
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
