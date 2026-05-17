import UIKit
import Social
import UniformTypeIdentifiers

/// Minimal share target: extract the URL (and any JS-preprocessed page text),
/// write a pending check to the App Group, then deep-link into the main app
/// which runs the heavy pipeline (extensions have tight memory limits).
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleShare()
    }

    private func handleShare() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = item.attachments else {
            return complete()
        }

        let group = DispatchGroup()
        var foundURL: URL?
        var pageText: String?

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { data, _ in
                    if let u = data as? URL { foundURL = u }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier) { data, _ in
                    if let dict = data as? NSDictionary,
                       let js = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary {
                        foundURL = (js["url"] as? String).flatMap(URL.init(string:)) ?? foundURL
                        pageText = js["text"] as? String
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
                    if let s = data as? String, let u = URL(string: s) { foundURL = u }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let url = foundURL else { return self?.complete() ?? () }
            let pending = PendingCheck(id: UUID(), url: url, pageText: pageText)
            SharedStore.shared.writePending(pending)
            self?.openHost(id: pending.id)
        }
    }

    private func openHost(id: UUID) {
        let deepLink = URL(string: "hypecheck://analyze?id=\(id.uuidString)")!
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(deepLink)
                break
            }
            responder = r.next
        }
        complete()
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
