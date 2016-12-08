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

class CommentsViewController: UICollectionViewController, AddCommentDelegate {
    var post: Post!
    var loadingComments = false
    var addingComment = false
    var addedLocally = [String]()
    var typing = false
    var moreCommentsAvailable = false
    var loadingMore = false
    
    @IBOutlet var accessoryView: AddCommentView!
    var imagesCache = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.collectionView!.registerNib(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        self.collectionView!.backgroundColor = UIColor.whiteColor()
        self.collectionView!.delegate = self
        
        if self.loadingComments{
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(notifyCommentsLoaded), name: NotificationManager.Name.PostCommentsUpdated.rawValue, object: nil)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(newCommentReceived), name: NotificationManager.Name.PostCommentAddedLocally.rawValue, object: nil)
        
        self.accessoryView.frame = CGRectMake(0, self.view.frame.height - 43, self.view.frame.width, 43)
        self.accessoryView.setupView(self.view.frame.size.height, delegate: self)
        self.view.addSubview(self.accessoryView)
        
        if !AccountHandler.Instance.isLoggedIn() {
            self.accessoryView.lblPlaceholder.text = NSLocalizedString("Please log in to comment", comment: "Please log in to comment")
            self.accessoryView.enableControls(false)
        }
        self.collectionView!.alwaysBounceVertical = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        self.collectionView!.addGestureRecognizer(gestureRecognizer)
        self.collectionView!.allowsSelection = true
            //AccountHandler.Instance.isLoggedIn()
        self.updateInsets(self.accessoryView.frame.height)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentUpdated), name: NotificationManager.Name.CommentUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(commentRemoved), name: NotificationManager.Name.CommentRemoved.rawValue, object: nil)
        if self.post.comments.count > CommentsHandler.DEFAULT_PAGE_SIZE {
            self.post.comments.removeLast()
            self.moreCommentsAvailable = true
        }
    }
    
    func commentRemoved(notification: NSNotification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment where comment.entityId == self.post.id,
                let index = self.post.comments.indexOf({$0.id == comment.id}) {
                if self.post.comments.count > 1 {
                    self.collectionView!.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                } else {
                    self.collectionView!.reloadData()
                }
            }
        })
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        if AccountHandler.Instance.isLoggedIn() && !self.accessoryView.typing {
            let comment = self.post.comments[indexPath.row]
            let actionController = UIAlertController(title: NSLocalizedString("Comment", comment: "Comment"), message: NSLocalizedString("What would you like to do?", comment: "What would you like to do?"), preferredStyle: .ActionSheet)
            var title = NSLocalizedString("Like", comment: "Like")
            if comment.liked ?? false {
                title = NSLocalizedString("Unlike", comment: "Unlike")
            }
            
            actionController.addAction(UIAlertAction(title: title, style: .Default, handler: { (action) in
                self.doLike(indexPath.row)
            }))
            
            if comment.userId == AccountHandler.Instance.userId || self.post.user!.id! == AccountHandler.Instance.userId {
                actionController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .Destructive, handler: { (action) in
                    if self.isNetworkReachable() {
                        self.doDeleteComment(indexPath.row)
                    }
                }))
            }
            actionController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil))
            
            self.presentViewController(actionController, animated: true, completion: nil)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if Float(indexPath.row) > (Float(CommentsHandler.DEFAULT_PAGE_SIZE) / 1.5) && self.moreCommentsAvailable && !self.loadingMore && ConnectionHandler.Instance.isNetworkConnected() {
            self.loadingMore = true
            ConnectionHandler.Instance.posts.getComments(self.post.id!, skip: self.post.comments.count, take: CommentsHandler.DEFAULT_PAGE_SIZE + 1, callback: { (success, errorId, errorMessage, result) in
                self.loadingMore = false
                if success {
                    if var comments = result as? [Comment] {
                        if comments.count > CommentsHandler.DEFAULT_PAGE_SIZE {
                            comments.removeLast()
                            self.moreCommentsAvailable = true
                        } else {
                            self.moreCommentsAvailable = false
                        }
                        ThreadHelper.runOnMainThread({ 
                            self.post.comments.appendContentsOf(comments)
                            self.collectionView?.reloadData()
                        })
                    }
                }
            })
        }
    }
    
    func doDeleteComment(index: Int){
        let comment = self.post.comments.removeAtIndex(index)
        if self.post.comments.count > 1{
            self.collectionView!.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
        } else {
            self.collectionView!.reloadData()
        }
        ConnectionHandler.Instance.posts.deleteComment(comment.id!) { (success, errorId, errorMessage, result) in
            if !success {
                ThreadHelper.runOnMainThread({ 
                    self.post.comments.insert(comment, atIndex: index)
                    if self.isVisible() {
                        if self.post.comments.count > 1 {
                            self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                        } else {
                            self.collectionView!.reloadData()
                        }
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                    }
                })
            }
        }
    }
    
    func newCommentReceived(notification: NSNotification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment where comment.entityId == self.post.id,
                let index = self.post.comments.indexOf({$0.id == comment.id}) {
                if self.addedLocally.indexOf(comment.id!) == nil {
                    if self.post.comments.count == 1{
                        self.collectionView!.reloadData()
                    } else {
                        self.collectionView!.insertItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                    }
                }
            }
        })
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func updateInsets(height: CGFloat){
        self.collectionView?.contentInset.bottom = height
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.addingComment {
            self.accessoryView.txtComment.becomeFirstResponder()
        }
    }
    
    func commentUpdated(notification: NSNotification){
        if let comment = notification.object as? Comment where comment.entityId == self.post.id!, let index = self.post.comments.indexOf({$0.id == comment.id}) {
            ThreadHelper.runOnMainThread({
                self.collectionView!.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            })
        }
    }
    
    func sendButtonPressed(comment: String) {
        if comment == "" || !self.isNetworkReachable() || !AccountHandler.Instance.isLoggedIn() {
            return
        }
        
        self.setLoading(true)
        self.accessoryView.setSendButtonEnabled(false)
        self.doComment()
    }
    
    func doComment(){
        let commentText = self.accessoryView.txtComment.text
        if ConnectionHandler.Instance.isConnected() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
            let comment = Comment()
            comment.entityId = self.post.id
            comment.text = commentText
            comment.userId = AccountHandler.Instance.userId
            comment.username = AccountHandler.Instance.currentUser!.username
            comment.user = AccountHandler.Instance.currentUser
            comment.timestamp = NSDate()
            
            ConnectionHandler.Instance.posts.addComment(comment, callback: { (success, errorId, errorMessage, result) in
                if self.isVisible() {
                    ThreadHelper.runOnMainThread({
                        self.setLoading(false)
                        self.accessoryView.setSendButtonEnabled(true)
                        if success {
                            self.accessoryView.clearMessageText()
                            comment.id = result as? String
                            
                            if self.post.comments.indexOf({$0.id == comment.id}) == nil {
                                self.addedLocally.append(comment.id!)
                                self.post.comments.insert(comment, atIndex: 0)
                                if self.isVisible() {
                                    if self.post.comments.count == 1 {
                                        self.collectionView!.reloadData()
                                    } else {
                                        self.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
                                    }
                                }
                            }
                        } else {
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                        }
                    })
                }
            })
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(doComment), name: NotificationManager.Name.MeteorConnected.rawValue, object: nil)
        }
    }
    
    func notifyCommentsLoaded(notification: NSNotification){
        if let postId = notification.object as? String where postId == self.post.id! {
            self.loadingComments = false
            if self.post.comments.count > CommentsHandler.DEFAULT_PAGE_SIZE {
                self.post.comments.removeLast()
                self.moreCommentsAvailable = true
            }
            ThreadHelper.runOnMainThread { 
                self.collectionView!.reloadData()
            }
        }
    }
    
    @IBAction func btnCancel_Click(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
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
                cell.commentId = comment.id!
                cell.btnLike.commentId = comment.id!
                cell.btnLike.removeTarget(self, action: #selector(self.btnLike_Click(_:)), forControlEvents: .TouchUpInside)
                cell.btnLike.addTarget(self, action: #selector(self.btnLike_Click(_:)), forControlEvents: .TouchUpInside)
                cell.setLikes(AccountHandler.Instance.isLoggedIn(), count: comment.likes ?? 0, liked: comment.liked ?? false)
                if let user = comment.user, url = user.imageUrl {
                    if let cachedImage = self.imagesCache.objectForKey(url) as? UIImage {
                        cell.userAvatar.image = cachedImage
                    } else {
                        ImageCachingHandler.Instance.getImageFromUrl(url, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                            if let img = image where img != ImageCachingHandler.defaultAccountImage {
                                ThreadHelper.runOnBackgroundThread({
                                    let newImage = img.resizeImage(200, maxHeight: 200, quality: 0.4)
                                    self.imagesCache.setObject(newImage, forKey: url)
                                    ThreadHelper.runOnMainThread({ 
                                        cell.userAvatar.image = newImage
                                    })
                                })
                            }
                        })
                    }
                }
                
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cellCommentMessage", forIndexPath: indexPath) as! CommentCollectionViewMessageCell
            cell.lblMessage.text = NSLocalizedString("Loading comments", comment: "Loading comments")
            return cell
        }
        
    }
    
    func btnLike_Click(sender: LikeButton){
        if self.isNetworkReachable(), let row = self.post.comments.indexOf({$0.id == sender.commentId}){
            self.doLike(row)
        }
    }
    
    func doLike(index: Int){
        let comment = self.post.comments[index]
        if comment.liked ?? false {
            comment.liked = false
            comment.likes = (comment.likes ?? 0) - 1
            
            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            
            ConnectionHandler.Instance.posts.unlikeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = true
                    comment.likes = (comment.likes ?? 0) + 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible() {
                            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        } else {
            comment.liked = true
            comment.likes = (comment.likes ?? 0) + 1
            
            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            
            ConnectionHandler.Instance.posts.likeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = false
                    comment.likes = (comment.likes ?? 0) - 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible(){
                            self.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
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
        if self.post.comments.count > 0 {
            let comment = self.post.comments[indexPath.row]
            let size = CGSizeMake(collectionView.frame.width - 60 - 16, 1000)
            let options = NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin)
            
            let estimatedRect = NSString(string: comment.text!).boundingRectWithSize(size, options: options, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(13)], context: nil)
            
            let newSize = CGSize(width: collectionView.frame.width - 16, height: max(estimatedRect.height, 40) + 20)
            
            return newSize
        }
        else {
            return CGSize(width: collectionView.frame.width, height: 44)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
}