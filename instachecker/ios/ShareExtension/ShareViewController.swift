import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // This keeps the "Post" button enabled
        return true
    }

    override func didSelectPost() {
        // This is called when the user hits 'Post'
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                for attachment in attachments {
                    // Check for URL
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                        attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (url, error) in
                            if let shareURL = url as? URL {
                                self.openMainApp(url: shareURL)
                            }
                        }
                        break
                    }
                    // Check for Plain Text (Sometimes Instagram sends the link as text)
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                        attachment.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { (text, error) in
                            if let shareText = text as? String, let shareURL = URL(string: shareText) {
                                self.openMainApp(url: shareURL)
                            }
                        }
                        break
                    }
                }
            }
        }
        // Closes the share popup
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To keep it simple like an email app, we return an empty array
        return []
    }

    private func openMainApp(url: URL) {
        // This encodes the URL so it doesn't break the deep link
        let suffix = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        // IMPORTANT: "instachecker" must match the URL Scheme you set in Xcode
        let fullURL = URL(string: "instachecker://share?url=\(suffix)")!
        
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(fullURL, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
}