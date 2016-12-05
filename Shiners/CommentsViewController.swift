//
//  CommentsViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 12/3/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController

let commentCellId = "cellComment"

class CommentsViewController: UICollectionViewController, UITextViewDelegate, AddCommentDelegate {
    var post: Post!
    var loadingComments = false
    
    @IBOutlet var accessoryView: AddCommentView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.collectionView!.registerNib(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        self.collectionView!.delegate = self
        
        if self.loadingComments{
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notifyCommentsLoaded), name: NotificationManager.Name.PostCommentsUpdated.rawValue, object: nil)
        }
        
        self.accessoryView.frame = CGRectMake(0, self.view.frame.height - 43, self.view.frame.width, 43)
        self.accessoryView.setupView(self.view.frame.size.height, delegate: self)
        self.view.addSubview(self.accessoryView)
        
        if !AccountHandler.Instance.isLoggedIn() {
            self.accessoryView.lblPlaceholder.text = NSLocalizedString("Please log in to comment", comment: "Please log in to comment")
            self.accessoryView.enableControls(false)
        }
        self.collectionView?.alwaysBounceVertical = true
    }
    
    func updateInsets(height: CGFloat){
        self.collectionView?.contentInset.bottom = height
        
    }
    
    func sendButtonPressed(comment: String) {
        if comment == "" || !self.isNetworkReachable() || !AccountHandler.Instance.isLoggedIn() {
            return
        }
        
        self.setLoading(true)
        self.accessoryView.setSendButtonEnabled(false)
        self.doComment(comment)
    }
    
    func doComment(commentText: String){
        if ConnectionHandler.Instance.isConnected() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            let comment = Comment()
            comment.entityId = self.post.id
            comment.text = commentText
            comment.userId = AccountHandler.Instance.userId
            comment.username = AccountHandler.Instance.currentUser!.username
            comment.user = AccountHandler.Instance.currentUser
            
            ConnectionHandler.Instance.posts.addComment(comment, callback: { (success, errorId, errorMessage, result) in
                ThreadHelper.runOnMainThread({ 
                    self.setLoading(false)
                    self.accessoryView.setSendButtonEnabled(true)
                    if success {
                        self.accessoryView.clearMessageText()
                        self.post.comments.append(comment)
                        self.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: self.post.comments.count - 1, inSection: 0)])
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    }
                })
            })
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(doComment), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.post.comments.count > 0 {
            self.collectionView!.scrollToItemAtIndexPath(NSIndexPath(forRow: self.post.comments.count - 1, inSection: 0), atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func notifyCommentsLoaded(notification: NSNotification){
        if let postId = notification.object as? String where postId == self.post.id! {
            self.loadingComments = false
            ThreadHelper.runOnMainThread { 
                self.collectionView!.reloadData()
            }
        }
    }
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if !self.loadingComments {
            if post.comments.count == 0{
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCommentMessage", forIndexPath: indexPath) as! CommentCollectionViewMessageCell
                cell.lblMessage.text = NSLocalizedString("There are no comments to this post", comment: "There are no comments to this post")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(commentCellId, forIndexPath: indexPath) as! commentCollectionViewCell
                
                cell.userAvatar.backgroundColor = UIColor(netHex: 0x8F8E94)
                cell.userAvatar.image = ImageCachingHandler.defaultAccountImage
                
                let comment = self.post.comments[indexPath.row]
                cell.userComment.text = comment.text
                cell.username = comment.username!
                cell.commentWritten = JSQMessagesTimestampFormatter.sharedFormatter().timestampForDate(comment.timestamp!)
                cell.labelUserInfoConfigure()
                if let user = comment.user {
                    ImageCachingHandler.Instance.getImageFromUrl(user.imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                        ThreadHelper.runOnMainThread({ 
                            if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? commentCollectionViewCell {
                                cell.userAvatar.image = image
                            }
                        })
                    })
                }
                
                //let ss = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                
                cell.contentView.setNeedsLayout()
                cell.contentView.layoutIfNeeded()
                
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCommentMessage", forIndexPath: indexPath) as! CommentCollectionViewMessageCell
            cell.lblMessage.text = NSLocalizedString("Loading comments", comment: "Loading comments")
            return cell
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !self.loadingComments {
            return max(1, self.post.comments.count)
        } else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if let cell = commentCollectionViewCell.fromNib() {
            if self.post.comments.count > 0 {
                let comment = self.post.comments[indexPath.row]
                let size = CGSizeMake(collectionView.frame.width - 60 - 16, 1000)
                let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
                
                let estimatedRect = NSString(string: comment.text!).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13)], context: nil)
                
                let newSize = CGSize(width: collectionView.frame.width - 16, height: max(estimatedRect.height, cell.userAvatar.frame.size.height) + 20)
                
                return newSize
            }
            else {
                return CGSize(width: collectionView.frame.width, height: 44)
            }
        }
        
        return CGSize(width: collectionView.frame.width, height: 44)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
}