//
//  NewSearchViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/3/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class NewSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    public var delegate: SearchViewControllerDelegate?
    
    @IBOutlet weak var tblSearchResults: UITableView!
    
    public override func viewDidLoad() {
        self.tblSearchResults.delegate = self
        self.tblSearchResults.dataSource = self
    }
    
    func forceLayout(){
        
        
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("testCell")!
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    public func setContentInset(navigationController: UINavigationController, tabBarController: UITabBarController){
        self.tblSearchResults.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.height + navigationController.navigationBar.frame.height, 0, tabBarController.tabBar.frame.height, 0)
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.didApplyFilter()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

public protocol SearchViewControllerDelegate {
    func didApplyFilter()
}
