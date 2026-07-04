import Foundation
import Network

final class NetworkMonitor: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let lock = NSLock()
    private var _onChangeCallback: (@Sendable (NWPath.Status) -> Void)?
    private var _isStarted = false

    var onChange: (@Sendable (NWPath.Status) -> Void)? {
        get { lock.withLock { _onChangeCallback } }
        set {
            lock.withLock {
                _onChangeCallback = newValue
            }
            if newValue != nil {
                let shouldStart = lock.withLock {
                    if !_isStarted {
                        _isStarted = true
                        return true
                    }
                    return false
                }
                if shouldStart { start() }
            }
        }
    }

    private func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let callback = self.lock.withLock { self._onChangeCallback }
            callback?(path.status)
        }
        monitor.start(queue: .global())
    }

    func stop() {
        monitor.cancel()
        lock.withLock {
            _isStarted = false
            _onChangeCallback = nil
        }
    }
}
