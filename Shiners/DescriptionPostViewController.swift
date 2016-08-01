//
//  DescriptionPostViewController.swift
//  wizard2
//
//  Created by Вячеслав on 7/6/16.
//  Copyright © 2016 mr.Douson. All rights reserved.
//

import UIKit

class DescriptionPostViewController: UIViewController, UITextViewDelegate {
    
    
    @IBOutlet weak var titleCountOfDescription: UILabel!
    @IBOutlet weak var fieldDescriptionOfPost: UITextView!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    
    
    //Устанавливаем лимит символов для поля с описанием
    var descriptionAllowCount:String = "1000"
    
    //Создаем объект для приниятия данных с контроллера в предыдущей цепочке
    var post: Post!
    
    var currentLocationInfo: GeocoderInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentLocationInfo == nil {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(currentLocationReported), name: NotificationManager.Name.NewPostLocationReported.rawValue, object: nil)
        }

        //Set focus to textfield
        fieldDescriptionOfPost.becomeFirstResponder()
        
        // Устанавливаем начальное значение в метку счетчика разрешенного кол-во символов
        titleCountOfDescription.text = String(descriptionAllowCount)
        
        
        if let text = fieldDescriptionOfPost.text where !text.isEmpty {
            //do something if it's not empty
            titleCountOfDescription.text = String(text.characters.count)
        }
        
    }
    
    func currentLocationReported(notification: NSNotification){
        let geocoderInfo = notification.object as! GeocoderInfo
        self.currentLocationInfo = geocoderInfo
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func textViewDidChange(textView: UITextView) {
        
        //Изменение titleCountOfDescription в зависимости от лимита
        let currentCountFieldDescriptionOfPost: Int = fieldDescriptionOfPost.text.characters.count
        titleCountOfDescription.text =  String(Int(descriptionAllowCount)! - currentCountFieldDescriptionOfPost)
        
        if currentCountFieldDescriptionOfPost > 0 {
            self.btn_next.enabled = true
        } else {
            self.btn_next.enabled = false
        }
    }
    
    
    //TextView limit characters
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if range.length + range.location > fieldDescriptionOfPost.text.characters.count {
            return false
        } else {
            let newlength = fieldDescriptionOfPost.text.characters.count + text.characters.count - range.length
            return newlength <= Int(descriptionAllowCount)
        }
        
    }
    
    

    
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chooseLocation" {
            if let destination = segue.destinationViewController as? WhereViewController{
                
                //Создаем объект post
                var post = Post()
                
                //Из пришедших данных в контроллер добавляем в созданный объект
                post = self.post
                
                //В свойство объекта desc помещаем строку из fieldDescriptionOfPost
                post.descr = fieldDescriptionOfPost.text
                
                //Передаем объект post следующему контроллеру
                destination.post = post
                
                destination.currentLocationInfo = self.currentLocationInfo
            }
        }
    }
    

}
