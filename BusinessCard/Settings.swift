//
//  Settings.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 31.07.2024.
//

import SwiftUI

struct Settings: View {
    @AppStorage("acceptIncomingCardAutomaticially") private var acceptIncomingCardAutomaticially: Bool = true
    @AppStorage("shareBackMyCardAutomaticially") private var shareBackMyCardAutomaticially: Bool = true
    @AppStorage("allowsDiscovery") private var allowsDiscovery: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Toggle(isOn: $allowsDiscovery, label: {
                        Text("Allow others to discover my device")
                    })
                    Text("Let others discover my device for exchanging business cards. 😊")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                VStack(alignment: .leading) {
                    Toggle(isOn: $acceptIncomingCardAutomaticially, label: {
                        Text("Automaticially accept any incoming card")
                    })
                    Text("When someone shares their card with me, save it right away. If this is unchecked, we'll ask for your approval first. ✅")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                VStack(alignment: .leading) {
                    Toggle(isOn: $shareBackMyCardAutomaticially, label: {
                        Text("Automaticially share back my card")
                    })
                    Text("When someone shares their card with me, make sure to share my card back with them automatically! 🌟")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            } header: {
                Text("Card sharing with nearby devices")
            } footer: {
                Text("Need to share your card with nearby iOS devices? These settings will come in handy for that. Just a heads up, sharing with Android devices nearby is not supported at the moment.")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel)).listRowSeparator(.hidden)
            }
        }
        
    }
}

#Preview {
    Settings()
}
