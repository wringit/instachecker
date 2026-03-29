import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Return true so the "Post" button is clickable
        return true
    }

    override func didSelectPost() {
        // This runs when the user taps "Post" or the App Icon
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let attachment = item.attachments?.first {
            
            // Look for a URL (The Instagram Reel link)
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                    if let shareURL = url as? URL {
                        self?.openMainApp(with: shareURL)
                    }
                }
            }
        }
    }

    private func openMainApp(with url: URL) {
        // This builds the custom "teleport" command
        let scheme = "instachecker://teleport?url=\(url.absoluteString)"
        
        if let openURL = URL(string: scheme) {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(openURL, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
            // Closes the share sheet and returns to the original app (Instagram)
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}