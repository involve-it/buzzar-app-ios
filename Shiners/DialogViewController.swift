//
//  DialogViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/14/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

public class DialogViewController : JSQMessagesViewController{
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var chat: Chat!
    var pendingMessagesAsyncId: String?
    
    var isPeeking = false
    var initialPage = false
    var dataFromCache: Bool!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.senderId = AccountHandler.Instance.userId ?? CachingHandler.Instance.currentUser?.id
        self.senderDisplayName = chat.otherParty?.username
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.setupBubbles()
        
        self.initialPage = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messagesPageReceived), name: NotificationManager.Name.MessagesAsyncRequestCompleted.rawValue, object: nil)
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId {
            if let isCompleted = MessagesHandler.Instance.isCompleted(pendingMessagesAsyncId) where isCompleted {
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
        LocalNotificationsHandler.Instance.reportEventSeen(.Messages, id: self.chat.id)
    }
    
    func appDidBecomeActive(){
        if self.chat.messages.count > 0 {
            self.updateMessages(self.chat.messages)
        }
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        self.view.endEditing(true)
        self.showLoadEarlierMessagesHeader = false
        
        self.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(self.chat.id!, skip: self.messages.count)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        LocalNotificationsHandler.Instance.reportActiveView(.Messages, id: self.chat.id)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageAdded), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageRemoved), name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageModified), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
    }
    
    func messagesPageReceived(notification:NSNotification){
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId where pendingMessagesAsyncId == notification.object as! String,
            let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
            
            self.dataFromCache = false
            self.updateMessages(messages)
            if !(self.chat.seen ?? true) {
                self.notifyUnseen()
            }
        }
    }
    
    private func notifyUnseen(){
        NotificationManager.sendNotification(.MyChatsUpdated, object: chat)
        let unseen = self.chat.messages.filter({!($0.seen ?? false) && $0.id != nil && $0.toUserId == AccountHandler.Instance.userId}).map({$0.id!})
        if unseen.count > 0 && UIApplication.sharedApplication().applicationState == .Active {
            ConnectionHandler.Instance.messages.messagesSetSeen(unseen, callback: { (success, errorId, errorMessage, result) in
                if success {
                    self.chat.messages.filter({unseen.contains($0.id ?? "")}).forEach({ (message) in
                        message.seen = true
                    })
                    self.chat.seen = true
                    ThreadHelper.runOnBackgroundThread({ 
                        AccountHandler.Instance.saveMyChats()
                    })
                } else {
                    print("Error marking messages page seen: " + (errorMessage ?? "(null)"))
                }
            })
        }
    }
    
    private func updateMessages(messages: Array<Message>){
        if messages.count == 0{
            ThreadHelper.runOnMainThread({
                self.showLoadEarlierMessagesHeader = false
            })
        } else {
            let messagesSorted = messages.sort({
                return $0.timestamp!.compare($1.timestamp!) == NSComparisonResult.OrderedAscending
            })
            if self.initialPage {
                chat.messages = messagesSorted
                self.messages = [JSQMessage]()
                self.chat.messages.forEach { (message) in
                    if let userId = message.userId, text = message.text, timestamp = message.timestamp where self.chat.messages.count <= MessagesHandler.DEFAULT_PAGE_SIZE || message != self.chat.messages.first!{
                        addMessage(userId, text: text, timestamp: timestamp)
                    }
                }
                ThreadHelper.runOnMainThread({ 
                    self.collectionView.reloadData()
                    self.scrollToBottomAnimated(false)
                })
                
                //cache only first page
                AccountHandler.Instance.saveMyChats()
            } else {
                let oldBottomOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y
                let messagesSortedDescending = messages.sort({
                    return $0.timestamp!.compare($1.timestamp!) == NSComparisonResult.OrderedDescending
                })
                var indexPaths = [NSIndexPath]()
                var totalCount = messages.count
                if messages.count > MessagesHandler.DEFAULT_PAGE_SIZE {
                    totalCount = MessagesHandler.DEFAULT_PAGE_SIZE
                }
                for i in 0...totalCount - 1 {
                    indexPaths.append(NSIndexPath(forItem: i, inSection: 0))
                    let message = messagesSortedDescending[i]
                    if let userId = message.userId, text = message.text, timestamp = message.timestamp {
                        let message = JSQMessage(senderId: userId, senderDisplayName: "", date: timestamp, text: text)
                        self.messages.insert(message, atIndex: 0)
                    }
                }
                
                ThreadHelper.runOnMainThread({
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    
                    self.collectionView.performBatchUpdates({ 
                        self.collectionView.insertItemsAtIndexPaths(indexPaths)
                        self.collectionView.collectionViewLayout.invalidateLayoutWithContext(JSQMessagesCollectionViewFlowLayoutInvalidationContext())
                    }, completion: { (finished) in
                        self.finishReceivingMessageAnimated(false)
                        self.collectionView.layoutIfNeeded()
                        self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentSize.height - oldBottomOffset)
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
    
    override public func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    func messageAdded(notification: NSNotification){
        if let message = notification.object as? Message where message.chatId == self.chat.id {
            ThreadHelper.runOnMainThread({ 
                self.addMessage(message.userId!, text: message.text!, timestamp: message.timestamp!, callFinish: true)
            })
            if UIApplication.sharedApplication().applicationState == .Active {
                if message.toUserId == AccountHandler.Instance.userId {
                    self.notifyUnseen()
                }
                LocalNotificationsHandler.Instance.reportEventSeen(.Messages, id: self.chat.id)
            }
        } else {
            ThreadHelper.runOnMainThread({ 
                //let backButton = self.navigationItem.backBarButtonItem
                //backButton?.title! += "(1)"
                let count = LocalNotificationsHandler.Instance.getNewEventCount(.Messages)
                if count > 0 {
                    self.navigationController!.navigationBar.backItem!.title = NSLocalizedString("Messages(\(count))", comment: "NavigationBar Item, Messages")
                }
            })
        }
    }
    
    func messageRemoved(notification: NSNotification){
        if let message = notification.object as? Message where message.chatId == self.chat.id {
            //todo
        }
    }
    
    func messageModified(notification: NSNotification){
        if let message = notification.object as? Message where message.chatId == self.chat.id {
            //todo
        }
    }
    
    public override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
        LocalNotificationsHandler.Instance.reportActiveView(.Messages, id: nil)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToBottomAnimated(false)
        if !self.isPeeking {
            self.keyboardController.textView.becomeFirstResponder()
        }
        
        let count = LocalNotificationsHandler.Instance.getNewEventCount(.Messages)
        if count > 0 {
            self.navigationController!.navigationBar.backItem!.title = NSLocalizedString("Messages(\(count))", comment: "NavigationBar Item, Messages")
        }
    }
    
    private func shouldDisplayTimestamp(index: Int) -> Bool{
        if index == 0{
            return true
        } else {
            let currentMessage = self.messages[index]
            let previousMessage = self.messages[index - 1]
            if currentMessage.date.timeIntervalSinceDate(previousMessage.date) > 60 * 5 {
                return true
            } else {
                return false
            }
        }
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if self.shouldDisplayTimestamp(indexPath.row){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0
        }
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if self.shouldDisplayTimestamp(indexPath.row){
            let currentMessage = self.messages[indexPath.row]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(currentMessage.date)
        } else {
            return nil
        }
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == self.senderId{
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == self.senderId{
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        return cell;
    }
    
    private func setupBubbles(){
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override public func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func addMessage(id: String, text: String, timestamp: NSDate, callFinish: Bool = false){
        //let message = JSQMessage(senderId: id, displayName: "", text: text)
        let message = JSQMessage(senderId: id, senderDisplayName: "", date: timestamp, text: text)
        messages.append(message)
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
    
    public override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        if text != "" {
            let message = MessageToSend()
            message.destinationUserId = self.chat.otherParty?.id
            message.message = text
            
            ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
                if !success {
                    ThreadHelper.runOnMainThread({ 
                        self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
                    })
                }
            };
            
            self.finishSendingMessage()
        }
    }
}

extension NSDate {
    
    func timestampFormatterForDate() -> NSAttributedString {
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(self)
    }
}
