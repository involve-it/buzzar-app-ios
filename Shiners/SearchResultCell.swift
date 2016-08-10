//
//  SearchResultCell.swift
//  Shiners
//
//  Created by Вячеслав on 8/6/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {

    
    @IBOutlet weak var imgAtPost: UIImageView!
    @IBOutlet weak var txtTitlePost: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
