//
//  cellAboutMe.swift
//  Shiners
//
//  Created by Вячеслав on 8/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class cellAboutMe: UITableViewCell {
    
    
    @IBOutlet weak var txtAboutMeTitle: UILabel!
    @IBOutlet weak var txtAboutMeBio: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        txtAboutMeTitle.text = NSLocalizedString("About Me", comment: "Title, About Me")
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
