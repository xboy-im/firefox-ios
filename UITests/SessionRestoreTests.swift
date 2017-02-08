/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import EarlGrey

/// This test should be disabled since session restore does not seem to work
class SessionRestoreTests: KIFTestCase {
    fileprivate var webRoot: String!
    
    override func setUp() {
        webRoot = SimplePageServer.start()
		BrowserUtils.dismissFirstRunUI()
        super.setUp()
    }
    
    func testTabRestore() {
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        let url2 = "\(webRoot)/numberedPage.html?page=2"
        let url3 = "\(webRoot)/numberedPage.html?page=3"
        
        // Build a session restore URL from the current homepage URL.
        var jsonDict = [String: AnyObject]()
        jsonDict["history"] = [url1, url2, url3]
        jsonDict["currentPage"] = -1 as AnyObject?
        let escapedJSON = JSON.stringify(jsonDict, pretty: false).stringByAddingPercentEncodingWithAllowedCharacters(CharacterSet.URLQueryAllowedCharacterSet())!
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        let restoreURL = URL(string: "/about/sessionrestore?history=\(escapedJSON)", relativeToURL: webView.URL!)
        
        // Enter the restore URL and verify the back/forward history.
        // After triggering the restore, the session should look like this:
        //   about:home, page1, *page2*, page3
        // where page2 is active.
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("address"))
			.performAction(grey_typeText("\(restoreURL!.absoluteString!)\n"))
		tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Back"))
			.performAction(grey_tap())
		
		tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Back"))
			.performAction(grey_tap())
		let wentBack = GREYCondition(name: "Check browser went back", block: { _ in
			var errorOrNil: NSError?
			let matcher = grey_allOfMatchers(grey_accessibilityLabel("Top sites"),
				grey_sufficientlyVisible())
			EarlGrey().selectElementWithMatcher(matcher)
				.assertWithMatcher(grey_notNil(), error: &errorOrNil)
			let success = errorOrNil == nil
			return success
		}).waitWithTimeout(5)
		GREYAssertTrue(wentBack, reason: "Didn't go back")
		
		let canGoBack: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Back")
            canGoBack = true
        } catch _ {
            canGoBack = false
        }
        XCTAssertFalse(canGoBack, "Reached the beginning of browser history")
		
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Forward"))
			.performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Forward"))
			.performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Forward"))
			.performAction(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("Page 3")
        let canGoForward: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Forward")
            canGoForward = true
        } catch _ {
            canGoForward = false
        }
        XCTAssertFalse(canGoForward, "Reached the end of browser history")
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
