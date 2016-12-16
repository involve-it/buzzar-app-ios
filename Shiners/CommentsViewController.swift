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
    var imagesCache = NSCache<AnyObject, AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.collectionView!.register(UINib(nibName: "commentCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: commentCellId)
        self.collectionView!.backgroundColor = UIColor.white
        self.collectionView!.delegate = self
        
        if self.loadingComments{
            NotificationCenter.default.addObserver(self, selector: #selector(notifyCommentsLoaded), name: NSNotification.Name(rawValue: NotificationManager.Name.PostCommentsUpdated.rawValue), object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(newCommentReceived), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentAdded.rawValue), object: nil)
        
        
        //self.accessoryView.frame = CGRectMake(0, self.view.frame.height - 43, self.view.frame.width, 43)
        self.accessoryView.setupView(self.view.frame.size.height, parentViewWidth: self.view.frame.size.width, delegate: self)
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
        NotificationCenter.default.addObserver(self, selector: #selector(commentUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(commentRemoved), name: NSNotification.Name(rawValue: NotificationManager.Name.CommentRemoved.rawValue), object: nil)
        if self.post.comments.count > CommentsHandler.DEFAULT_PAGE_SIZE {
            self.post.comments.removeLast()
            self.moreCommentsAvailable = true
        }
    }
    
    func commentRemoved(_ notification: Notification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment, comment.entityId == self.post.id,
                let index = self.post.comments.index(where: {$0.id == comment.id}) {
                self.post.comments.remove(at: index)
                if self.post.comments.count > 1 {
                    self.collectionView!.deleteItems(at: [IndexPath(row: index, section: 0)])
                } else {
                    self.collectionView!.reloadData()
                }
            }
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if AccountHandler.Instance.isLoggedIn() && !self.accessoryView.typing {
            let comment = self.post.comments[indexPath.row]
            let actionController = UIAlertController(title: NSLocalizedString("Comment", comment: "Comment"), message: NSLocalizedString("What would you like to do?", comment: "What would you like to do?"), preferredStyle: .actionSheet)
            var title = NSLocalizedString("Like", comment: "Like")
            if comment.liked ?? false {
                title = NSLocalizedString("Unlike", comment: "Unlike")
            }
            
            actionController.addAction(UIAlertAction(title: title, style: .default, handler: { (action) in
                self.doLike(indexPath.row)
            }))
            
            if comment.userId == AccountHandler.Instance.userId || self.post.user!.id! == AccountHandler.Instance.userId {
                actionController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (action) in
                    if self.isNetworkReachable() {
                        self.doDeleteComment(indexPath.row)
                    }
                }))
            }
            actionController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
            
            self.present(actionController, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
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
                            self.post.comments.append(contentsOf: comments)
                            self.collectionView?.reloadData()
                        })
                    }
                }
            })
        }
    }
    
    func doDeleteComment(_ index: Int){
        let comment = self.post.comments.remove(at: index)
        if self.post.comments.count > 1{
            self.collectionView!.deleteItems(at: [IndexPath(row: index, section: 0)])
        } else {
            self.collectionView!.reloadData()
        }
        ConnectionHandler.Instance.posts.deleteComment(comment.id!) { (success, errorId, errorMessage, result) in
            if !success {
                ThreadHelper.runOnMainThread({ 
                    self.post.comments.insert(comment, at: index)
                    if self.isVisible() {
                        if self.post.comments.count > 1 {
                            self.collectionView!.insertItems(at: [IndexPath(row: index, section: 0)])
                        } else {
                            self.collectionView!.reloadData()
                        }
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                    }
                })
            }
        }
    }
    
    func newCommentReceived(_ notification: Notification){
        ThreadHelper.runOnMainThread({
            if self.isVisible(), let comment = notification.object as? Comment, comment.entityId == self.post.id,
                let index = self.post.comments.index(where: {$0.id == comment.id}) {
                if self.addedLocally.index(of: comment.id!) == nil {
                    if self.post.comments.count == 1{
                        self.collectionView!.reloadData()
                    } else {
                        self.collectionView!.insertItems(at: [IndexPath(row: index, section: 0)])
                    }
                }
            }
        })
    }
    
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func updateInsets(_ height: CGFloat){
        self.collectionView?.contentInset.bottom = height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.addingComment {
            self.accessoryView.txtComment.becomeFirstResponder()
        }
    }
    
    func commentUpdated(_ notification: Notification){
        if let comment = notification.object as? Comment, comment.entityId == self.post.id!, let index = self.post.comments.index(where: {$0.id == comment.id}) {
            ThreadHelper.runOnMainThread({
                self.collectionView!.reloadItems(at: [IndexPath(row: index, section: 0)])
            })
        }
    }
    
    func sendButtonPressed(_ comment: String) {
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
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            let comment = Comment()
            comment.entityId = self.post.id
            comment.text = commentText
            comment.userId = AccountHandler.Instance.userId
            comment.username = AccountHandler.Instance.currentUser!.username
            comment.user = AccountHandler.Instance.currentUser
            comment.timestamp = Date()
            
            ConnectionHandler.Instance.posts.addComment(comment, callback: { (success, errorId, errorMessage, result) in
                if self.isVisible() {
                    ThreadHelper.runOnMainThread({
                        self.setLoading(false)
                        self.accessoryView.setSendButtonEnabled(true)
                        if success {
                            self.accessoryView.clearMessageText()
                            comment.id = result as? String
                            
                            if self.post.comments.index(where: {$0.id == comment.id}) == nil {
                                self.addedLocally.append(comment.id!)
                                self.post.comments.insert(comment, at: 0)
                                if self.isVisible() {
                                    if self.post.comments.count == 1 {
                                        self.collectionView!.reloadData()
                                    } else {
                                        self.collectionView?.insertItems(at: [IndexPath(row: 0, section: 0)])
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
            NotificationCenter.default.addObserver(self, selector: #selector(doComment), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
    
    func notifyCommentsLoaded(_ notification: Notification){
        if let postId = notification.object as? String, postId == self.post.id! {
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
    
    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.navigationController!.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !self.loadingComments {
            if post.comments.count == 0{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCommentMessage", for: indexPath) as! CommentCollectionViewMessageCell
                cell.lblMessage.text = NSLocalizedString("There are no comments to this post", comment: "There are no comments to this post")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: commentCellId, for: indexPath) as! commentCollectionViewCell
                
                cell.userAvatar.backgroundColor = UIColor(netHex: 0x8F8E94)
                cell.userAvatar.image = ImageCachingHandler.defaultAccountImage
                
                let comment = self.post.comments[indexPath.row]
                cell.userComment.text = comment.text
                cell.username = comment.username!
                cell.commentWritten = JSQMessagesTimestampFormatter.shared().timestamp(for: comment.timestamp! as Date!)
                cell.labelUserInfoConfigure()
                cell.commentId = comment.id!
                cell.btnLike.commentId = comment.id!
                cell.btnLike.removeTarget(self, action: #selector(self.btnLike_Click(_:)), for: .touchUpInside)
                cell.btnLike.addTarget(self, action: #selector(self.btnLike_Click(_:)), for: .touchUpInside)
                cell.setLikes(AccountHandler.Instance.isLoggedIn(), count: comment.likes ?? 0, liked: comment.liked ?? false)
                if let user = comment.user, let url = user.imageUrl {
                    if let cachedImage = self.imagesCache.object(forKey: url as AnyObject) as? UIImage {
                        cell.userAvatar.image = cachedImage
                    } else {
                        ImageCachingHandler.Instance.getImageFromUrl(url, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                            if let img = image, img != ImageCachingHandler.defaultAccountImage {
                                ThreadHelper.runOnBackgroundThread({
                                    let newImage = img.resizeImage(200, maxHeight: 200, quality: 0.4)
                                    self.imagesCache.setObject(newImage, forKey: url as AnyObject)
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellCommentMessage", for: indexPath) as! CommentCollectionViewMessageCell
            cell.lblMessage.text = NSLocalizedString("Loading comments", comment: "Loading comments")
            return cell
        }
        
    }
    
    func btnLike_Click(_ sender: LikeButton){
        if self.isNetworkReachable(), let row = self.post.comments.index(where: {$0.id == sender.commentId}){
            self.doLike(row)
        }
    }
    
    func doLike(_ index: Int){
        let comment = self.post.comments[index]
        if comment.liked ?? false {
            comment.liked = false
            comment.likes = (comment.likes ?? 0) - 1
            
            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            
            ConnectionHandler.Instance.posts.unlikeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = true
                    comment.likes = (comment.likes ?? 0) + 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible() {
                            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        } else {
            comment.liked = true
            comment.likes = (comment.likes ?? 0) + 1
            
            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            
            ConnectionHandler.Instance.posts.likeComment(comment.id!) { (success, errorId, errorMessage, result) in
                if !success {
                    comment.liked = false
                    comment.likes = (comment.likes ?? 0) - 1
                    ThreadHelper.runOnMainThread({
                        if self.isVisible(){
                            self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                            self.showAlert(NSLocalizedString("Error", comment: "Alert title, error"), message: NSLocalizedString("An error occurred.", comment: "An error occurred."))
                        }
                    })
                }
            }
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !self.loadingComments {
            return max(1, self.post.comments.count)
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        if self.post.comments.count > 0 {
            let comment = self.post.comments[indexPath.row]
            let size = CGSize(width: collectionView.frame.width - 60 - 16, height: 1000)
            let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
            
            let estimatedRect = NSString(string: comment.text!).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)], context: nil)
            
            let newSize = CGSize(width: collectionView.frame.width - 16, height: max(estimatedRect.height, 40) + 20)
            
            return newSize
        }
        else {
            return CGSize(width: collectionView.frame.width, height: 44)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
}
