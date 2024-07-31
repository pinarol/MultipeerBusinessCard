import SwiftUI
import MultipeerConnectivity
import SwiftData

struct MCPeer: Identifiable, Hashable {
    var peerID: MCPeerID
    var state: MCSessionState?
    var isInvited: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peerID.displayName)
    }
    
    public var id: String { peerID.displayName }
}

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
        /*if let peer = findPeerByID(peerID) {
            print("I am \(myPeerId.displayName). Updating peer: \(peerID.displayName), \(name), \(email)")
            peer.email = email
            peer.name = name
            peer.phone = phone
            peer.job = job
        } else {
            print("I am \(myPeerId.displayName). Adding a new peer: \(peerID.displayName), \(name), \(email)")
            let newPeer = Peer(displayName: peerID.displayName, lastSeen: nil, name: name, email: email, phone: phone, job: job)
            modelContext.insert(newPeer)
        }*/
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
        
        /*guard let context else {
            invitationHandler(false, session)
            return
        }*/
            /*let jsonObject = try JSONSerialization.jsonObject(with: context, options: [])
            guard let dictionary = jsonObject as? [String: Any],
                let peerRunningTime = dictionary["runningTime"] as? TimeInterval else {
                invitationHandler(false, session)
                return
            }
            let runningTime = -timeStarted.timeIntervalSinceNow
            let isPeerOlder = (peerRunningTime > runningTime)*/
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
           // await updateInDiscoveredPeers(with: peerID, state: state)
            
            switch state {
            case .connected:
                // Check if I invited this person before sending data
                /*let isInvited = await isInvited(peerID: peerID)
                // I might not be the inviting party but I opted-in to share my card automaticially
                let shouldShareMyData = isInvited || self.shareBackMyCardAutomaticially
                if shouldShareMyData {
                   sendMyCurrentInfo(to: [peerID])
                }
                 if shouldShareMyData {
                     //advertiser.stopAdvertisingPeer()
                 }*/
                sendMyCurrentInfo(to: [peerID])
            case .connecting:
                break
            case .notConnected:
               // advertiser?.startAdvertisingPeer()
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
    //
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard info?["app"] == "peers", peerID != myPeerId, peerID.displayName != previewPeerID, let session else { return }
        let runningTime = -timeStarted.timeIntervalSinceNow
        Task {
            await appendToDiscoveredPeers(peerID)
        }
        let userInfo = ["runningTime": runningTime]
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
            //browser.invitePeer(peerID, to: session, withContext: data, timeout: 10)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        print("I am \(myPeerId.displayName), inviting \(peerID.displayName)")
        Task {
            //await updateInDiscoveredPeers(with: peerID, isInvited: true)
            guard let session else { return }
            isHosting = true
            browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
/*
            if let index = await indexInDiscoveredPeers(peerID), discoveredPeers[index].state == .connected {
                sendMyCurrentInfo(to: [peerID])
            }
            else {
                guard let session else { return }
                browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
            }*/
        }
    }
    
    @MainActor
    func appendToDiscoveredPeers(_ peerID: MCPeerID) {
        if indexInDiscoveredPeers(peerID) == nil {
            self.discoveredPeers.append(peerID)
        }
        //self.discoveredPeers.append(MCPeer(peerID: peerID, state: nil))
    }
    
    @MainActor
    func clearDiscoveredPeers() {
        //self.discoveredPeers = []
    }
    
    @MainActor
    func removeFromDiscoveredPeers(_ peerID: MCPeerID) {
        if let index = self.discoveredPeers.firstIndex(where: { $0 == peerID }) {
            self.discoveredPeers.remove(at: index)
        }
        // self.discoveredPeers.removeAll { $0.peerID == peerID }
    }
    
    @MainActor
    func indexInDiscoveredPeers(_ peerID: MCPeerID) -> Array<MCPeer>.Index? {
        self.discoveredPeers.firstIndex(where: { $0 == peerID })
    }
    
  /*  @MainActor
    func updateInDiscoveredPeers(with peerID: MCPeerID, state: MCSessionState?) {
        if let index = indexInDiscoveredPeers(peerID) {
            var peer = discoveredPeers[index]
            peer.state = state
            discoveredPeers[index] = peer
        }
    }
    
    @MainActor
    func updateInDiscoveredPeers(with peerID: MCPeerID, isInvited: Bool) {
        if let index = indexInDiscoveredPeers(peerID) {
            var peer = discoveredPeers[index]
            peer.isInvited = isInvited
            discoveredPeers[index] = peer
        }
    }
    
    @MainActor
    func isInvited(peerID: MCPeerID) -> Bool {
        if let index = indexInDiscoveredPeers(peerID) {
            return discoveredPeers[index].isInvited
        }
        return false
    }
   */
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
