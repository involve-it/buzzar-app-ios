//
//  MessagesViewController.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/30/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import UIKit

public class MessagesViewController: UITableViewController{
    var dialogs = [Chat]()
    
    private var meteorLoaded = false
    
    var pendingChatId: String?
    
    @IBAction func unwindMessages(segue: UIStoryboardSegue) {
        //self.navigationController?.popViewControllerAnimated(false)
    }
    
    public override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dialogsUpdated), name: NotificationManager.Name.MyChatsUpdated.rawValue, object: nil)
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
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.dialogs.count > 0 && AccountHandler.Instance.status == .Completed{
            self.checkPending()
        }
    }
    
    private func checkPending(){
        if let pendingChatId = self.pendingChatId, chatIndex = self.dialogs.indexOf({$0.id == pendingChatId}){
            self.navigationController?.popToViewController(self, animated: true)
            let indexPath = NSIndexPath(forRow: chatIndex, inSection: 0)
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .Bottom)
            self.performSegueWithIdentifier("dialog", sender: self)
        }
        self.pendingChatId = nil
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
        AccountHandler.Instance.updateMyChats { (success, errorId, errorMessage, result) in
            self.dialogsUpdated()
        }
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
            self.checkPending()
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
            viewController.navigationItem.title = selectedCell.lblTitle.text
            viewController.chat = chat
            if !chat.messagesRequested {
                chat.messagesRequested = true
                viewController.pendingMessagesAsyncId = MessagesHandler.Instance.getMessagesAsync(chat.id!, skip: 0)
            }
        }
    }
    
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let dialog = self.dialogs[indexPath.row]
            
            ConnectionHandler.Instance.messages.deleteChats([dialog.id!]) { success, errorId, errorMessage, result in
                if success {
                    self.dialogs.removeAtIndex(indexPath.row)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                } else {
                    self.showAlert("Error", message: errorMessage)
                }
                
            }
        }
    }
}
