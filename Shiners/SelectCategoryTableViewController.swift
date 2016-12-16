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
    var currentCategory: String?
    var selectCategoryDelegate: SelectCategoryViewControllerDelegate?
    
    override func viewDidLoad() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let currentCategory = self.currentCategory, let index = ConstantValuesHandler.Instance.categories.index(of: currentCategory) {
            self.tableView.visibleCells.forEach { (cell) in
                cell.accessoryType = .none
            }
            self.tableView.cellForRow(at: IndexPath(item: index, section: 1))!.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.visibleCells.forEach { (cell) in
            cell.accessoryType = .none
        }
        let cell = self.tableView.cellForRow(at: indexPath)!
        cell.accessoryType = .checkmark
        var category:String? = nil
        var value = NSLocalizedString("None", comment: "None")
        if indexPath.section == 1{
            category = ConstantValuesHandler.Instance.categories[indexPath.row]
            value = cell.textLabel!.text!
        }
        self.selectCategoryDelegate?.categorySelected(category, value: value)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}

protocol SelectCategoryViewControllerDelegate{
    func categorySelected(_ category: String?, value: String)
}
