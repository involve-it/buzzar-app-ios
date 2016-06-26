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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.senderId = AccountHandler.Instance.userId
        self.senderDisplayName = chat.otherParty?.username
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.inputToolbar.contentView.leftBarButtonItem = nil
        
        self.setupBubbles()
        
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId, isCompleted = MessagesHandler.Instance.isCompleted(pendingMessagesAsyncId) {
            if isCompleted {
                if let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
                    chat.messages = messages
                }
            } else {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messagesPageReceived), name: NotificationManager.Name.MessagesAsyncRequestCompleted.rawValue, object: nil)
            }
        }
        
        if self.chat.messages.count > 0{
            self.updateMessages(self.chat.messages)
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageAdded), name: NotificationManager.Name.MessageAdded.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageRemoved), name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(messageModified), name: NotificationManager.Name.MessageModified.rawValue, object: nil)
    }
    
    func messagesPageReceived(notification:NSNotification){
        if let pendingMessagesAsyncId = self.pendingMessagesAsyncId where pendingMessagesAsyncId == notification.object as! String,
            let messages = MessagesHandler.Instance.getMessagesByRequestId(pendingMessagesAsyncId){
            self.updateMessages(messages)
        }
    }
    
    private func updateMessages(messages: Array<Message>){
        chat.messages = messages.sort({
            return $0.timestamp!.compare($1.timestamp!) == NSComparisonResult.OrderedAscending
        })
        
        self.chat.messages.forEach { (message) in
            addMessage(message.userId!, text: message.text!)
        }
        
        self.collectionView.reloadData()
    }
    
    func messageAdded(notification: NSNotification){
        if let message = notification.object as? Message where message.chatId == self.chat.id {
            addMessage(message.userId!, text: message.text!, callFinish: true)
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageModified.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationManager.Name.MessageRemoved.rawValue, object: nil)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.keyboardController.textView.becomeFirstResponder()
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
        addMessage(self.senderId, text: text, callFinish: true)
        let message = MessageToSend()
        message.destinationUserId = self.chat.otherParty?.id
        message.message = text
        
        ConnectionHandler.Instance.messages.sendMessage(message);
    }
}
