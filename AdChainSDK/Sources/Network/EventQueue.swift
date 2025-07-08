import Foundation

internal class EventQueue {
    static let shared = EventQueue()
    
    private var events: [AnalyticsEvent] = []
    private let queue = DispatchQueue(label: "com.adchain.sdk.eventqueue", attributes: .concurrent)
    private let maxQueueSize = 100
    
    private init() {}
    
    func add(_ event: AnalyticsEvent) {
        queue.async(flags: .barrier) {
            if self.events.count >= self.maxQueueSize {
                self.events.removeFirst()
            }
            self.events.append(event)
        }
    }
    
    func flush(completion: @escaping ([AnalyticsEvent]) -> Void) {
        queue.async(flags: .barrier) {
            let eventsToFlush = self.events
            self.events.removeAll()
            
            DispatchQueue.main.async {
                completion(eventsToFlush)
            }
        }
    }
    
    func size() -> Int {
        return queue.sync {
            return events.count
        }
    }
}