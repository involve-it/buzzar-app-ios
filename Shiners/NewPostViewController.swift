//
//  NewPostViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NewPostViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var txtAdType: UITextField!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var txtWhen: UITextField!
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var whenPicker = UIPickerView(frame: CGRectZero)
    var adTypePicker = UIPickerView(frame: CGRectZero)
    
    override func viewDidLoad() {
        self.whenPicker.delegate = self;
        self.whenPicker.dataSource = self;
        
        self.adTypePicker.delegate = self;
        self.adTypePicker.dataSource = self;
        
        self.txtWhen.inputView = self.whenPicker;
        self.txtAdType.inputView = self.adTypePicker;
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView === self.whenPicker){
            return ConstantValuesHandler.Instance.postDateRanges.count;
        } else if (pickerView === self.adTypePicker){
            return ConstantValuesHandler.Instance.adTypes.count;
        }
        
        return 0;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === self.whenPicker{
            return ConstantValuesHandler.Instance.postDateRanges[row]
        } else if pickerView === self.adTypePicker{
            return ConstantValuesHandler.Instance.adTypes[row]
        }
        
        return "";
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if pickerView === self.whenPicker || pickerView === self.adTypePicker{
            return 1;
        } else {
            return 0;
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView === self.whenPicker){
            self.txtWhen.text = ConstantValuesHandler.Instance.postDateRanges[row]
        } else if pickerView === self.adTypePicker {
            self.txtAdType.text = ConstantValuesHandler.Instance.adTypes[row]
        }
    }
}
