//
//  Item.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
