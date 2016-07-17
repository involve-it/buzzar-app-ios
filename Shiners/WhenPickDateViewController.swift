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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("\(post)")
        // Do any additional setup after loading the view.
        //labelDateNotYetSet.text = ""
    
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), forControlEvents: .ValueChanged)
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
    }
    
    

    
    //btn action
    
    @IBAction func pickOneDay(sender: AnyObject) {
        //Определяем насколько дней изменить текущую дату
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
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     
        // Передать с объектом дата новую дату. Создать под нее переменную и присваивать значение из вызываемых методов
     
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
