//
//  Settings.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 31.07.2024.
//

import SwiftUI

struct Settings: View {
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
            } header: {
                Text("Card sharing with nearby devices")
            } footer: {
                Text("Just a heads up, sharing with Android devices nearby is not supported at the moment.")
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.secondaryLabel)).listRowSeparator(.hidden)
            }
        }
        
    }
}

#Preview {
    Settings()
}
