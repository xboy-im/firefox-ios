/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

class BrowserTests: KIFTestCase {
	
	private var webRoot: String!
	
	override func setUp() {
		super.setUp()
		webRoot = SimplePageServer.start()
		BrowserUtils.dismissFirstRunUI()
	}
	
	override func tearDown() {
		BrowserUtils.resetToAboutHome(tester())
		BrowserUtils.clearPrivateData(tester: tester())
		super.tearDown()
	}
	
	func testDisplaySharesheetWhileJSPromptOccurs() {
		let url = "\(webRoot)/JSPrompt.html"
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("url"))
			.performAction(grey_tap())
		EarlGrey().selectElementWithMatcher(grey_accessibilityID("address"))
			.performAction(grey_typeText("\(url)\n"))
		tester().waitForWebViewElementWithAccessibilityLabel("JS Prompt")
		
		// Show share sheet and wait for the JS prompt to fire
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Share")).performAction((grey_tap()))
		let matcher = grey_allOfMatchers(grey_accessibilityLabel("Cancel"),
		                                 grey_accessibilityTrait(UIAccessibilityTraitButton),
		                                 grey_sufficientlyVisible())
		EarlGrey().selectElementWithMatcher(matcher)
			.performAction(grey_tap())


		// Check to see if the JS Prompt is dequeued and showing
		EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("OK"))
			.inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")))
			.assertWithMatcher(grey_enabled())
			.performAction((grey_tap()))
	}
}
