//
//  DialogViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

open class DialogViewController : JSQMessagesViewController{
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var chat: Chat!
    var pendingMessagesAsyncId: String?
    
    var isPeeking = false
    var initialPage = false
    var dataFromCache: Bool!
    var shownMessageIds = [String]()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        self.senderId = AccountHandler.Instance.userId ?? CachingHandler.Instance.currentUser?.id
        self.senderDisplayName = chat.otherParty?.username
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.setupBubbles()
        
        self.initialPage = true
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
        
        self.chat.seen = true
        
        if self.chat.messages.count > 0{
            self.updateMessages(self.chat.messages)
            self.notifyUnseen()
        }
        LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: self.chat.id)
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
        
        LocalNotificationsHandler.Instance.reportActiveView(.messages, id: self.chat.id)
        
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
        if let message = notification.object as? Message, message.chatId == self.chat.id /*&& !self.chat.messages.contains({$0.id! == message.id!})*/ {
            ThreadHelper.runOnMainThread({ 
                self.addMessage(message.id!, senderId: message.userId!, text: message.text!, timestamp: message.timestamp!, callFinish: true)
            })
            if UIApplication.shared.applicationState == .active {
                if message.toUserId == AccountHandler.Instance.userId {
                    self.notifyUnseen()
                }
                LocalNotificationsHandler.Instance.reportEventSeen(.messages, id: self.chat.id)
            }
        } else {
            ThreadHelper.runOnMainThread({ 
                //let backButton = self.navigationItem.backBarButtonItem
                //backButton?.title! += "(1)"
                let count = LocalNotificationsHandler.Instance.getNewEventCount(.messages)
                if count > 0 {
                    self.navigationController!.navigationBar.backItem!.title = NSLocalizedString("Messages(\(count))", comment: "NavigationBar Item, Messages")
                }
            })
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MessageAdded.rawValue), object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MessageRemoved.rawValue), object: nil)
        LocalNotificationsHandler.Instance.reportActiveView(.messages, id: nil)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToBottom(animated: false)
        if !self.isPeeking {
            self.keyboardController.textView.becomeFirstResponder()
        }
        
        let count = LocalNotificationsHandler.Instance.getNewEventCount(.messages)
        if count > 0 {
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
                if id == self.senderId {
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
        if text != "" {
            if !self.isNetworkReachable(){
                return
            }
            self.setLoading(true)
            button.isEnabled = false
            
            
            self.doSendMessge()
        }
    }
    
    func doSendMessge() {
        if ConnectionHandler.Instance.status == .connected {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationManager.Name.MeteorConnected.rawValue), object: nil)
            let message = MessageToSend()
            message.destinationUserId = self.chat.otherParty?.id
            message.message = self.inputToolbar.contentView.textView.text
            
            ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                ThreadHelper.runOnMainThread({
                    self.setLoading(false)
                    self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
                    
                    if success {
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
