/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
class NightModeTests: BaseTestCase {

    private func checkNightModeOn() {
        waitForExistence(app.tables.cells["menu-NightMode"])
        XCTAssertTrue(app.tables.cells.images["enabled"].exists)
    }

    private func checkNightModeOff() {
        waitForExistence(app.tables.cells["menu-NightMode"])
        XCTAssertTrue(app.tables.cells.images["disabled"].exists)
    }

    func testNightModeUI() {
        let url1 = "test-example.html"

        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openURL(path(forTestPage: url1))

        //turn on the night mode
        navigator.performAction(Action.ToggleNightMode)

        //checking night mode on or off
        checkNightModeOn()

        //turn off the night mode
        navigator.performAction(Action.ToggleNightMode)

        //checking night mode on or off
        checkNightModeOff()
    }
}
