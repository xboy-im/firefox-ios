//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import Shared
import XCTest

private let timeoutPeriod: NSTimeInterval = 600

class PushClientTests: XCTestCase {

    var endpointURL: NSURL {
        return DeveloperPushConfiguration().endpointURL
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testClientRegistration() {
        let expectation = expectationWithDescription(#function)
        let num = arc4random_uniform(1 << 31)
        let deviceID = "test-id-deadbeef-\(num)"
        let client = PushClient(endpointURL: endpointURL)

        client.register(deviceID) >>== { registration in
            print("Registered: \(registration.uaid)")

            client.unregister(registration).upon { _ in
                print("Unregistered: \(registration.uaid)")
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(timeoutPeriod, handler: nil)
    }
}
