//
//  WhenPickDateViewController.swift
//  Shiners
//
//  Created by Вячеслав on 7/7/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class WhenPickDateViewController: UIViewController {

    
    
    @IBOutlet weak var labelDateNotYetSet: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var btn_next: UIBarButtonItem!
    
    
    var post: Post!
    
    var currentLocationInfo: GeocoderInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //labelDateNotYetSet.text = ""
    
        datePicker.minimumDate = NSDate()
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), forControlEvents: .ValueChanged)
        
        if let date = post.endDate{
            self.datePicker.date = date
            self.btn_next.enabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func datePickerChanged(sender: UIDatePicker) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        if let title:String = formatter.stringFromDate(sender.date) {
           labelDateNotYetSet.text = title
            
            //Btn "next" set enabled
            btn_next.enabled = true
        } else {
            //Btn "next" set disabled
            btn_next.enabled = false
        }
        post.endDate = self.datePicker.date
    }
    
    
    //btn action
    @IBAction func pickOneDay(sender: AnyObject) {
        let dayToAdd = 1
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = dayToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickTwoDays(sender: AnyObject) {
        let daysToAdd = 2
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneWeek(sender: AnyObject) {
        let daysToAdd = 7
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickTwoWeek(sender: AnyObject) {
        let daysToAdd = 14
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneMonth(sender: AnyObject) {
        let monthToAdd = 1
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.month = monthToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneYear(sender: AnyObject) {
        let yearToAdd = 1
        
        //Текущая дата
        let currentDate = NSDate()
        let newDateComponents = NSDateComponents()
        
        //Установка даты в компонент
        newDateComponents.year = yearToAdd
        let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.stringFromDate(calculatedDate!)
        
        if(!btn_next.enabled) {
            btn_next.enabled = true
        }
        post.endDate = self.datePicker.date
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addPhotos" {
            if let destination = segue.destinationViewController as? PhotosViewController {
                //Передаем объект post следующему контроллеру
                destination.post = post
                destination.currentLocationInfo = self.currentLocationInfo
            }
        } 
    }
    
    

}
