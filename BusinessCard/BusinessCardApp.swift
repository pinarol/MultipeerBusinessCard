//
//  BusinessCardApp.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import SwiftUI
import SwiftData

@MainActor
@main
struct BusinessCardApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Peer.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
