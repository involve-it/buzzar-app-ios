//
//  PostDetailsViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/23/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class PostDetailsViewController: UITableViewController{
    @IBOutlet weak var svImages: UIScrollView!
    
    public var post: Post!;
    private var imagesScrollViewDelegate:ImagesScrollViewDelegate!;
    @IBOutlet weak var txtDetails: UILabel!
    @IBOutlet weak var txtViews: UILabel!
    @IBOutlet var btnEdit: UIBarButtonItem!
    
    @IBAction func btnShare_Click(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: ["Check out this post: http://msg.webhop.org/post/\(self.post.id!)", NSURL(string: "http://msg.webhop.org/post/\(self.post.id!)")!], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeOpenInIBooks, UIActivityTypeSaveToCameraRoll];
        navigationController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
    public override func viewDidLoad() {
        self.navigationItem.title = post?.title;
        self.txtDetails.text = post?.descr;
        self.txtDetails.sizeToFit();
        var views = "";
        if let seenTotal = post?.seenTotal{
            views+="All: \(seenTotal)";
        }
        if let seenToday = post?.seenToday{
            views+=" Today: \(seenToday)";
        }
        self.txtViews.text = views;
        
        if (self.imagesScrollViewDelegate == nil){
            self.imagesScrollViewDelegate = ImagesScrollViewDelegate(mainView: self.view, scrollView: self.svImages, viewController: self);
        }
        self.updateScrollView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateScrollView), name: UIDeviceOrientationDidChangeNotification, object: nil)
        if let index = self.navigationItem.rightBarButtonItems?.indexOf(self.btnEdit){
            self.navigationItem.rightBarButtonItems?.removeAtIndex(index)
        }
        if self.post?.user?.id == AccountHandler.Instance.currentUser?.id {
            self.navigationItem.rightBarButtonItems?.append(self.btnEdit)
        }
    }
    
    func updateScrollView(){
        let urls = post?.photos?.filter({ $0.original != nil }).map({ $0.original! });
        self.imagesScrollViewDelegate.setupScrollView(urls);
    }
    
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0){
            return 261;
        } else if (indexPath.row == 1){
            if (txtViews.text?.characters.count > 0){
                return 44;
            } else {
                return 0;
            }
        } else if (indexPath.row == 2){
            if let height = post?.descr?.heightWithConstrainedWidth(self.view.frame.width - 16, font: self.txtDetails.font){
                return max(height, 44);
            } else {
                return 0
            }
        } else {
            return 44;
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editPost"{
            let vc = segue.destinationViewController as! UINavigationController
            let createVc = vc.viewControllers[0] as! NewPostViewController
            createVc.post = self.post
        }
    }
}
