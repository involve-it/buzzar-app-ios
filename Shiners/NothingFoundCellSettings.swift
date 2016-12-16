//
//  NothingFoundCellSettings.swift
//  Shiners
//
//  Created by Вячеслав on 8/6/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NothingFoundCellSettings: UITableViewCell {

    

    //Вызывается когда ячейка была загружена из nib, но до того, как ячейка была добавлена в таблицу.
    override func awakeFromNib() {
        super.awakeFromNib()
    
        let  selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0)
        
        selectedBackgroundView = selectedView
        
    }
    
    @IBAction func pressTextYouCanAlways(_ sender: UIButton) {
        print("PRESS BUTTON __ YOU CAN ALWAYS...")
    }
    
    
}
