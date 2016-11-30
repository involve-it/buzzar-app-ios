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
    
    var username: String {
        get {
            return "username"
        }
    }
    
    var commentWritten: String {
        get {
            return "1 hour ago"
        }
    }
    
    class func fromNib() -> commentCollectionViewCell? {
        var cell: commentCollectionViewCell?
        let nibViews = NSBundle.mainBundle().loadNibNamed("commentCollectionViewCell", owner: nil, options: nil)
        for nibView in nibViews {
            if let cellView = nibView as? commentCollectionViewCell {
                cell = cellView
            }
        }
        return cell
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        userAvatar.layer.cornerRadius = userAvatar.frame.width / 2
        userAvatar.clipsToBounds = true
        
        labelUserInfoConfigure()
    }
    
    func labelUserInfoConfigure() {
        self.txtTotalInfoFromUser.text = "\(username) • \(commentWritten)"
    }
}

//•