import XCTest

/** Extension to provide a convenient way to wait for a closure's fulfillment. */
public extension XCTWaiter {

    enum Error: Swift.Error {
        case timeout
    }

    /**
     Convenience API that creates a waiter object which then waits on the closure's fulfillment for up to
     the specified timeout. May return early based on fulfillment of the waited on expectations. The waiter
     is discarded when the wait completes.

     Throws `Error.timeout` if the closure did not return `true` within the specified time.

     - Parameters:
        - closure:  The closure whose fulfillment should be waited for.
        - timeout:  The time up to which the function waits on the closure's fulfillment.
     */
    static func wait(for closure: @escaping () -> Bool, timeout: TimeInterval = 60) throws {
        let predicate = NSPredicate(format: "isFulfilled == true")
        let wrapper = ClosureWrapper(closure: closure)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: wrapper)
        guard case .completed = self.wait(for: [expectation], timeout: timeout) else {
            throw Error.timeout
        }
    }

}

/**
 Wrapper object to make the fulfillment of a closure observable by predicate expectations to provide a possibility to
 wait for it's fulfillment. That's why it needs to be inherited from `NSObject` and the `isFullfilled` method needs to
 be prefixed with `@objc` to ensure the proper evaluation of the `NSPredicate` checking this property. Changing this
 will make the predicate _failing_ silent after the timeout.
 */
class ClosureWrapper: NSObject {

    /** The closure which is called to check whether the expectation is (already) fulfilled. */
    let closure: () -> Bool

    /**
     Designated initializer.

     - Parameters:
        - closure: The closure which is called to check whether the expectation is (already) fulfilled.
     */
    fileprivate init(closure: @escaping () -> Bool) {
        self.closure = closure
    }

    /** The property which is observed by `XCTNSPredicateExpectation` inside `XCTWaiter`'s `wait(for:timeout:)`. */
    @objc var isFulfilled: Bool {
        return closure()
    }

}
