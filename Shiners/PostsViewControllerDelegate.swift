//
//  PostsViewControllerDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 9/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

protocol PostsViewControllerDelegate {
    func postsUpdated()
    func showPostDetails(index: Int)
    func displayLoadingMore()
}