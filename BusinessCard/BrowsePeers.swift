import SwiftUI
import MultipeerConnectivity

struct BrowsePeers: View {
    @Binding var peerIDs: [MCPeerID]
    var inviteHandler: ([MCPeerID]) -> ()
    @State private var selectedPeers: [Int: MCPeerID] = [:]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(peerIDs.enumerated()), id: \.offset) { index, peerID in
                        HStack {
                            Button(peerID.displayName) {
                                if selectedPeers[index] != nil {
                                    selectedPeers[index] = nil                                }
                                else {
                                    selectedPeers[index] = peerID
                                }
                            }
                            
                            Spacer()
                            selectionIcon(for: index)
                        }
                    }
                } header: {
                    VStack(alignment: .leading) {
                        Text("Available Peers")
                            .listRowSeparator(.hidden)
                            .textCase(.uppercase)
                            .foregroundColor(Color(UIColor.label))
                        Text("Ask your friends to open the BusinessCards app.")
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .listRowSeparator(.visible)
                            .textInputAutocapitalization(.never)
                    }
                    .textCase(.none)
                } footer: {
                    Text("Just a heads up, this feature only works between iOS devices.")
                }
                
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        Button("Invite") {
                            inviteHandler(Array(selectedPeers.values))
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(selectedPeers.isEmpty)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Browse Peers")
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    func selectionIcon(for index: Int) -> some View {
        if selectedPeers[index] != nil {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(UIColor.systemGreen))
        }
    }
}

extension MCPeer {
    @ViewBuilder
    func icon() -> some View {
        switch state {
        case .connected:
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(UIColor.systemGreen))
        case .notConnected:
            Image(systemName: "circle.fill").foregroundColor(Color(UIColor.systemRed))
        case .connecting:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        case .none:
            Text("None")
        @unknown default:
            Text("Unknown")
        }
    }
}

extension MCPeerID: Identifiable {
    public var id: String { displayName }
}

#Preview {
    let peers: [MCPeerID] = [.init(displayName: "Peer1"),
                             .init(displayName: "Peer2"),
                             .init(displayName: "Peer3"),
                             .init(displayName: "Peer4"),
                             .init(displayName: "Peer5")]
    return BrowsePeers(peerIDs: .constant(peers)) { peers in
        
    }
}
