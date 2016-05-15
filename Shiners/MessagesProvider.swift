//
//  MessagesProvider.swift
//  Shiners
//
//  Created by Yury Dorofeev on 5/15/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation

class MessagesProvider{
    class func getMessage(messageId: ShinersMessage) -> String{
        switch messageId {
            case .ConnectionBroken:
                return "Connection to server lost. Working offline."
            case .ConnectionConnecting:
                return "Attempting to recover broken connection..."
            case .ConnectionEstablished:
                return "Connected!"
        }
    }
}

enum ShinersMessage {
    case ConnectionBroken, ConnectionEstablished, ConnectionConnecting
}