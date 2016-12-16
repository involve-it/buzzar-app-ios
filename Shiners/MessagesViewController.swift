//
//  MessagesViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

open class MessagesViewController: UITableViewController, UIViewControllerPreviewingDelegate{
    var dialogs = [Chat]()
    
    fileprivate var meteorLoaded = false
    
    var pendingChatId: String?
    var btnDelete: UIBarButtonItem!
    
    @IBAction func unwindMessages(_ segue: UIStoryboardSegue) {
        //self.navigationController?.popViewControllerAnimated(false)
    }
    
    open override func viewDidLoad() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(dialogsUpdated), name: NSNotification.Name(rawValue: NotificationManager.Name.MyChatsUpdated.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageAdded), name: NSNotification.Name(rawValue: NotificationManager.Name.MessageAdded.rawValue), object: nil)
        if AccountHandler.Instance.status == .completed {
            self.meteorLoaded = true
            if let dialogs = AccountHandler.Instance.myChats{
                self.dialogs = dialogs
            } else {
                self.dialogs = [Chat]()
            }
        } else {
            if CachingHandler.Instance.status != .complete {
                NotificationCenter.default.addObserver(self, selector: #selector(showOfflineData), name: NSNotification.Name(rawValue: NotificationManager.Name.OfflineCacheRestored.rawValue), object: nil)
            } else if let dialogs = CachingHandler.Instance.chats {
                self.dialogs = dialogs
            }
        }
        
        if (dialogs.count == 0){
            self.tableView.separatorStyle = .none;
        } else {
            self.tableView.separatorStyle = .singleLine;
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(updateDialogs), for: .valueChanged)
        
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            self.registerForPreviewing(with: self, sourceView: view)
        }
        
        self.btnDelete = UIBarButtonItem(title: NSLocalizedString("Delete", comment: "Delete"), style: UIBarButtonItemStyle.done, target: self, action: #selector(deleteMessages))
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.editButtonItem.action = #selector(editAction)
        
        if self.dialogs.count > 0{
            self.editButtonItem.isEnabled = true
        } else {
            self.editButtonItem.isEnabled = false
        }
        
        //conf. LeftMenu
        //self.configureOfLeftMenu()
        //self.addLeftBarButtonWithImage(UIImage(named: "menu_black_24dp")!)
    }
    
    func editAction(_ sender: UIBarButtonItem){
        AppAnalytics.logEvent(.MessagesScreen_BtnEdit_Click)
        if self.tableView.isEditing{
            self.tableView.setEditing(false, animated: true)
            self.navigationItem.rightBarButtonItem = nil
            sender.title = NSLocalizedString("Edit", comment: "Edit")
        } else {
            self.tableView.setEditing(true, animated: true)
            self.navigationItem.rightBarButtonItem = self.btnDelete
            sender.title = NSLocalizedString("Done", comment: "Done")
        }
    }
    
    func deleteMessages(){
        AppAnalytics.logEvent(.MessagesScreen_BtnDelete_Clicked)
        if let indexPaths = self.tableView.indexPathsForSelectedRows {
            let count = indexPaths.count
            if count > 0 {
                let alertController = UIAlertController(title: NSLocalizedString("Delete Messages", comment: "Delete Messages"), message: NSLocalizedString("Are you sure you want to delete selected dialog(s)?", comment: "Alert message, Are you sure you want to delete selected dialogs?"), preferredStyle: .actionSheet);
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (action) in
                    //self.showAlert("Deleted", message: "Deleted")
                    var chatIds = [String]()
                    indexPaths.forEach({ (indexPath) in
                        chatIds.append(self.dialogs[indexPath.row].id!)
                    })
                    ConnectionHandler.Instance.messages.deleteChats(chatIds, callback: { (success, errorId, errorMessage, result) in
                        ThreadHelper.runOnMainThread({
                            if success {
                                chatIds.forEach({ (chatId) in
                                    self.dialogs.remove(at: self.dialogs.index(where: {$0.id == chatId})!)
                                    AccountHandler.Instance.myChats!.remove(at: AccountHandler.Instance.myChats!.index(where: {$0.id == chatId})!)
                                    LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: chatId)
                                })
                                AccountHandler.Instance.saveMyChats()
                                NotificationManager.sendNotification(NotificationManager.Name.MyChatsUpdated, object: nil)
                                
                                if self.dialogs.count == 0{
                                    let allExceptFirst = indexPaths.filter({$0.row != 0})
                                    self.tableView.deleteRows(at: allExceptFirst, with: .none)
                                    self.tableView.reloadData()
                                } else {
                                    self.tableView.deleteRows(at: indexPaths, with: .automatic)
                                }
                                self.editAction(self.editButtonItem)
                                AccountHandler.Instance.processLocalNotifications()
                            } else {
                                self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                            }
                        })
                    })
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil));
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func endEditIfDone(_ count: Int, processedCount: Int, allIndexPaths: [IndexPath]){
        if count == processedCount {
            if self.tableView.isEditing {
                ThreadHelper.runOnMainThread({
                    self.editAction(self.editButtonItem)
                })
            }
            ThreadHelper.runOnMainThread({
                if self.dialogs.count == 0{
                    let allExceptFirst = allIndexPaths.filter({$0.row != 0})
                    self.tableView.deleteRows(at: allExceptFirst, with: .none)
                    self.tableView.reloadData()
                } else {
                    self.tableView.deleteRows(at: allIndexPaths, with: .automatic)
                }
            })
        }
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else {return nil}
        guard let cell = self.tableView.cellForRow(at: indexPath) as? MessagesTableViewCell else {return nil}
        guard let viewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "dialog") as? DialogViewController else {return nil}
        
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
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.show(viewControllerToCommit, sender: self)
    }
    
    func messageAdded(_ notification: Notification){
        if let message = notification.object as? Message, let chatIndex = self.dialogs.index(where: {$0.id == message.chatId}){
            let chat = self.dialogs[chatIndex]
            self.dialogs.remove(at: chatIndex)
            self.dialogs.insert(chat, at: 0)
            
            ThreadHelper.runOnMainThread({
                self.tableView.reloadData()
            })
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.navigationItem.title = NSLocalizedString("Messages", comment: "NavigationItem title, Messages")
        self.refreshControl?.endRefreshing()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.dialogs.count > 0 && AccountHandler.Instance.status == .completed{
            self.checkPending(false)
        }
    }
    
    func appDidBecomeActive(){
        if self.dialogs.count > 0 && AccountHandler.Instance.status == .completed{
            self.checkPending(false)
        }
        self.refreshControl?.endRefreshing()
    }
    
    fileprivate func checkPending(_ stopAfter: Bool){
        if let pendingChatId = self.pendingChatId, let chatIndex = self.dialogs.index(where: {$0.id == pendingChatId}){
            //self.navigationController?.popToViewController(self, animated: true)
            let indexPath = IndexPath(row: chatIndex, section: 0)
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
            self.performSegue(withIdentifier: "dialog", sender: self)
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
                    self.tableView.separatorStyle = .singleLine;
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
            self.tableView.separatorStyle = .singleLine;
            self.tableView.reloadData()
            if self.dialogs.count > 0{
                self.editButtonItem.isEnabled = true
            } else {
                self.editButtonItem.isEnabled = false
            }
            self.checkPending(true)
        }
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, dialogs.count);
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (dialogs.count == 0){
            if (indexPath.row == 0){
                return self.tableView.dequeueReusableCell(withIdentifier: "noMessages")!
            }
        }
        
        let dialog = self.dialogs[indexPath.row]
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "dialog") as! MessagesTableViewCell
        
        cell.lblTitle.text = dialog.otherParty?.username
        cell.lblLastMessage.text = dialog.lastMessage
        if let lastMessageTimeStamp = dialog.lastMessageTimestamp {
            cell.lblDate.text = lastMessageTimeStamp.toFriendlyDateTimeString()
        } else {
            cell.lblDate.text = nil
        }
        
        if (dialog.seen ?? true) || dialog.toUserId != AccountHandler.Instance.userId {
            cell.backgroundColor = UIColor.white
        } else {
            cell.backgroundColor = self.tableView.separatorColor
        }
        
        let loading = ImageCachingHandler.Instance.getImageFromUrl(dialog.otherParty?.imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage) { (image) in
            ThreadHelper.runOnMainThread({ 
                if let cellToUpdate = tableView.cellForRow(at: indexPath) as? MessagesTableViewCell{
                    cellToUpdate.imgPhoto?.image = image;
                }
            })
        }
        if loading {
            cell.imgPhoto?.image = ImageCachingHandler.defaultAccountImage;
        }
        
        return cell
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dialog"{
            AppAnalytics.logEvent(.MessagesScreen_DialogSelected)
            let selectedCell = self.tableView.cellForRow(at: self.tableView.indexPathForSelectedRow!) as! MessagesTableViewCell;
            let chat = self.dialogs[self.tableView.indexPathForSelectedRow!.row]
            
            let viewController = segue.destination as! DialogViewController
            
            
            //Добавить новое view с информацией о пользователе
            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32, height: view.frame.height))
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
                imageView.contentMode = .scaleAspectFill
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
            
            views.addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: views, attribute: .centerY, multiplier: 1, constant: 0))
            
            //ContainerView
            let containerView = UIView()
            views.addSubview(containerView)
            
            views.addConstraintsWithFormat("H:|-46-[v0]|", views: containerView)
            views.addConstraintsWithFormat("V:[v0(30)]", views: containerView)
            
            views.addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: views, attribute: .centerY, multiplier: 1, constant: 0))
            
            //nameLabel
            let nameLabel: UILabel = {
               let label = UILabel()
                label.text = selectedCell.lblTitle.text
                label.font = UIFont.systemFont(ofSize: 12)
                return label
            }()
            
            //activeTimeLabel
            let activeTimeLabel: UILabel = {
                let label = UILabel()
                if let lastLogin = chat.otherParty?.lastLogin{
                    label.text = lastLogin.toFriendlyLongDateTimeString()
                }
                label.font = UIFont.systemFont(ofSize: 10)
                label.textColor = UIColor.darkGray
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
                if CachingHandler.Instance.status == .complete, let index = CachingHandler.Instance.chats?.index(where: {$0.id == chat.id}) {
                    let cachedChat = CachingHandler.Instance.chats![index]
                    chat.messages = cachedChat.messages
                    viewController.dataFromCache = true
                }
                
                viewController.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(chat.id!, skip: 0)
            }
        }
    }
    
    open override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !self.tableView.isEditing
    }
    
    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let dialog = self.dialogs[indexPath.row]
            AppAnalytics.logEvent(.MessagesScreen_SlideDelete_Clicked)
            ConnectionHandler.Instance.messages.deleteChats([dialog.id!]) { success, errorId, errorMessage, result in
                ThreadHelper.runOnMainThread({ 
                    if success {
                        LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: dialog.id)
                        self.dialogs.remove(at: indexPath.row)
                        AccountHandler.Instance.myChats!.remove(at: AccountHandler.Instance.myChats!.index(where: {$0.id == dialog.id})!)
                        AccountHandler.Instance.saveMyChats()
                        if self.dialogs.count == 0 {
                            self.tableView.reloadData()
                        } else {
                            self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
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
