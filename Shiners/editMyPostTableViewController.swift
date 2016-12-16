//
//  editMyPostTableViewController.swift
//  Shiners
//
//  Created by Вячеслав on 14/12/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class editMyPostTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var titleTextCount: UILabel!
    @IBOutlet weak var titleNewPost: UITextField!
    
    @IBOutlet weak var fieldDescriptionOfPost: UITextView!
    @IBOutlet weak var titleCountOfDescription: UILabel!
    
    @IBOutlet weak var btn_update: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Заполняем начальное значение при инициализации контроллера
        titleTextCount.text = String(titleAllowCount)
        // Устанавливаем начальное значение в метку счетчика разрешенного кол-во символов
        titleCountOfDescription.text = String(descriptionAllowCount)
        
        //Placeholder
        fieldDescriptionOfPost.text = descriptionPlaceholderText
        fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
        
        txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }

    @IBAction func titleFieldChanged(_ sender: UITextField) {
        let currentCountTitleTextField:Int = (titleNewPost.text?.characters.count)!
        titleTextCount.text = String( Int(titleAllowCount)! - currentCountTitleTextField )
        
        if let title = sender.text, title != "" {
            btn_update.isEnabled = true
        } else {
            btn_update.isEnabled = false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        //Изменение titleCountOfDescription в зависимости от лимита
        let currentCountFieldDescriptionOfPost: Int = fieldDescriptionOfPost.text.characters.count
        titleCountOfDescription.text =  String(Int(descriptionAllowCount)! - currentCountFieldDescriptionOfPost)
    }
    
    //Textfield limit characters
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if range.length + range.location > titleNewPost.text!.characters.count {
            return false
        } else {
            let newlength = titleNewPost.text!.characters.count + string.characters.count - range.length
            return newlength <= Int(titleAllowCount)
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentText: NSString = fieldDescriptionOfPost.text as NSString
        let updateText = currentText.replacingCharacters(in: range, with: text)
        
        if updateText.isEmpty || range.length + range.location > fieldDescriptionOfPost.text.characters.count{
            fieldDescriptionOfPost.text = descriptionPlaceholderText
            fieldDescriptionOfPost.textColor = descriptionPlaceholderColor
            
            txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            return false
            
        } else if (fieldDescriptionOfPost.textColor == descriptionPlaceholderColor && !text.isEmpty)  {
            fieldDescriptionOfPost.text = nil
            fieldDescriptionOfPost.textColor = UIColor.black
        } else {
            let newlength = fieldDescriptionOfPost.text.characters.count + text.characters.count - range.length
            return newlength <= Int(descriptionAllowCount)
        }
        
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if fieldDescriptionOfPost.textColor == descriptionPlaceholderColor {
                txtPlaceholderSelectedTextRange(fieldDescriptionOfPost)
            }
        }
    }
    
    func txtPlaceholderSelectedTextRange(_ placeholder: UITextView) -> () {
        placeholder.selectedTextRange = placeholder.textRange(from: placeholder.beginningOfDocument, to: placeholder.beginningOfDocument)
    }

  

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
