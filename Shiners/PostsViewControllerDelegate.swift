//
//  PostsViewControllerDelegate.swift
//  Shiners
//
//  Created by Yury Dorofeev on 9/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import CoreLocation

protocol PostsViewControllerDelegate {
    func postsUpdated(posts: [Post], currentLocation: CLLocationCoordinate2D?)
    func showPostDetails(_ index: Int)
    func displayLoadingMore()
}
