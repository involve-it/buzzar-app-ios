//
//  NewPostNewViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/7/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NewPostNewViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var titleTextCount: UILabel!
    @IBOutlet weak var titleNewPost: UITextField!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    
    //Устанавливаем лимит символов для текстового поля
    var titleAllowCount:String = "75"
    
    @IBAction func titleFieldChanged(sender: UITextField) {
        
        let currentCountTitleTextField:Int = (titleNewPost.text?.characters.count)!
        titleTextCount.text = String( Int(titleAllowCount)! - currentCountTitleTextField )
        
        if let title = sender.text where title != "" {
            btn_next.enabled = true
        } else {
            btn_next.enabled = false
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Заполняем начальное значение при инициализации контроллера
        titleTextCount.text = String(titleAllowCount)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Textfield limit characters
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if range.length + range.location > titleNewPost.text!.characters.count {
            return false
        } else {
            let newlength = titleNewPost.text!.characters.count + string.characters.count - range.length
            return newlength <= Int(titleAllowCount)
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chooseDescription" {
            if let destination = segue.destinationViewController as? DescriptionPostViewController {
                
                //Создаем объект post
                let post = Post()
                
                //В свойство объекта title помещаем строку из titleNewPost
                post.title = titleNewPost.text
                
                //Передаем объект post следующему контроллеру
                destination.post = post
                
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
