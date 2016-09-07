//
//  SearchViewController.swift
//  LearningSwift2
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Yury Dorofeev. All rights reserved.
//

import UIKit

class SearchViewController: UITableViewController{
    
    @IBOutlet weak var txtRadius: UILabel!
    @IBOutlet weak var txtSearch: UITextField!
    @IBAction func btnSearch_Click(sender: UIBarButtonItem) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil);
    }
    
    override func viewDidLoad() {
        self.txtSearch.becomeFirstResponder();
    }
    
    @IBAction func slRadius_Changed(sender: UISlider) {
        let value:Float = round(sender.value);
        if (value < 50){
            self.txtRadius.text = "\(Int(value)) mi";
        } else  {
            self.txtRadius.text = NSLocalizedString("Everywhere", comment: "Everywhere");
        }
    }
}
