import SwiftUI
import MultipeerConnectivity

class BrowserCoordinator: NSObject, MCBrowserViewControllerDelegate {
    var parent: MCBrowserView

    init(parent: MCBrowserView) {
        self.parent = parent
    }

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        parent.isPresented = false
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        parent.isPresented = false
    }
}
