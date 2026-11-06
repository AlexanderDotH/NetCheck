import Foundation

public actor TracerouteService {
    public var destination: String = "8.8.8.8"
    public init() {}

    public func run() -> AsyncStream<TracerouteHop> {
        let dest = destination
        return AsyncStream { continuation in
            Task {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/traceroute")
                process.arguments = ["-n", "-q", "1", "-w", "2", dest]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                do {
                    try process.run()
                } catch {
                    continuation.finish()
                    return
                }

                var hopId = 0
                // Les lectures peuvent couper une ligne en deux : on ne parse que des lignes complètes
                var pending = Data()
                let handle = pipe.fileHandleForReading
                func emit(_ lineData: Data) {
                    guard let line = String(data: lineData, encoding: .utf8),
                          let hop = TracerouteService.parse(line: line, id: hopId) else { return }
                    hopId += 1
                    continuation.yield(hop)
                }
                while true {
                    let data = handle.availableData
                    if data.isEmpty { break }
                    pending.append(data)
                    while let newline = pending.firstIndex(of: UInt8(ascii: "\n")) {
                        emit(pending[pending.startIndex..<newline])
                        pending = Data(pending[pending.index(after: newline)...])
                    }
                }
                if !pending.isEmpty { emit(pending) }

                process.waitUntilExit()
                continuation.finish()
            }
        }
    }

    public static func parse(line: String, id: Int) -> TracerouteHop? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.first?.isNumber == true else { return nil }

        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, Int(parts[0]) != nil else { return nil }

        // "3  * * *" (-q 3) ou "3  *" (-q 1) : pas de réponse pour ce saut
        if parts[1] == "*" {
            return TracerouteHop(id: id, ip: nil, latencyMs: nil,
                                 city: nil, country: nil, latitude: nil, longitude: nil, asn: nil)
        }

        guard parts.count >= 3, isIPAddress(parts[1]) else { return nil }
        let ip = parts[1]
        let latency = Double(parts[2])
        return TracerouteHop(id: id, ip: ip, latencyMs: latency,
                             city: nil, country: nil, latitude: nil, longitude: nil, asn: nil)
    }

    static func isIPAddress(_ value: String) -> Bool {
        var v4 = in_addr()
        var v6 = in6_addr()
        return inet_pton(AF_INET, value, &v4) == 1 || inet_pton(AF_INET6, value, &v6) == 1
    }
}
