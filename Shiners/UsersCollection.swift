//
//  UsersCollection.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/25/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import SwiftDDP

public class UsersCollection:AbstractCollection{
    var users = [User]()
    
    init() {
        super.init(name: "users");
    }
    
    override public func documentWasAdded(collection: String, id: String, fields: NSDictionary?) {
        let user = User(id: id, fields: fields)
        self.users.append(user)
    }
    
    override public func documentWasRemoved(collection: String, id: String) {
        if let index = self.users.indexOf({user in return user.id == id}){
            self.users.removeAtIndex(index)
        }
    }
    
    override public func documentWasChanged(collection: String, id: String, fields: NSDictionary?, cleared: [String]?) {
        if let index = self.users.indexOf({user in return user.id == id}){
            let user = self.users[index];
            user.update(fields);
        }
    }
    
    public func count() -> Int{
        return users.count;
    }
    
    public func itemAtIndex(index: Int) -> User{
        return users[index];
    }
}