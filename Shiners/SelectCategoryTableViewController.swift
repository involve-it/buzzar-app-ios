//
//  SelectCategoryTableViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 11/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import Foundation

class SelectCategoryTableViewController: UITableViewController {
    let categories = ["jobs", "trainings", "connect", "trade", "housing", "events", "services", "help"];
    
    var currentCategory: String?
    var selectCategoryDelegate: SelectCategoryViewControllerDelegate?
    
    override func viewDidLoad() {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let currentCategory = self.currentCategory, index = self.categories.indexOf(currentCategory) {
            self.tableView.visibleCells.forEach { (cell) in
                cell.accessoryType = .None
            }
            self.tableView.cellForRowAtIndexPath(NSIndexPath(forItem: index, inSection: 1))!.accessoryType = .Checkmark
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.visibleCells.forEach { (cell) in
            cell.accessoryType = .None
        }
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)!
        cell.accessoryType = .Checkmark
        var category:String? = nil
        var value = NSLocalizedString("None", comment: "None")
        if indexPath.section == 1{
            category = self.categories[indexPath.row]
            value = cell.textLabel!.text!
        }
        self.selectCategoryDelegate?.categorySelected(category, value: value)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

protocol SelectCategoryViewControllerDelegate{
    func categorySelected(category: String?, value: String)
}
