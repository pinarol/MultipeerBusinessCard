//
//  ContentView.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import SwiftUI
import SwiftData
import MultipeerConnectivity

enum Page: String, CaseIterable, Identifiable {
    case businessCard = "Cards"
    case settings = "Settings"

    var id: Int {
        self.rawValue.hashValue
    }
    
    var title: String {
        rawValue
    }
}

struct ContentView: View {

    @State var presentedItems: [Page] = []
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("displayName") private var displayName: String = ""
        
    var body: some View {
        NavigationStack(path: $presentedItems) {
            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Display Name", text: $displayName)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Text("Display name helps other people to discover you.")
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                VStack(alignment: .center, spacing: 10) {
                    NavigationLink(value: Page.businessCard) {
                        Text("Next")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(alignment: .center)
                    .disabled(displayName.isEmpty)
                    .padding(.vertical, 20)
                    .multilineTextAlignment(.center)
                }
                Spacer()
                
            }
            .padding()
            .navigationTitle("Multipeer Connection Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Page.self, destination: { page in
                view(for: page)
                    .navigationTitle(page.rawValue)
            })
        }
    }
    
    @ViewBuilder
    func view(for page: Page) -> some View {
        switch page {
        case .businessCard:
            CardSharingView(multipeerSession: MultipeerSession(modelContext: modelContext, myPeerId: MCPeerID(displayName: displayName)))
        case .settings:
            Settings()
        }
    }
    /*
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }*/
}

#Preview {
    ContentView()
        .modelContainer(for: Peer.self, inMemory: true)
}
