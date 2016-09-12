//
//  BeginnerViewController.swift
//  Shiners
//
//  Created by Вячеслав on 9/9/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

class BeginnerViewController: UIViewController {
    
    @IBOutlet weak var typeSwitch: UISegmentedControl!
    @IBOutlet var contentView: UIView!
    
    var currentViewController: UIViewController?
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    //Identifier postStyle
    lazy var listIdentifier: UIViewController? = {
        let list = self.storyBoard.instantiateViewControllerWithIdentifier("postsViewController")
        return list
    }()
    //Identifier mapStyle
    lazy var mapIdentifier: UIViewController? = {
        let map = self.storyBoard.instantiateViewControllerWithIdentifier("mapViewControllerForPosts")
        return map
    }()
    
    enum PostsViewType: Int {
        case list = 0
        case Map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set index for segment
        self.typeSwitch.selectedSegmentIndex = PostsViewType.list.rawValue
        // Load viewController
        self.loadCurrentViewController(self.typeSwitch.selectedSegmentIndex)
        
        //conf. LeftMenu
        self.configureOfLeftMenu()
        self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let currentViewController = currentViewController {
            currentViewController.viewWillDisappear(animated)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadCurrentViewController(index: Int) {
        if let vc = viewControllerForSelectedSegmentIndex(index) {
            self.addChildViewController(vc)
            vc.didMoveToParentViewController(self)
            
            vc.view.frame = self.contentView.bounds
            self.contentView.addSubview(vc.view)
            self.currentViewController = vc
        }
    }
    
    func viewControllerForSelectedSegmentIndex(index: Int) -> UIViewController? {
        var vc: UIViewController?
        let index = PostsViewType(rawValue: self.typeSwitch.selectedSegmentIndex)
        switch index! {
        case .list: vc = self.listIdentifier
        case .Map: vc = self.mapIdentifier
        }
        
        return vc
    }
    
    @IBAction func postsViewTypeChanged(sender: UISegmentedControl) {
        self.currentViewController!.view.removeFromSuperview()
        self.currentViewController!.removeFromParentViewController()
        loadCurrentViewController(sender.selectedSegmentIndex)
    }
    
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
