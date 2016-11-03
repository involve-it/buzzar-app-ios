//
//  MessagesViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class MessagesViewController: UITableViewController, UIViewControllerPreviewingDelegate{
    var dialogs = [Chat]()
    
    private var meteorLoaded = false
    
    var pendingChatId: String?
    var btnDelete: UIBarButtonItem!
    
    @IBAction func unwindMessages(segue: UIStoryboardSegue) {
        //self.navigationController?.popViewControllerAnimated(false)
    }
    
    public override func viewDidLoad() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dialogsUpdated), name: NotificationManager.Name.MyChatsUpdated.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageAdded), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
        if AccountHandler.Instance.status == .Completed {
            self.meteorLoaded = true
            if let dialogs = AccountHandler.Instance.myChats{
                self.dialogs = dialogs
            } else {
                self.dialogs = [Chat]()
            }
        } else {
            if CachingHandler.Instance.status != .Complete {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showOfflineData), name: NotificationManager.Name.OfflineCacheRestored.rawValue, object: nil)
            } else if let dialogs = CachingHandler.Instance.chats {
                self.dialogs = dialogs
            }
        }
        
        if (dialogs.count == 0){
            self.tableView.separatorStyle = .None;
        } else {
            self.tableView.separatorStyle = .SingleLine;
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateDialogs), forControlEvents: .ValueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            self.registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
        self.btnDelete = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.Done, target: self, action: #selector(deleteMessages))
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.editButtonItem().action = #selector(editAction)
        
        if self.dialogs.count > 0{
            self.editButtonItem().enabled = true
        } else {
            self.editButtonItem().enabled = false
        }

        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func editAction(sender: UIBarButtonItem){
        if self.tableView.editing{
            self.tableView.setEditing(false, animated: true)
            self.navigationItem.leftBarButtonItem = nil
            sender.title = "Edit"
        } else {
            self.tableView.setEditing(true, animated: true)
            self.navigationItem.leftBarButtonItem = self.btnDelete
            sender.title = "Done"
        }
    }
    
    func deleteMessages(){
        if let indexPaths = self.tableView.indexPathsForSelectedRows {
            let count = indexPaths.count
            if count > 0 {
                let alertController = UIAlertController(title: NSLocalizedString("Delete Messages", comment: "Delete Messages"), message: NSLocalizedString("Are you sure you want to delete your \(count > 1 ? "\(count) ":"")dialog\(count > 1 ?"s":"")?", comment: "Alert message, Are you sure you want to delete your \(count > 1 ? "\(count) ":"")dialog\(count > 1 ?"s":"")?"), preferredStyle: .ActionSheet);
                alertController.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) in
                    //self.showAlert("Deleted", message: "Deleted")
                    var chatIds = [String]()
                    indexPaths.forEach({ (indexPath) in
                        chatIds.append(self.dialogs[indexPath.row].id!)
                    })
                    ConnectionHandler.Instance.messages.deleteChats(chatIds, callback: { (success, errorId, errorMessage, result) in
                        ThreadHelper.runOnMainThread({
                            if success {
                                chatIds.forEach({ (chatId) in
                                    self.dialogs.removeAtIndex(self.dialogs.indexOf({$0.id == chatId})!)
                                    AccountHandler.Instance.myChats!.removeAtIndex(AccountHandler.Instance.myChats!.indexOf({$0.id == chatId})!)
                                    AccountHandler.Instance.saveMyChats()
                                    NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
                                })
                                
                                if self.dialogs.count == 0{
                                    let allExceptFirst = indexPaths.filter({$0.row != 0})
                                    self.tableView.deleteRowsAtIndexPaths(allExceptFirst, withRowAnimation: .None)
                                    self.tableView.reloadData()
                                } else {
                                    self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                                }
                                self.editAction(self.editButtonItem())
                                AccountHandler.Instance.processLocalNotifications()
                            } else {
                                self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                            }
                        })
                    })
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil));
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func endEditIfDone(count: Int, processedCount: Int, allIndexPaths: [NSIndexPath]){
        if count == processedCount {
            if self.tableView.editing {
                ThreadHelper.runOnMainThread({
                    self.editAction(self.editButtonItem())
                })
            }
            ThreadHelper.runOnMainThread({
                if self.dialogs.count == 0{
                    let allExceptFirst = allIndexPaths.filter({$0.row != 0})
                    self.tableView.deleteRowsAtIndexPaths(allExceptFirst, withRowAnimation: .None)
                    self.tableView.reloadData()
                } else {
                    self.tableView.deleteRowsAtIndexPaths(allIndexPaths, withRowAnimation: .Automatic)
                }
            })
        }
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRowAtPoint(location) else {return nil}
        guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? MessagesTableViewCell else {return nil}
        guard let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("dialog") as? DialogViewController else {return nil}
        
        let chat = dialogs[indexPath.row];
        
        viewController.navigationItem.title = cell.lblTitle.text
        viewController.chat = chat
        viewController.isPeeking = true
        viewController.dataFromCache = false
        if !chat.messagesRequested {
            chat.messagesRequested = true
            viewController.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(chat.id!, skip: 0)
            viewController.dataFromCache = true
        }
        previewingContext.sourceRect = cell.frame
        
        return viewController
    }
    
    public func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.showViewController(viewControllerToCommit, sender: self)
    }
    
    func messageAdded(notification: NSNotification){
        if let message = notification.object as? Message, chatIndex = self.dialogs.indexOf({$0.id == message.chatId}){
            let chat = self.dialogs[chatIndex]
            self.dialogs.removeAtIndex(chatIndex)
            self.dialogs.insert(chat, atIndex: 0)
            
            ThreadHelper.runOnMainThread({
                self.tableView.reloadData()
            })
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.navigationItem.title = NSLocalizedString("Messages", comment: "NavigationItem title, Messages")
        self.refreshControl?.endRefreshing()
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.dialogs.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending(false)
        }
    }
    
    func appDidBecomeActive(){
        if self.dialogs.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending(false)
        }
        self.refreshControl?.endRefreshing()
    }
    
    private func checkPending(stopAfter: Bool){
        if let pendingChatId = self.pendingChatId, chatIndex = self.dialogs.indexOf({$0.id == pendingChatId}){
            self.navigationController?.popToViewController(self, animated: true)
            let indexPath = NSIndexPath(forRow: chatIndex, inSection: 0)
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Bottom)
            self.performSegueWithIdentifier("dialog", sender: self)
            self.pendingChatId = nil
        }
        if stopAfter {
            self.pendingChatId = nil
        }
    }
    
    func showOfflineData(){
        if !self.meteorLoaded{
            if let chats = CachingHandler.Instance.chats{
                self.dialogs = chats
                ThreadHelper.runOnMainThread {
                    self.tableView.separatorStyle = .SingleLine;
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func updateDialogs(){
        AccountHandler.Instance.updateMyChats()
    }
    
    func dialogsUpdated(){
        self.meteorLoaded = true
        if let dialogs = AccountHandler.Instance.myChats{
            self.dialogs = dialogs
        } else {
            self.dialogs = [Chat]()
        }
        ThreadHelper.runOnMainThread {
            self.refreshControl?.endRefreshing()
            self.tableView.separatorStyle = .SingleLine;
            self.tableView.reloadData()
            self.checkPending(true)
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, dialogs.count);
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (dialogs.count == 0){
            if (indexPath.row == 0){
                return self.tableView.dequeueReusableCellWithIdentifier("noMessages")!
            }
        }
        
        let dialog = self.dialogs[indexPath.row]
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("dialog") as! MessagesTableViewCell
        
        cell.lblTitle.text = dialog.otherParty?.username
        cell.lblLastMessage.text = dialog.lastMessage
        if let lastMessageTimeStamp = dialog.lastMessageTimestamp {
            cell.lblDate.text = lastMessageTimeStamp.toFriendlyDateTimeString()
        } else {
            cell.lblDate.text = nil
        }
        
        if (dialog.seen ?? true) || dialog.toUserId != AccountHandler.Instance.userId {
            cell.backgroundColor = UIColor.whiteColor()
        } else {
            cell.backgroundColor = self.tableView.separatorColor
        }
        
        let loading = ImageCachingHandler.Instance.getImageFromUrl(dialog.otherParty?.imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage) { (image) in
            ThreadHelper.runOnMainThread({ 
                if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) as? MessagesTableViewCell{
                    cellToUpdate.imgPhoto?.image = image;
                }
            })
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultAccountImage;
        }
        
        return cell
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "dialog"{
            let selectedCell = self.tableView.cellForRowAtIndexPath(self.tableView.indexPathForSelectedRow!) as! MessagesTableViewCell;
            let chat = self.dialogs[self.tableView.indexPathForSelectedRow!.row]
            
            let viewController = segue.destinationViewController as! DialogViewController
            
            
            //Добавить новое view с информацией о пользователе
            let titleLabel = UILabel(frame: CGRectMake(0, 0, view.frame.width - 32, view.frame.height))
            titleLabel.text = "HOME"
            
            //Main profile view
            let views: UIView = {
                let v = UIView()
                v.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 42)
                return v
            }()
            
            //Profile imageView
            let profileImageView: UIImageView = {
                let imageView = UIImageView()
                imageView.contentMode = .ScaleAspectFill
                imageView.image = selectedCell.imgPhoto.image
                //imageView.backgroundColor = UIColor.redColor()
                imageView.layer.cornerRadius = 15
                imageView.layer.masksToBounds = true
                return imageView
            }()
            
            views.addSubview(profileImageView)
            
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            views.addConstraintsWithFormat("H:|-8-[v0(30)]", views: profileImageView)
            views.addConstraintsWithFormat("V:[v0(30)]", views: profileImageView)
            
            views.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .CenterY, relatedBy: .Equal, toItem: views, attribute: .CenterY, multiplier: 1, constant: 0))
            
            //ContainerView
            let containerView = UIView()
            views.addSubview(containerView)
            
            views.addConstraintsWithFormat("H:|-46-[v0]|", views: containerView)
            views.addConstraintsWithFormat("V:[v0(30)]", views: containerView)
            
            views.addConstraint(NSLayoutConstraint(item: containerView, attribute: .CenterY, relatedBy: .Equal, toItem: views, attribute: .CenterY, multiplier: 1, constant: 0))
            
            //nameLabel
            let nameLabel: UILabel = {
               let label = UILabel()
                label.text = selectedCell.lblTitle.text
                label.font = UIFont.systemFontOfSize(12)
                return label
            }()
            
            //activeTimeLabel
            let activeTimeLabel: UILabel = {
                let label = UILabel()
                if let lastLogin = chat.otherParty?.lastLogin{
                    label.text = lastLogin.toFriendlyLongDateTimeString()
                }
                label.font = UIFont.systemFontOfSize(10)
                label.textColor = UIColor.darkGrayColor()
                return label
            }()
            
            containerView.addSubview(nameLabel)
            containerView.addSubview(activeTimeLabel)
            
            containerView.addConstraintsWithFormat("H:|[v0]|", views: nameLabel)
            containerView.addConstraintsWithFormat("V:|[v0][v1(14)]|", views: nameLabel, activeTimeLabel)
            
            containerView.addConstraintsWithFormat("H:|[v0]-8-|", views: activeTimeLabel)
               
            viewController.navigationItem.titleView = views
            
            //viewController.navigationItem.titleView = titleLabel
            
            
            //WAS HERE
            //viewController.navigationItem.title = selectedCell.lblTitle.text
            
            
            viewController.chat = chat
            viewController.dataFromCache = false
            
            if !chat.messagesRequested {
                if CachingHandler.Instance.status == .Complete, let index = CachingHandler.Instance.chats?.indexOf({$0.id == chat.id}) {
                    let cachedChat = CachingHandler.Instance.chats![index]
                    chat.messages = cachedChat.messages
                    viewController.dataFromCache = true
                }
                chat.messagesRequested = true
                viewController.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(chat.id!, skip: 0)
            }
        }
    }
    
    public override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return !self.tableView.editing
    }
    
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let dialog = self.dialogs[indexPath.row]
            
            ConnectionHandler.Instance.messages.deleteChats([dialog.id!]) { success, errorId, errorMessage, result in
                ThreadHelper.runOnMainThread({ 
                    if success {
                        self.dialogs.removeAtIndex(indexPath.row)
                        AccountHandler.Instance.myChats!.removeAtIndex(AccountHandler.Instance.myChats!.indexOf({$0.id == dialog.id})!)
                        AccountHandler.Instance.saveMyChats()
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        AccountHandler.Instance.processLocalNotifications()
                        NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    }
                })
            }
        }
    }
}
