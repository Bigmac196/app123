import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum FetchError: Error, LocalizedError {
    case invalidURL
    case http(Int)
    case empty
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "That doesn't look like a valid product link."
        case .http(let c): return "The store blocked or couldn't serve the page (HTTP \(c))."
        case .empty: return "The page returned no readable content."
        case .transport(let m): return "Network problem: \(m)"
        }
    }
}

/// On-device, user-initiated single-page fetch. Uses a realistic desktop
/// User-Agent and follows redirects. No third-party services involved.
public struct PageFetcher: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchHTML(from url: URL) async throws -> String {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw FetchError.invalidURL
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
            + "(KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent")
        req.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse,
               !(200..<400).contains(http.statusCode) {
                throw FetchError.http(http.statusCode)
            }
            guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1), !html.isEmpty else {
                throw FetchError.empty
            }
            return html
        } catch let e as FetchError {
            throw e
        } catch {
            throw FetchError.transport(error.localizedDescription)
        }
    }
}
