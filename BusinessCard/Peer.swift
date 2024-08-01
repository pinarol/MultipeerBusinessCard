//
//  Item.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import Foundation
import SwiftData

@Model
final class Peer: Identifiable {
    var id: String {
        displayName
    }
    
    var displayName: String
    var lastSeen: Date?
    var name: String?
    var email: String?
    var phone: String?
    var job: String?
    
    init(displayName: String, lastSeen: Date? = nil, name: String? = nil, email: String? = nil, phone: String? = nil, job: String? = nil) {
        self.displayName = displayName
        self.lastSeen = lastSeen
        self.name = name
        self.email = email
        self.phone = phone
        self.job = job
    }
}
