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
    
    var editingPost = false
    var post: Post!
    
    var currentLocationInfo: GeocoderInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.editingPost {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        // Do any additional setup after loading the view.
        //labelDateNotYetSet.text = ""
    
        datePicker.minimumDate = Date()
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        
        if let date = post.endDate{
            self.datePicker.date = date as Date
            self.setDateLabel()
            if !self.editingPost {
                self.btn_next.isEnabled = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppAnalytics.logScreen(.NewPost_When)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setDateLabel(){
        if let date = self.post.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            
            self.labelDateNotYetSet.text = formatter.string(from: date)
            if !self.editingPost{
                btn_next.isEnabled = true
            }
        } else {
            if !self.editingPost {
                btn_next.isEnabled = false
            }
        }
    }
    
    
    func datePickerChanged(_ sender: UIDatePicker) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Spinner_Modified)
        post.endDate = self.datePicker.date
        self.setDateLabel()
    }
    
    
    //btn action
    @IBAction func pickOneDay(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let dayToAdd = 1
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = dayToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickTwoDays(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let daysToAdd = 2
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneWeek(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let daysToAdd = 7
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickTwoWeek(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let daysToAdd = 14
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.day = daysToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneMonth(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let monthToAdd = 1
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.month = monthToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }
    
    
    @IBAction func pickOneYear(_ sender: AnyObject) {
        AppAnalytics.logEvent(.NewPostWizard_WhenStep_Preset_Click)
        let yearToAdd = 1
        
        //Текущая дата
        let currentDate = Date()
        var newDateComponents = DateComponents()
        
        //Установка даты в компонент
        newDateComponents.year = yearToAdd
        let calculatedDate = (Calendar.current as NSCalendar).date(byAdding: newDateComponents, to: currentDate, options: NSCalendar.Options.init(rawValue: 0))
        
        //Устанавливаем формат для даты
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        datePicker.date = calculatedDate!
        labelDateNotYetSet.text = formatter.string(from: calculatedDate!)
        
        if(self.btn_next != nil && !btn_next.isEnabled) {
            btn_next.isEnabled = true
        }
        post.endDate = self.datePicker.date
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addPhotos" {
            AppAnalytics.logEvent(.NewPostWizard_WhenStep_BtnNext_Click)
            if let destination = segue.destination as? PhotosViewController {
                //Передаем объект post следующему контроллеру
                destination.post = post
                destination.currentLocationInfo = self.currentLocationInfo
            }
        } 
    }
    
    

}
