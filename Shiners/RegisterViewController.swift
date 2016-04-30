//
//  RegisterViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class RegisterViewController: UITableViewController{
    
    @IBOutlet weak var txtUsername: UITextField!
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public override func viewDidLoad() {
        self.txtUsername.becomeFirstResponder();
    }
}
