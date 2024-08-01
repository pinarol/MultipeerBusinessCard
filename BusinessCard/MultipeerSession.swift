import SwiftUI
import MultipeerConnectivity
import SwiftData

class MultipeerSession: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let serviceType = "my-peers"
    private var myPeerId: MCPeerID
    private(set) var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var timeStarted: Date = Date()
    private var modelContext: ModelContext
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var incomingPeerInfo: [String: Peer] = [:]
    @AppStorage("name") private var name: String = ""
    @AppStorage("email") private var email: String = ""
    @AppStorage("phone") private var phone: String = ""
    @AppStorage("job") private var job: String = ""
    @AppStorage("shareBackMyCardAutomaticially") private var shareBackMyCardAutomaticially: Bool = true
    var didReceiveInvitationHandler: ((_ fromPeer: MCPeerID, _ invitationHandler: @escaping (Bool, MCSession?) -> Void) -> ())?
    var didAcceptInvitation: (() -> ())?
    var isHosting: Bool = false
    init(modelContext: ModelContext, myPeerId: MCPeerID) {
        self.modelContext = modelContext
        self.myPeerId = myPeerId
        super.init()
    }
    
    func startSession() {
        print("I am \(myPeerId.displayName). Starting session.")
        incomingPeerInfo = [:]
        discoveredPeers = []
        isHosting = false
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["app": "peers"], serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        session?.delegate = self
        advertiser?.delegate = self
        browser?.delegate = self
        timeStarted = Date()
        startAdvertising()
    }
    
    func restartSession() {
        disconnect()
        startSession()
    }
    
    func disconnect() {
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
    }
    
    func startBrowsing() {
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
    }
    
    private func startAdvertising() {
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
    }
    
    deinit {
        disconnect()
    }
    
    func sendData(_ data: Data, to peers: [MCPeerID]? = nil) {
        do {
            let toPeers = peers ?? session?.connectedPeers
            guard let toPeers else { return }
            let peersLog: String = toPeers.map { $0.displayName }.joined(separator: "\n")
            print("I am \(myPeerId.displayName). Sending data to peers: \(peersLog).")
            try session?.send(data, toPeers: toPeers, with: .reliable)
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
                Task {
                    await addOrUpdatePeer(peerID:peerID, email:email, name:name, phone: phone, job:job)
                }
            }
        } catch {
            print("Error converting data to dictionary: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addOrUpdatePeer(peerID: MCPeerID, email: String, name: String, phone: String?, job: String?) {
        incomingPeerInfo[peerID.displayName] = Peer(displayName: peerID.displayName, lastSeen: nil, name: name, email: email, phone: phone, job: job)
    }
    
    @MainActor
    func persistPeers(_ peers: [Peer]) {
        for peerIter in peers {
            if let peer = findPeerByID(peerIter.displayName) {
                print("I am \(myPeerId.displayName). Updating peer: \(peerIter.displayName), \(String(describing: peerIter.name)), \(String(describing: peerIter.email))")
                peer.email = peerIter.email
                peer.name = peerIter.name
                peer.phone = peerIter.phone
                peer.job = peerIter.job
            } else {
                print("I am \(myPeerId.displayName). Adding a new peer: \(peerIter.displayName), \(String(describing: peerIter.name)), \(String(describing: peerIter.email))")
                modelContext.insert(peerIter)
            }
        }
    }
    
    func findPeerByID(_ displayName: String) -> Peer? {
        var result: Peer?
        do {
            let idToSearch = displayName // "idToSearch" is defined to ignore the weird compiler error
            var fetchDescriptor = FetchDescriptor<Peer>(predicate: #Predicate { peer in
                peer.displayName == idToSearch
            })
            fetchDescriptor.fetchLimit = 1
            result = try modelContext.fetch(fetchDescriptor).first
        }
        catch {
            print("Error fetching Peer with id: \(displayName), error: \(String(describing: error))")
        }
        return result
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        /*Task {
         let isInvited = await isInvited(peerID: peerID)
         invitationHandler(!isInvited, session)
         }
         */
        
        print("I am \(myPeerId.displayName), didReceiveInvitationFromPeer: \(peerID.displayName)")
        print("I am \(myPeerId.displayName), isHosting: \(isHosting)")
        
        if !isHosting {
            if let didReceiveInvitationHandler {
                // delegate the invitation to user consent
                didReceiveInvitationHandler(peerID, invitationHandler)
            }
            else {
                print("I am \(myPeerId.displayName), accepting invitation from: \(peerID.displayName)")
                invitationHandler(true, session)
                didAcceptInvitation?()
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task {
            await removeFromDiscoveredPeers(peerID)
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peerID: \(peerID), state: \(state.description)")
        Task {
            switch state {
            case .connected:
                advertiser?.stopAdvertisingPeer()
                sendMyCurrentInfo(to: [peerID])
            case .connecting:
                break
            case .notConnected:
                advertiser?.startAdvertisingPeer()
                break
            @unknown default:
                break
            }
        }
    }
    
    func sendMyCurrentInfo(to peers: [MCPeerID]) {
        let userInfo = ["name": name, "email": email, "phone": phone, "job": job]
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
            sendData(data, to: peers)
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard info?["app"] == "peers", peerID != myPeerId, peerID.displayName != myPeerId.displayName, peerID.displayName != previewPeerID else { return }
        Task {
            await appendToDiscoveredPeers(peerID)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        print("I am \(myPeerId.displayName), inviting \(peerID.displayName)")
        Task {
            guard let session else { return }
            isHosting = true
            browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }
    }
    
    @MainActor
    func appendToDiscoveredPeers(_ peerID: MCPeerID) {
        if indexInDiscoveredPeers(peerID) == nil {
            self.discoveredPeers.append(peerID)
        }
    }
    
    @MainActor
    func removeFromDiscoveredPeers(_ peerID: MCPeerID) {
        if let index = self.discoveredPeers.firstIndex(where: { $0 == peerID }) {
            self.discoveredPeers.remove(at: index)
        }
    }
    
    @MainActor
    func indexInDiscoveredPeers(_ peerID: MCPeerID) -> Array<MCPeerID>.Index? {
        self.discoveredPeers.firstIndex(where: { $0 == peerID })
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
