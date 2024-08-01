//
//  SharingSessionView.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 31.07.2024.
//

import SwiftUI

struct SharingSessionView: View {
    
    @Binding var peers: [String: Peer]
    @State private var selectedPeers: [Peer]
    var acceptHandler: ([Peer]) -> ()
    
    init(peers: Binding<[String : Peer]>, acceptHandler: @escaping ([Peer]) -> Void) {
        self._peers = peers
        self.selectedPeers = Array(peers.wrappedValue.values)
        self.acceptHandler = acceptHandler
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(peers.values)) { peer in
                        HStack {
                            CardView(peer: peer)
                            Image(systemName: "checkmark.circle.fill").foregroundColor(
                                isSelected(peer: peer) ? Color(UIColor.systemGreen) : Color(UIColor.systemGray))
                        }
                        .onTapGesture {
                            if isSelected(peer: peer) {
                                guard let index = selectedPeers.firstIndex(where: { $0.displayName == peer.displayName
                                }) else { return }
                                selectedPeers.remove(at: index)
                            }
                            else {
                                selectedPeers.append(peer)
                            }
                        }
                    }
                } header: {
                    Text("Shared cards")
                } footer: {
                    Text("")
                }
                Button(action: {
                    acceptHandler(selectedPeers)
                }, label: {
                    Text("Accept")
                        .font(.title3)
                })
                .disabled(selectedPeers.isEmpty)
            }
            .onAppear() {
                self.selectedPeers = Array($peers.wrappedValue.values)
            }
            .onChange(of: peers, { oldValue, newValue in
                // ideally we shouldn't update the existing selected state, we should only add the new ones
                self.selectedPeers = Array(newValue.values)
            })
            .navigationTitle("Sharing Session")
        }
    }
    
    private func isSelected(peer: Peer) -> Bool {
        selectedPeers.first(where: { peerIter in
            peerIter.displayName == peer.displayName
        }) != nil
    }
}

#Preview {
    let samplePeers = [
        "Sir Tom Jones": Peer(displayName: "Sir Tom Jones", lastSeen: Date(), name: "Sir Tom Jones", email: "tomjones@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
        "Celine Dion": Peer(displayName: "Celine Dion", lastSeen: Date(), name: "Celine Dion", email: "celine@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
        "Mariah Carey": Peer(displayName: "Mariah Carey", lastSeen: Date(), name: "Mariah Carey", email: "mariah@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
    ]
    return SharingSessionView(peers: .constant(samplePeers), acceptHandler: { _ in })
}
