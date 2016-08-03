//
//  PostsTableViewCell.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class PostsTableViewCell: UITableViewCell{    
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtPrice: UILabel!
    @IBOutlet weak var txtDetails: UILabel!
    
    @IBOutlet weak var txtPostCreated: UILabel!
    @IBOutlet weak var txtPostDistance: UILabel!
    @IBOutlet weak var imgPostType: UIImageView!
    
    //my posts
    @IBOutlet weak var imgViewCountPost: UIImageView!
    @IBOutlet weak var txtViewCountPost: UILabel!
    @IBOutlet weak var imgPostTypeLocation: UIImageView!
    @IBOutlet weak var viewUIPostcategory: UIView!
    @IBOutlet weak var txtPostCategory: UILabel!
    @IBOutlet weak var txtExpiresPostLabel: UILabel!
    @IBOutlet weak var txtExpiresPostCount: UILabel!
    
    @IBOutlet weak var imgSeparatorFromViewCount: UIImageView!
    @IBOutlet weak var imgSeparatorFromViewUI: UIImageView!
    @IBOutlet weak var imgSeparatorFromExpiresPostLabel: UIImageView!
}
