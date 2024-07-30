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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            /*let samplePeers = [
                Peer(displayName: "Sir Tom Jones", lastSeen: Date(), name: "Tom Jones", email: "tomjones@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
                Peer(displayName: "Celine Dion", lastSeen: Date(), name: "Celine Dion", email: "celine@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
                Peer(displayName: "Mariah Carey", lastSeen: Date(), name: "Mariah Carey", email: "email@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
            ]
            
            for peer in samplePeers {
                container.mainContext.insert(peer)
            }*/
            return container
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
