import SwiftUI
import MultipeerConnectivity
import SwiftData

class MultipeerSession: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let serviceType = "my-peers"
    private var myPeerId: MCPeerID
    private(set) var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    private var timeStarted: Date = Date()
    private var modelContext: ModelContext
    @Published var discoveredPeers: [MCPeerID] = []
    @AppStorage("name") private var name: String = ""
    @AppStorage("email") private var email: String = ""
    @AppStorage("phone") private var phone: String = ""
    @AppStorage("job") private var job: String = ""

    init(modelContext: ModelContext, myPeerId: MCPeerID) {
        self.modelContext = modelContext
        self.myPeerId = myPeerId
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["app": "peers"], serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    func startBrowsing() {
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        browser.delegate = nil
    }
    
    func startAdvertising() {
        timeStarted = Date()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        advertiser.delegate = nil
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
    }

    func sendData(_ data: Data, to peers: [MCPeerID]? = nil) {
        do {
            let toPeers = peers ?? session.connectedPeers
            let peersLog: String = toPeers.map { $0.displayName }.joined(separator: "\n")
            print("I am \(myPeerId.displayName). Sending data to peers: \(peersLog).")
            try session.send(data, toPeers: toPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("I am \(myPeerId.displayName). Received data from peer: \(peerID.displayName).")
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = jsonObject as? [String: Any],
               let email = dictionary["email"] as? String,
               let name = dictionary["name"] as? String {
                let phone = dictionary["phone"] as? String
                let job = dictionary["job"] as? String
                print("name: \(name), email: \(email)")
            }
        } catch {
            print("Error converting data to dictionary: \(error.localizedDescription)")
        }

    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        invitationHandler(true, session)
        /*
        guard let context else {
            invitationHandler(false, session)
            return
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: context, options: [])
            guard let dictionary = jsonObject as? [String: Any],
                let peerRunningTime = dictionary["runningTime"] as? TimeInterval else {
                invitationHandler(false, session)
                return
            }
            let runningTime = -timeStarted.timeIntervalSinceNow
            let isPeerOlder = (peerRunningTime > runningTime)
            invitationHandler(isPeerOlder, session)
        } catch {
            invitationHandler(false, session)
            return
        }*/
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task {
            await removeFromDiscoveredPeers(peerID)
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peerID: \(peerID), state: \(state.description)")
        switch state {
        case .connected:
            advertiser.stopAdvertisingPeer()
            let userInfo = ["name": name, "email": email, "phone": phone, "job": job]
            // check if I invited this person before sending data
            if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
                sendData(data, to: [peerID])
            }
        case .connecting:
            break
        case .notConnected:
            advertiser.startAdvertisingPeer()
            break
        @unknown default:
            break
        }
    }
    
    //
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard info?["app"] == "peers" else { return }
        //let runningTime = -timeStarted.timeIntervalSinceNow
        Task {
            await appendToDiscoveredPeers(peerID)
        }
        /* let userInfo = ["runningTime": runningTime]
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
            browser.invitePeer(peerID, to: session, withContext: data, timeout: 10)
        }*/
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        print("I am \(myPeerId.displayName), inviting \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    @MainActor
    func appendToDiscoveredPeers(_ peerID: MCPeerID) {
        self.discoveredPeers.append(peerID)
    }
    
    @MainActor
    func removeFromDiscoveredPeers(_ peerID: MCPeerID) {
        self.discoveredPeers.removeAll { $0 == peerID }
    }
}

extension MCSessionState {
    var description: String {
        switch self {
        case .connected:
            "connected"
        case .connecting:
            "connecting"
        case .notConnected:
            "notConnected"
        @unknown default:
            "unknown"
        }
    }
}
