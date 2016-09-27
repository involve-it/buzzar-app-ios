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
    
    let navigationBarBackItemTitle = NSLocalizedString("Messages(1)", comment: "NavigationBar Item, Messages")
    
    var isPeeking = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        self.senderId = AccountHandler.Instance.userId ?? CachingHandler.Instance.currentUser?.id
        self.senderDisplayName = chat.otherParty?.username
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.setupBubbles()
        
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId, isCompleted = MessagesHandler.Instance.isCompleted(pendingMessagesAsyncId) {
            if isCompleted {
                if let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
                    chat.messages = messages
                    self.notifyUnseen()
                }
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messagesPageReceived), name: NotificationManager.Name.MessagesAsyncRequestCompleted.rawValue, object: nil)
            }
        }
        
        if self.chat.messages.count > 0{
            self.updateMessages(self.chat.messages)
        }
        LocalNotificationsHandler.Instance.reportEventSeen(.Messages, id: self.chat.id)
    }
    
    func appDidBecomeActive(){
        if self.chat.messages.count > 0 {
            self.updateMessages(self.chat.messages)
        }
    }
    
    func mergeMessages(){
        
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageAdded), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageRemoved), name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageModified), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
    }
    
    func messagesPageReceived(notification:NSNotification){
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId where pendingMessagesAsyncId == notification.object as! String,
            let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
            
            self.updateMessages(messages)
            self.scrollToBottomAnimated(false)
            self.notifyUnseen()
        }
    }
    
    private func notifyUnseen(){
        let unseen = self.chat.messages.filter({!($0.seen ?? false) && $0.id != nil && $0.toUserId == AccountHandler.Instance.userId}).map({$0.id!})
        if unseen.count > 0 && UIApplication.sharedApplication().applicationState == .Active {
            ConnectionHandler.Instance.messages.messagesSetSeen(unseen, callback: { (success, errorId, errorMessage, result) in
                if success {
                    self.chat.messages.filter({unseen.contains($0.id ?? "")}).forEach({ (message) in
                        message.seen = true
                    })
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
        chat.messages = messages.sort({
            return $0.timestamp!.compare($1.timestamp!) == NSComparisonResult.OrderedAscending
        })
        
        self.chat.messages.forEach { (message) in
            if let userId = message.userId, text = message.text{
                addMessage(userId, text: text)
            }
        }
        
        AccountHandler.Instance.saveMyChats()
        
        ThreadHelper.runOnMainThread { 
            self.collectionView.reloadData()
            self.scrollToBottomAnimated(false)
        }
    }
    
    func messageAdded(notification: NSNotification){
        if let message = notification.object as? Message where message.chatId == self.chat.id {
            ThreadHelper.runOnMainThread({ 
                self.addMessage(message.userId!, text: message.text!, callFinish: true)
            })
            if UIApplication.sharedApplication().applicationState == .Active && message.toUserId == AccountHandler.Instance.userId && message.id != nil {
                self.notifyUnseen()
                LocalNotificationsHandler.Instance.reportEventSeen(.Messages, id: self.chat.id)
            }
        } else {
            ThreadHelper.runOnMainThread({ 
                //let backButton = self.navigationItem.backBarButtonItem
                //backButton?.title! += "(1)"
                self.navigationController!.navigationBar.backItem!.title = self.navigationBarBackItemTitle
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
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToBottomAnimated(false)
        if !self.isPeeking {
            self.keyboardController.textView.becomeFirstResponder()
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
    
    func addMessage(id: String, text: String, callFinish: Bool = false){
        let message = JSQMessage(senderId: id, displayName: "", text: text)
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
        let message = MessageToSend()
        message.destinationUserId = self.chat.otherParty?.id
        message.message = text
        ConnectionHandler.Instance.messages.sendMessage(message){ success, errorId, errorMessage, result in
            if success {
                self.chat.lastMessage = text
            } else {
                self.showAlert(NSLocalizedString("Error", comment: "Alert title, Error"), message: errorMessage)
            }
        };
    }
}
