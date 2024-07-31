import SwiftUI
import MultipeerConnectivity

struct BrowsePeers: View {
    @Binding var peers: [MCPeerID]
    var selectionHandler: (MCPeerID) -> ()
    
    var body: some View {
        List {
            Text("Available Peers")
            ForEach(peers) { peer in
                Button(peer.displayName) {
                    selectionHandler(peer)
                }
            }
        }
    }
}

extension MCPeerID: Identifiable {
    public var id: String { displayName }
}

#Preview {
    BrowsePeers(peers: .constant([.init(displayName: "Peer1"),
                                  .init(displayName: "Peer2")]), selectionHandler: { _ in })
}
