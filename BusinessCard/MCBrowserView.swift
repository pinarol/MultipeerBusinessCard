import SwiftUI
import MultipeerConnectivity

struct MCBrowserView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let session: MCSession
    let peerID: MCPeerID
    let serviceType: String

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let browser = MCBrowserViewController(serviceType: serviceType, session: session)
        browser.delegate = context.coordinator
        return browser
    }

    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {
        if isPresented {
            uiViewController.presentedViewController?.dismiss(animated: true, completion: nil)
        } else {
            uiViewController.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> BrowserCoordinator {
        BrowserCoordinator(parent: self)
    }
}
