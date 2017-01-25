/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
		super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .stringByReplacingOccurrencesOfString("127.0.0.1", withString: "localhost", options: NSStringCompareOptions(), range: nil)
        BrowserUtils.dismissFirstRunUI()
    }
	
	func enterUrl(url: String) {
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("address"))
			.performAction(grey_typeText("\(url)\n"))
	}
	
	func waitForReadingList() {
		let readingList = GREYCondition(name: "wait until Reading List Add btn appears", block: { _ in
			var errorOrNil: NSError?
			let matcher = grey_allOfMatchers(grey_accessibilityLabel("Add to Reading List"),
				grey_sufficientlyVisible())
			EarlGrey().selectElementWithMatcher(matcher)
				.assertWithMatcher(grey_notNil(), error: &errorOrNil)
			let success = errorOrNil == nil
			return success
		}).waitWithTimeout(20)
		
		GREYAssertTrue(readingList, reason: "Can't be added to Reading List")
	}
	
	func waitForEmptyReadingList() {
		let readable = GREYCondition(name: "Check readable list is empty", block: { _ in
			var errorOrNil: NSError?
			let matcher = grey_allOfMatchers(grey_accessibilityLabel("Readable page"),
			                                 grey_sufficientlyVisible())
			EarlGrey().selectElementWithMatcher(matcher)
				.assertWithMatcher(grey_notNil(), error: &errorOrNil)
			
			let success = errorOrNil != nil
			return success
		}).waitWithTimeout(10)
		GREYAssertTrue(readable, reason: "Read list should not appear")
	}

    /**
     * Tests opening reader mode pages from the urlbar and reading list.
     */
    func testReadingList() {
        // Load a page
        let url1 = "\(webRoot)/readablePage.html"
        enterUrl(url1)
		tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")
		
        // Add it to the reading list
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reader View"))
			.performAction(grey_tap())
		waitForReadingList()
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Add to Reading List"))
			.performAction(grey_tap())
		
		// Open a new page
        let url2 = "\(webRoot)/numberedPage.html?page=1"
		enterUrl(url2)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Check that it appears in the reading list home panel
        EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reading list"))
			.performAction(grey_tap())

        // Tap to open it
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("localhost"))
			.performAction(grey_tap())
		tester().waitForWebViewElementWithAccessibilityLabel("Readable page")
		
        // Remove it from the reading list
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Remove from Reading List"))
			.performAction(grey_tap())
		
        // Check that it no longer appears in the reading list home panel
        EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reading list"))
			.performAction(grey_tap())
		
		waitForEmptyReadingList()
		
		EarlGrey().selectElementWithMatcher(
			grey_allOfMatchers(grey_accessibilityLabel("Cancel"),
			grey_accessibilityTrait(UIAccessibilityTraitButton),
			grey_sufficientlyVisible()))
			.performAction(grey_tap())
    }

    func testReadingListAutoMarkAsRead() {
        // Load a page
        let url1 = "\(webRoot)/readablePage.html"
		
		enterUrl(url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

		// Add it to the reading list
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reader View"))
			.performAction(grey_tap())
		waitForReadingList()
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Add to Reading List"))
			.performAction(grey_tap())

        // Check that it appears in the reading list home panel and make sure it marked as unread
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reading list"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("MarkAsRead"))
			.inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")))
			.assertWithMatcher(grey_notNil())
		// Select to Read
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("localhost"))
			.performAction(grey_tap())
		tester().waitForWebViewElementWithAccessibilityLabel("Readable page")
		
        // Go back to the reading list panel
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Reading list"))
			.performAction(grey_tap())

        // Make sure the article is marked as read
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Readable page"))
		.assertWithMatcher(grey_notNil())
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("MarkAsUnread"))
			.inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")))
			.assertWithMatcher(grey_notNil())
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("localhost"))
			.assertWithMatcher(grey_notNil())
		
		// Remove the list entry
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Readable page"))
		.performAction(grey_swipeSlowInDirection(GREYDirection.Left))
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Remove"))
			.inRoot(grey_kindOfClass(NSClassFromString("_UITableViewCellActionButton")))
			.performAction(grey_tap())
		
		// check the entry no longer exist
		waitForEmptyReadingList()
   }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
		super.tearDown()
    }
}
