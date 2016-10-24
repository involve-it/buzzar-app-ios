//
//  cellUserProfile.swift
//  Shiners
//
//  Created by Вячеслав on 8/16/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class cellUserProfile: UITableViewCell {

    private var currentUser: User?
    
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var txtUserName: UILabel!
    @IBOutlet weak var txtUserLocation: UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        getUserData()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func getUserData() {
        if let currentUser = AccountHandler.Instance.currentUser {
            
            //Username
            if let firstName = self.currentUser?.getProfileDetailValue(.FirstName),
                lastName = self.currentUser?.getProfileDetailValue(.LastName) {
                txtUserName.text = "\(firstName) \(lastName)"
            } else {
                txtUserName.text = currentUser.username;
            }
            
            //Avatar
            if let imageUrl = currentUser.imageUrl{
                ImageCachingHandler.Instance.getImageFromUrl(imageUrl, callback: { (image) in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.imgUserAvatar.image = image
                    })
                })
            } else {
                imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
            }
            
            //Location
            if let userLocation = currentUser.locations?.first {
                txtUserLocation.text = userLocation.name
            } else {
                txtUserLocation.text = NSLocalizedString("Location is hidden", comment: "Text, Location is hidden")
            }
            
            //UserStatus: online/ofline
        
            
        } else {
            //Load user default data
            imgUserAvatar.image = ImageCachingHandler.defaultAccountImage;
        }
    }
    

}
