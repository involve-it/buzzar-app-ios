//
//  ValuePickerViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class ValuePickerViewController: UITableViewController {
    //keys only
    var selectedItems = [String]()
    //key-value pairs
    var items = [String: String]()
    var multipleSelection = false
    var id: String?
    
    //Select "something"
    var titleComponent: String?
    
    var delegate: ValuePickerViewControllerDelegate?
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func btnDone_Click(sender: AnyObject) {
        self.delegate?.valuePickerController(self, withId: id, selectionReturned: selectedItems)
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil);
    }
    
    override func viewDidLoad() {
        if let titleComponent = self.titleComponent{
            self.navigationItem.title = "Select \(titleComponent)"
        }
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("valuePickerItem")
        let item = Array(items.values)[indexPath.row]
        let key = Array(items.keys)[indexPath.row]
        cell?.textLabel?.text = item
        if self.selectedItems.contains(key){
            cell?.accessoryType = .Checkmark
        } else {
            cell?.accessoryType = .None
        }
        return cell!
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = Array(items.keys)[indexPath.row]
        if let selectedIndex = selectedItems.indexOf(item){
            selectedItems.removeAtIndex(selectedIndex)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            if self.multipleSelection || self.selectedItems.count == 0 {
                self.selectedItems.append(item)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            } else {
                self.selectedItems.removeAll()
                self.selectedItems.append(item)
                var indexPaths = [indexPath]
                if let currentIndex = Array(items.keys).indexOf(selectedItems[0]) {
                    indexPaths.append(NSIndexPath(forRow: currentIndex, inSection: 0))
                }
                
                self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

protocol ValuePickerViewControllerDelegate{
    func valuePickerController(valuePickerController: ValuePickerViewController, withId: String?, selectionReturned: [String])
}