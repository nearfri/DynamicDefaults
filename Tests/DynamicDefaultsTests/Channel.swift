// Inspired by https://medium.com/developermind/using-channels-for-data-flow-in-swift-14bbdf27b471

public class Channel<Value> {
    private typealias SubscriptionID = ObjectIdentifier
    
    private var subscriptions: [SubscriptionID: Subscription] = [:]
    
    public init() {}
    
    public func addSubscriber(_ subscriber: AnyObject, using block: @escaping (Value) -> Void) {
        let subscription = Subscription(channel: self, subscriber: subscriber, block: block)
        subscriptions[SubscriptionID(subscription)] = subscription
    }
    
    public func addSubscriber(using block: @escaping (Value) -> Void) -> Subscriber {
        let subscriber = Subscriber()
        let subscription = Subscription(channel: self, subscriber: subscriber, block: block)
        subscriptions[SubscriptionID(subscription)] = subscription
        subscriber.subscription = subscription
        return subscriber
    }
    
    private func removeSubscription(_ subscription: Subscription) {
        subscriptions[SubscriptionID(subscription)] = nil
    }
    
    public func broadcast(_ value: Value) {
        for (_, subscription) in subscriptions {
            subscription.notify(value)
        }
    }
}

extension Channel {
    private class Subscription: Invalidatable {
        private weak var channel: Channel?
        private weak var subscriber: AnyObject?
        private let block: (Value) -> Void
        
        init(channel: Channel, subscriber: AnyObject, block: @escaping (Value) -> Void) {
            self.channel = channel
            self.subscriber = subscriber
            self.block = block
        }
        
        deinit {
            invalidate()
        }
        
        func invalidate() {
            channel?.removeSubscription(self)
            channel = nil
            subscriber = nil
        }
        
        func notify(_ value: Value) {
            if subscriber != nil {
                block(value)
            } else {
                invalidate()
            }
        }
    }
}

private protocol Invalidatable {
    func invalidate()
}

public class Subscriber {
    fileprivate var subscription: Invalidatable?
    
    fileprivate init() {}
    
    deinit {
        subscription?.invalidate()
    }
    
    public func invalidate() {
        subscription?.invalidate()
        subscription = nil
    }
}
