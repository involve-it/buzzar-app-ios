//
//  NewSearchViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/3/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class NewSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    open var delegate: SearchViewControllerDelegate?
    
    @IBOutlet weak var tblSearchResults: UITableView!
    
    open override func viewDidLoad() {
        self.tblSearchResults.delegate = self
        self.tblSearchResults.dataSource = self
    }
    
    func forceLayout(){
        
        
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "testCell")!
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    open func setContentInset(_ navigationController: UINavigationController, tabBarController: UITabBarController){
        self.tblSearchResults.contentInset = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height, 0, tabBarController.tabBar.frame.height, 0)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didApplyFilter()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

public protocol SearchViewControllerDelegate {
    func didApplyFilter()
}
