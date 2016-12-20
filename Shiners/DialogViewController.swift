//
//  DialogViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

open class DialogViewController : JSQMessagesViewController, UIGestureRecognizerDelegate, NewMessageViewControllerDelegate{
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var chat: Chat!
    var pendingMessagesAsyncId: String?
    
    var isPeeking = false
    var initialPage = false
    var dataFromCache: Bool!
    var shownMessageIds = [String]()
    var newMessage = false
    var openedModally = false
    
    var newMessageRecipient: User?
    var showNearbyUsers = true
    var newMessageViewController: NewMessageViewController?
    
    //@IBOutlet var accessoryView: NewMessageView!
    
    func recipientSelected() {
        self.keyboardController.textView.becomeFirstResponder()
    }
    
    @IBOutlet var accessoryView: UIView!
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newMessageContainer" {
            let newMessageViewController = segue.destination as! NewMessageViewController
            newMessageViewController.recipient = self.newMessageRecipient
            newMessageViewController.showNearbyUsers = self.showNearbyUsers
            newMessageViewController.delegate = self
            self.newMessageViewController = newMessageViewController
        }
    }
    
    open override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "newMessageContainer" {
            return self.newMessage
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.chat == nil
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.senderId = AccountHandler.Instance.userId ?? CachingHandler.Instance.currentUser?.id
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.setupBubbles()
        
        self.initialPage = true
        
        if self.newMessage {
            //self.accessoryView.setupView(frame: self.view.frame, navigationController: self.navigationController!, inputViewHeight: self.inputToolbar.frame.size.height)
            //self.view.addSubview(self.accessoryView)
            self.senderDisplayName = ""
            self.view.addSubview(self.accessoryView)
            self.newMessageViewController!.setupView(frame: self.view.frame, navigationController: self.navigationController!, inputViewHeight: self.inputToolbar.frame.size.height, keyboardController: self.keyboardController)
            self.newMessageViewController!.tableView.gestureRecognizers!.forEach({ (recognizer) in
                self.collectionView.addGestureRecognizer(recognizer)
            })
            self.collectionView.addGestureRecognizer(self.newMessageViewController!.tapGestureRecognizer)
            
            //self.collectionView.addGestureRecognizer(self.newMessageViewController!.tableView.panGestureRecognizer)
        } else {
            self.setupTitleBar()
            if !openedModally{
                self.navigationItem.leftBarButtonItem = nil
            }
            NotificationCenter.default.addObserver(self, selector: #selector(messagesPageReceived), name: NSNotification.Name(rawValue: NotificationManager.Name.MessagesAsyncRequestCompleted.rawValue), object: nil)
            if let pendingMessagesAsyncId = self.pendingMessagesAsyncId {
                if let isCompleted = MessagesHandler.Instance.isCompleted(pendingMessagesAsyncId), isCompleted {
                    self.pendingMessagesAsyncId = nil
                    if let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
                        chat.messages = messages
                        self.notifyUnseen()
                    }
                }
            }
            
            self.senderDisplayName = chat.otherParty?.username
            
            self.chat.seen = true
            
            if self.chat.messages.count > 0{
                self.updateMessages(self.chat.messages)
                self.notifyUnseen()
            }
            LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: self.chat.id)
        }
    }
    
    func setupTitleBar() {
        ThreadHelper.runOnMainThread { 
            if self.newMessage {
                UIView.animate(withDuration: 0.2, animations: {
                    self.collectionView.frame.origin.y = 0
                    self.collectionView.frame.size.height -= self.accessoryView.frame.size.height
                    self.accessoryView.frame.origin.y -= self.accessoryView.frame.size.height
                }, completion: { (finished) in
                    self.accessoryView.removeFromSuperview()
                    self.newMessageViewController = nil
                })
                self.view.layoutSubviews()
            }
            
            //Добавить новое view с информацией о пользователе
            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 32, height: self.view.frame.height))
            titleLabel.text = "HOME"
            
            //Main profile view
            let views: UIView = {
                let v = UIView()
                v.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 42)
                return v
            }()
            
            //Profile imageView
            let profileImageView: UIImageView = {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                
                imageView.image = ImageCachingHandler.defaultAccountImage
                if let imageUrl = self.chat?.otherParty?.imageUrl {
                    ImageCachingHandler.Instance.getImageFromUrl(imageUrl, defaultImage: ImageCachingHandler.defaultAccountImage, callback: { (image) in
                        ThreadHelper.runOnMainThread {
                            imageView.image = image
                        }
                    })
                }
                //imageView.image = selectedCell.imgPhoto.image
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
                
                if let fullName = self.chat.otherParty?.getFullName(){
                    label.text = fullName
                } else {
                    label.text = self.chat.otherParty?.username
                }
                label.font = UIFont.systemFont(ofSize: 12)
                return label
            }()
            
            //activeTimeLabel
            let activeTimeLabel: UILabel = {
                let label = UILabel()
                if let lastLogin = self.chat.otherParty?.lastLogin{
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
            
            self.navigationItem.titleView = views
        }
    }
    
    @IBAction func btnDone_Clicked(_ sender: Any) {
        self.navigationController!.dismiss(animated: true, completion: nil)
    }
    
    func appDidBecomeActive(){
        if self.chat.messages.count > 0 {
            self.updateMessages(self.chat.messages)
        }
    }
    
    open override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.view.endEditing(true)
        self.showLoadEarlierMessagesHeader = false
        
        self.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(self.chat.id!, skip: self.messages.count)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.newMessage {
            LocalNotificationsHandler.Instance.reportActiveView(.messages, id: self.chat.id)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(messageAdded), name: NSNotification.Name(rawValue: NotificationManager.Name.MessageAdded.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageRemoved), name: NSNotification.Name(rawValue: NotificationManager.Name.MessageRemoved.rawValue), object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageModified), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
    }
    
    func messagesPageReceived(_ notification:Notification){
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId, pendingMessagesAsyncId == notification.object as! String,
            let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
            self.chat.messagesRequested = true
            self.dataFromCache = false
            self.updateMessages(messages)
            if messages.contains(where: {!($0.seen ?? true)}) || !(self.chat.seen ?? true){
                self.notifyUnseen()
            }
        }
    }
    
    fileprivate func notifyUnseen(){
        let unseen = self.chat.messages.filter({!($0.seen ?? false) && $0.id != nil && $0.toUserId == AccountHandler.Instance.userId}).map({$0.id!})
        if unseen.count > 0 && UIApplication.shared.applicationState == .active {
            ConnectionHandler.Instance.messages.messagesSetSeen(unseen, callback: { (success, errorId, errorMessage, result) in
                if success {
                    self.chat.messages.filter({unseen.contains($0.id ?? "")}).forEach({ (message) in
                        message.seen = true
                    })
                    self.chat.seen = true
                    ThreadHelper.runOnBackgroundThread({ 
                        AccountHandler.Instance.saveMyChats()
                    })
                    NotificationManager.sendNotification(.MyChatsUpdated, object: self.chat)
                } else {
                    print("Error marking messages page seen: " + (errorMessage ?? "(null)"))
                }
            })
        }
    }
    
    fileprivate func updateMessages(_ messages: Array<Message>){
        if messages.count == 0{
            ThreadHelper.runOnMainThread({
                self.showLoadEarlierMessagesHeader = false
            })
        } else {
            let messagesSorted = messages.sorted(by: {
                return $0.timestamp!.compare($1.timestamp! as Date) == ComparisonResult.orderedAscending
            })
            if self.initialPage {
                self.shownMessageIds.removeAll()
                chat.messages = messagesSorted
                self.messages = [JSQMessage]()
                self.chat.messages.forEach { (message) in
                    if let userId = message.userId, let text = message.text, let timestamp = message.timestamp, self.chat.messages.count <= MessagesHandler.DEFAULT_PAGE_SIZE || message != self.chat.messages.first!{
                        addMessage(message.id!, senderId: userId, text: text, timestamp: timestamp as Date)
                    }
                }
                ThreadHelper.runOnMainThread({ 
                    self.collectionView.reloadData()
                    self.scrollToBottom(animated: false)
                })
                
                //cache only first page
                AccountHandler.Instance.saveMyChats()
            } else {
                let oldBottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y
                let messagesSortedDescending = messages.sorted(by: {
                    return $0.timestamp!.compare($1.timestamp! as Date) == ComparisonResult.orderedDescending
                })
                var indexPaths = [IndexPath]()
                var totalCount = messages.count
                if messages.count > MessagesHandler.DEFAULT_PAGE_SIZE {
                    totalCount = MessagesHandler.DEFAULT_PAGE_SIZE
                }
                for i in 0...totalCount - 1 {
                    indexPaths.append(IndexPath(item: i, section: 0))
                    let message = messagesSortedDescending[i]
                    if let userId = message.userId, let text = message.text, let timestamp = message.timestamp {
                        let message = JSQMessage(senderId: userId, senderDisplayName: "", date: timestamp as Date!, text: text)
                        self.messages.insert(message!, at: 0)
                    }
                }
                
                ThreadHelper.runOnMainThread({
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    self.collectionView.performBatchUpdates({ 
                        self.collectionView.insertItems(at: indexPaths)
                        self.collectionView.collectionViewLayout.invalidateLayout(with: JSQMessagesCollectionViewFlowLayoutInvalidationContext())
                    }, completion: { (finished) in
                        self.finishReceivingMessage(animated: false)
                        self.collectionView.layoutIfNeeded()
                        self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - oldBottomOffset)
                        CATransaction.commit()
                    })
                })
            }
            
            ThreadHelper.runOnMainThread {
                if messages.count > MessagesHandler.DEFAULT_PAGE_SIZE{
                    self.showLoadEarlierMessagesHeader = true
                } else {
                    self.showLoadEarlierMessagesHeader = false
                }
            }
        }
        
        if !self.dataFromCache {
            self.initialPage = false
        }
    }
    
    override open var prefersStatusBarHidden : Bool {
        return false
    }
    
    func messageAdded(_ notification: Notification){
        if let message = notification.object as? Message{
            var setupTitlebar = false
            if self.chat == nil && self.newMessage && message.id == self.lastMessageId, let index = AccountHandler.Instance.myChats?.index(where: {$0.id == message.chatId}) {
                self.chat = AccountHandler.Instance.myChats![index]
                setupTitlebar = true
                LocalNotificationsHandler.Instance.reportActiveView(.messages, id: self.chat.id)
            }
            if self.chat != nil {
                if message.chatId == self.chat.id /*&& !self.chat.messages.contains({$0.id! == message.id!})*/ {
                    ThreadHelper.runOnMainThread({ 
                        self.addMessage(message.id!, senderId: message.userId!, text: message.text!, timestamp: message.timestamp!, callFinish: true)
                        if setupTitlebar {
                            self.setupTitleBar()
                        }
                    })
                    if UIApplication.shared.applicationState == .active {
                        if message.toUserId == AccountHandler.Instance.userId {
                            self.notifyUnseen()
                        }
                        LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: self.chat.id)
                    }
                } else {
                    if !self.newMessage {
                        ThreadHelper.runOnMainThread({
                            //let backButton = self.navigationItem.backBarButtonItem
                            //backButton?.title! += "(1)"
                            let count = LocalNotificationsHandler.Instance.getNewEventCount(.messages)
                            if count > 0 && !self.openedModally && !self.newMessage {
                                self.navigationController!.navigationBar.backItem!.title = NSLocalizedString("Messages(\(count))", comment: "NavigationBar Item, Messages")
                            }
                        })
                    }
                }
            }
        }
    }
    
    func messageRemoved(_ notification: Notification){
        if let message = notification.object as? Message, message.chatId == self.chat.id {
            //todo
        }
    }
    
    func messageModified(_ notification: Notification){
        if let message = notification.object as? Message, message.chatId == self.chat.id {
            //todo
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MessageAdded.rawValue), object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MessageRemoved.rawValue), object: nil)
        LocalNotificationsHandler.Instance.reportActiveView(.messages, id: nil)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*if self.newMessage {
            self.collectionView.frame.origin.y += self.accessoryView.frame.size.height
            self.collectionView.frame.size.height -= self.accessoryView.frame.size.height
            self.view.layoutSubviews()
        }*/
        self.scrollToBottom(animated: false)
        if !self.isPeeking {
            self.keyboardController.textView.becomeFirstResponder()
        }
        
        let count = LocalNotificationsHandler.Instance.getNewEventCount(.messages)
        if count > 0 && !self.newMessage {
            self.navigationController!.navigationBar.backItem!.title = NSLocalizedString("Messages(\(count))", comment: "NavigationBar Item, Messages")
        }
    }
    
    fileprivate func shouldDisplayTimestamp(_ index: Int) -> Bool{
        if index == 0{
            return true
        } else {
            let currentMessage = self.messages[index]
            let previousMessage = self.messages[index - 1]
            if currentMessage.date.timeIntervalSince(previousMessage.date) > 60 * 5 {
                return true
            } else {
                return false
            }
        }
    }
    
    open override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if self.shouldDisplayTimestamp(indexPath.row){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0
        }
    }
    
    open override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if self.shouldDisplayTimestamp(indexPath.row){
            let currentMessage = self.messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: currentMessage.date)
        } else {
            return nil
        }
    }
    
    open override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    open override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == self.senderId{
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == self.senderId{
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.black
        }
        
        return cell;
    }
    
    fileprivate func setupBubbles(){
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleBlue())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override open func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func addMessage(_ id: String, senderId: String, text: String, timestamp: Date, callFinish: Bool = false){
        //let message = JSQMessage(senderId: id, displayName: "", text: text)
        if self.shownMessageIds.index(of: id) == nil {
            self.shownMessageIds.append(id)
            let message = JSQMessage(senderId: senderId, senderDisplayName: "", date: timestamp, text: text)
            messages.append(message!)
            if callFinish{
                if AccountHandler.Instance.userId == self.senderId {
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    finishSendingMessage()
                } else {
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    finishReceivingMessage()
                }
            }
        }
    }
    
    open override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text != "" && (!self.newMessage || self.chat != nil || self.newMessageViewController?.recipient != nil) {
            if !self.isNetworkReachable(){
                return
            }
            self.setLoading(true)
            button.isEnabled = false
            
            
            self.doSendMessge()
        }
    }
    
    var lastMessageId: String?
    
    func doSendMessge() {
        if ConnectionHandler.Instance.isConnected() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            let message = MessageToSend()
            if self.chat != nil {
                message.destinationUserId = self.chat.otherParty?.id
            } else if self.newMessageViewController?.recipient != nil {
                message.destinationUserId = self.newMessageViewController!.recipient!.id
            } else {
                return
            }
            
            message.message = self.inputToolbar.contentView.textView.text
            
            ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                ThreadHelper.runOnMainThread({
                    self.setLoading(false)
                    self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
                    
                    if success {
                        self.lastMessageId = (result as! String)
                        if self.chat == nil, let collectionMessageIndex = AccountHandler.Instance.messagesCollection.messages.index(where: {$0.id == self.lastMessageId!}), let index = AccountHandler.Instance.myChats?.index(where: {$0.id == AccountHandler.Instance.messagesCollection.messages[collectionMessageIndex].chatId}) {
                            let collectionMessage = AccountHandler.Instance.messagesCollection.messages[collectionMessageIndex]
                            self.chat = AccountHandler.Instance.myChats![index]
                            self.setupTitleBar()
                            self.addMessage(collectionMessage.id!, senderId: collectionMessage.userId!, text: collectionMessage.text!, timestamp: collectionMessage.timestamp!, callFinish: true)
                            LocalNotificationsHandler.Instance.reportActiveView(.messages, id: self.chat.id)
                        }
                        self.finishSendingMessage()
                    } else {
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    }
                })
            }
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(doSendMessge), name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
        }
    }
}

extension Date {
    
    func timestampFormatterForDate() -> NSAttributedString {
        return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: self)
    }
}
