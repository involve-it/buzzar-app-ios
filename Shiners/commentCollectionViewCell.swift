//
//  commentCollectionViewCell.swift
//  Shiners
//
//  Created by Вячеслав on 29/11/2016.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class commentCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var txtTotalInfoFromUser: UILabel!
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userComment: UILabel!
    @IBOutlet weak var btnReport: UIButton!
    @IBOutlet weak var btnLike: LikeButton!
    
    var username: String!
    var commentId: String!
    
    var commentWritten: String!
    
    var likes = 0
    var liked = false
    var loggedIn = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userAvatar.layer.cornerRadius = userAvatar.frame.width / 2
        userAvatar.clipsToBounds = true
        
        /*
        self.btnLike.setImage(UIImage(named: "icon_likes")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.btnLike.tintColor = UIColor(netHex: 0x4A4A4A)
        self.btnLike.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6)
         */
    }
    
    func labelUserInfoConfigure() {
        self.txtTotalInfoFromUser.text = "\(username!) • \(commentWritten!) •"
    }
    
    func setLikes(_ loggedIn: Bool, count: Int, liked: Bool) {
        self.loggedIn = loggedIn
        self.likes = count
        self.liked = liked
        self.updateLikesUi()
    }
    
    func updateLikesUi(){
        if self.loggedIn {
            self.btnLike.isHidden = false
            var title: String
            if liked  {
                self.btnLike.setImage(UIImage(named: "icon_comment")?.withRenderingMode(.alwaysTemplate), for: .normal)
                self.btnLike.tintColor = UIColor(netHex: 0x5EB2E5)
                self.btnLike.titleLabel?.textColor = UIColor(netHex: 0x5EB2E5)
                
                title = NSLocalizedString("Like", comment: "Unlike")
            } else {
                self.btnLike.setImage(UIImage(named: "icon_comment")?.withRenderingMode(.alwaysTemplate), for: .normal)
                self.btnLike.tintColor = UIColor(netHex: 0xAAAAAA)
                self.btnLike.titleLabel?.textColor = UIColor(netHex: 0xAAAAAA)
                
                title = NSLocalizedString("Like", comment: "Like")
            }
            if likes > 0 {
                title += " \(likes)"
            }
            self.btnLike.setTitle(title, for: UIControlState())
        } else {
            self.btnLike.isHidden = true
        }
    }
}
