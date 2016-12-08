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
    }
    
    func labelUserInfoConfigure() {
        self.txtTotalInfoFromUser.text = "\(username) • \(commentWritten)"
    }
    
    func setLikes(loggedIn: Bool, count: Int, liked: Bool) {
        self.loggedIn = loggedIn
        self.likes = count
        self.liked = liked
        self.updateLikesUi()
    }
    
    func updateLikesUi(){
        if self.loggedIn {
            self.btnLike.hidden = false
            var title: String
            if liked  {
                title = NSLocalizedString("Unlike", comment: "Unlike")
            } else {
                title = NSLocalizedString("Like", comment: "Like")
            }
            if likes > 0 {
                title += " (\(likes))"
            }
            self.btnLike.setTitle(title, forState: .Normal)
        } else {
            self.btnLike.hidden = true
        }
    }
}