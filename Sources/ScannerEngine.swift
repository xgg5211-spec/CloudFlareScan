import Foundation
import Network

struct IPResult: Identifiable, Sendable {
    let id = UUID()
    let ip: String
    let latency: Int
}

actor ScannerEngine: ObservableObject {
    @MainActor @Published var results: [IPResult] = []
    @MainActor @Published var isScanning = false

    func startScan(ipList: [String]) async {
        await MainActor.run {
            self.isScanning = true
            self.results.removeAll()
        }

        await withTaskGroup(of: IPResult?.self) { group in
            for ip in ipList {
                group.addTask { await self.testTLS(ip: ip) }
            }
            for await res in group {
                if let res = res {
                    await MainActor.run { self.results.append(res) }
                }
            }
        }

        await MainActor.run {
            self.results.sort { $0.latency < $1.latency }
            self.isScanning = false
        }
    }

    private func testTLS(ip: String) async -> IPResult? {
        let start = CFAbsoluteTimeGetCurrent()
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: 443)
        let params = NWParameters(tls: NWProtocolTLS.Options())
        let conn = NWConnection(to: endpoint, using: params)

        return await withCheckedContinuation { continuation in
            conn.stateUpdateHandler = { state in
                if state == .ready {
                    let ms = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                    conn.cancel()
                    continuation.resume(returning: IPResult(ip: ip, latency: ms))
                } else if case .failed = state {
                    conn.cancel()
                    continuation.resume(returning: nil)
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                conn.cancel()
                continuation.resume(returning: nil)
            }
            conn.start(queue: .global())
        }
    }
}
