/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
class DesktopModeTests: BaseTestCase {

    func testClearPrivateData() {
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Go to Clear Data
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        
        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testSameHostInMultipleTabs() {
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Tab #3
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testPrivateModeOffAlsoRemovesFromNormalMode() {
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite) // toggle on
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now on in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite) // toggle off
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // is now off in private, mode, confirm it is off in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testPrivateModeOnHasNoAffectOnNormalMode() {
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }
}
