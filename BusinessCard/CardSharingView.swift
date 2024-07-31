//
//  CardSharingView.swift
//  BusinessCard
//
//  Created by Pinar Olguc on 30.07.2024.
//

import SwiftUI
import SwiftData
import MultipeerConnectivity

struct CardSharingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("name") private var name: String = ""
    @AppStorage("email") private var email: String = ""
    @AppStorage("phone") private var phone: String = ""
    @AppStorage("job") private var job: String = ""
    @Query(sort: \Peer.name, order: .forward) private var peers: [Peer]
    @State private var errorMessage: String? = nil
    @State private var isBrowserPresented = false
    @ObservedObject var multipeerSession: MultipeerSession
    @State private var isSharingSessionPresented = false

    var body: some View {
            VStack {
                List {
                    myEditableCard().listRowSeparator(.hidden)
                    if let errorMessage = errorMessage {
                        inlineErrorView(errorMessage).listRowSeparator(.hidden)
                    }
                    connectionsSectionHeader().listRowSeparator(.hidden)
                    if peers.isEmpty {
                        Text("You don't have any connections yet. Why not start adding some?")
                            .listRowSeparator(.hidden)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Section {
                        ForEach(peers) { peer in
                            CardView(peer: peer)
                                .listRowSeparator(.hidden)
                            
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .listStyle(PlainListStyle())
                .selectionDisabled()
                .listRowSeparatorTint(.clear)
            }
            .sheet(isPresented: $isBrowserPresented) {
                BrowsePeers(peerIDs: $multipeerSession.discoveredPeers) { peerIDs in
                    for peerID in peerIDs {
                        multipeerSession.invitePeer(peerID)
                    }
                    withAnimation {
                        isBrowserPresented = false
                    }
                    completion: {
                        isSharingSessionPresented = true
                    }
                }.onAppear() {
                    multipeerSession.startBrowsing()
                }
                .onDisappear() {
                    multipeerSession.stopBrowsing()
                }
            }
            .sheet(isPresented: $isSharingSessionPresented) {
                SharingSessionView(peers: $multipeerSession.incomingPeerInfo) { peers in
                    multipeerSession.persistPeers(peers)
                    isSharingSessionPresented = false
                    multipeerSession.restartSession()
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear() {
                multipeerSession.didAcceptInvitation = {
                    isSharingSessionPresented = true
                }
                multipeerSession.startSession()
            }
            .onDisappear() {
             //   multipeerSession.stopAdvertising()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: Page.settings) {
                        Label {
                            
                        } icon: {
                            Image(systemName: "gearshape")
                        }

                    }
                }
            }
    }
    
    private func inlineErrorView(_ errorMessage: String) -> some View {
        // Error message view
        Text(errorMessage)
            .foregroundColor(.red)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 10)
            .transition(.opacity)
            .listRowSeparator(.hidden)
    }
    
    private func connectionsSectionHeader() -> some View {
        HStack(alignment: .center) {
            Text("Connections")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
            Spacer()
            
            menuToAddPeer(
                label:
                    Button("+ Add") {
                        
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(UIColor.white))
                    .padding(.init(top: 3, leading: 8, bottom: 3, trailing: 8))
                    .background(Color(UIColor.tintColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                , addAnotherPeer: true
            )
        }
        .padding(.init(top: 24, leading: 0, bottom: 8, trailing: 0))
    }
    
    private func myEditableCard() -> some View {
        VStack {
            HStack {
                TextField("Name Surname", text: $name)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.alphabet)
                    .disableAutocorrection(true)
                    .font(.title2)
                    .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                Spacer()
                menuToAddPeer(
                    label:
                        Button(
                            action: { },
                            label: { Label("", systemImage: "square.and.arrow.up") }
                        ),
                    addAnotherPeer: false
                )
            }
            TextField("Job", text: $job)
                .textInputAutocapitalization(.never)
                .keyboardType(.alphabet)
                .disableAutocorrection(true)
                .font(.headline)
                .padding(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .font(.subheadline)
            TextField("+(10) 453 56 43", text: $phone)
                .textInputAutocapitalization(.never)
                .keyboardType(.phonePad)
                .disableAutocorrection(true)
                .font(.footnote)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .foregroundColor(Color(UIColor.label))
    }
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(peers[index])
            }
        }
    }
    
    // Function to create a menu with the given label
    func menuToAddPeer<LabelType: View>(label: LabelType, addAnotherPeer: Bool) -> some View {
        return Menu {
            Button(action: {
                if addAnotherPeer {
                    print("Open camera to scan QR Code")
                }
                else {
                    print("Show my QR Code")
                }
                showError(message: "This operation is not supported yet.")
            }) {
                Label(addAnotherPeer ? "Scan QR code" : "QR code", systemImage: "qrcode")
            }
            
            Button(action: {
                browseForPeers()
            }) {
                Label("Nearby peers", systemImage: "plus.magnifyingglass")
            }
        } label: {
            label
        }
    }
    
    func browseForPeers() {
        guard !name.isEmpty, !email.isEmpty else {
            showError(message: "Please fill in Name and Email to continue")
            return
        }
        isBrowserPresented = true
    }
    
    // Function to show the error message temporarily
    private func showError(message: String) {
        withAnimation {
            errorMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                errorMessage = nil
            }
        }
    }
}

@MainActor
struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let previewUserDefaults: UserDefaults = {
            let userDefaults = UserDefaults(suiteName: "Testing")!
            userDefaults.set("Pinar Olg", forKey: "name")
            userDefaults.set("email@domain.com", forKey: "email")
            userDefaults.set("+90 (216) 645 56 32", forKey: "phone")
            userDefaults.set("Software Dev", forKey: "job")
            return userDefaults
        }()
        CardSharingView(multipeerSession: MultipeerSession(modelContext: previewContainer.mainContext, myPeerId: MCPeerID(displayName: previewPeerID)))
            .modelContainer(previewContainer)
            .defaultAppStorage(previewUserDefaults)
    }
}

let previewPeerID: String = "PeerID"

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(for: Peer.self,
                                           configurations: .init(isStoredInMemoryOnly: true))
        
        let samplePeers = [
            Peer(displayName: "Sir Tom Jones", lastSeen: Date(), name: "Tom Jones", email: "tomjones@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
            Peer(displayName: "Celine Dion", lastSeen: Date(), name: "Celine Dion", email: "celine@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
            Peer(displayName: "Mariah Carey", lastSeen: Date(), name: "Mariah Carey", email: "mariah@domain.com", phone: "+90 (216) 645 56 32", job: "Singer"),
        ]
        
        for peer in samplePeers {
            container.mainContext.insert(peer)
        }
        
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()
