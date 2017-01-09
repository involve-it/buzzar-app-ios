//
//  NearbyUserTableViewCell.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/20/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class NearbyUserTableViewCell: UITableViewCell {
    @IBOutlet weak var txtUsername: UILabel!
    @IBOutlet weak var txtFullname: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    var fullNameShown = true

    @IBOutlet weak var imgPhoto: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(_ user: User){
        self.txtUsername.text = user.username
        if let fullName = user.getFullName(), fullName != "" {
            if !self.fullNameShown {
                self.fullNameShown = true
                self.stackView.addArrangedSubview(self.txtFullname!)
            }
            self.txtFullname!.text = fullName
        } else {
            self.stackView.removeArrangedSubview(self.txtFullname)
            self.txtFullname.text = ""
            self.fullNameShown = false
        }
        
        self.imgPhoto.contentMode = .scaleAspectFill
        self.imgPhoto.layer.cornerRadius = 30
        self.imgPhoto.layer.masksToBounds = true
        self.imgPhoto.clipsToBounds = true
        self.imgPhoto.image = ImageCachingHandler.defaultAccountImage
    }
    
    func updateImage(image: UIImage){
        self.imgPhoto.image = image
    }
}
