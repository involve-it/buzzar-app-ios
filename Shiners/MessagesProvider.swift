//
//  MessagesProvider.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class MessagesProvider{
    class func getMessage(_ messageId: ShinersMessage) -> String{
        switch messageId {
            case .connectionBroken:
                return NSLocalizedString("Connection to server lost. Working offline.", comment: "Connection Broken, Connection to server lost. Working offline.")
            case .connectionConnecting:
                return NSLocalizedString("Attempting to recover broken connection...", comment: "Connection Connecting, Attempting to recover broken connection...")
            case .connectionEstablished:
                return NSLocalizedString("Connected!", comment: "Connection Established, Connected!")
        }
    }
}

enum ShinersMessage {
    case connectionBroken, connectionEstablished, connectionConnecting
}
