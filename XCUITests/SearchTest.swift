/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar meaning"
private let SuggestedSite2: String = "foobar2000"
private let SuggestedSite3: String = "foobar2000 mac"

private let SuggestedSite4: String = "foo bar baz"
private let SuggestedSite5: String = "foo bar baz qux"
private let SuggestedSite6: String = "foobar bit perfect"



class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        waitForExistence(app.textFields["address"])
        app.textFields["address"].typeText(text)
    }

    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForNoExistence(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        waitForExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Disable Search suggestion
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        suggestionsOnOff()

        // Suggestions should not be shown
        waitForNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Verify that previous choice is remembered
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)

        // Reset suggestion button, set it to on
        suggestionsOnOff()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)

        // Suggestions prompt should appear
        typeOnSearchBar(text: "foobar")
        waitForExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }

    // Promt does not appear once Search has been enabled by default, see bug: 1411184
    func testDismissPromptPresence() {
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForExistence(app.staticTexts[LabelPrompt])

        app.buttons["No"].tap()
        waitForNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        app.buttons["Go"].tap()
        navigator.nowAt(BrowserTab)
        // Verify that it is possible to enable suggestions after selecting No
        suggestionsOnOff()
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }

    func testDoNotShowSuggestionsWhenEnteringURL() {
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string,
        // the suggestions are shown again
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitForNoExistence(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        waitForExistence(app.tables["SiteTable"])
        if !(app.tables["SiteTable"].buttons[SuggestedSite].exists) {
            if !(app.tables["SiteTable"].buttons[SuggestedSite2].exists) {
                waitForExistence(app.tables["SiteTable"].buttons[SuggestedSite3])
            }
        }

        // Typing / should stop showing suggestions
        app.textFields["address"].typeText("/")
        waitForNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Typing space and char after / should show suggestions again
        app.textFields["address"].typeText(" b")
        waitForExistence(app.tables["SiteTable"])
        if !(app.tables["SiteTable"].buttons[SuggestedSite4].exists) {
            if !(app.tables["SiteTable"].buttons[SuggestedSite5].exists) {
                waitForExistence(app.tables["SiteTable"].buttons[SuggestedSite6])
            }
        }
    }

    func testCopyPasteComplete() {
        // Copy, Paste and Go to url
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.mozilla.org")
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        waitForExistence(app.buttons["goBack"])
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].tap()
        waitForExistence(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()

        // Verify that the Paste shows the search controller with prompt
        waitForNoExistence(app.staticTexts[LabelPrompt])
        app.typeText("\r")

        // Check that the website is loaded
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org")

        // Go back, write part of moz, check the autocompletion
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "moz")
        waitForValueContains(app.textFields["address"], value: "mozilla.org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "mozilla.org")
    }

    private func changeSearchEngine(searchEngine: String) {
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).tap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts[searchEngine].tap()

        navigator.openURL("foo")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: searchEngine.lowercased())
        }

    // Smoketest
    func testSearchEngine() {
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        changeSearchEngine(searchEngine: "DuckDuckGo")
        // Temporary disabled due to intermittent issue on BB
        // changeSearchEngine(searchEngine: "Google")
        // changeSearchEngine(searchEngine: "Twitter")
        // changeSearchEngine(searchEngine: "Wikipedia")
        // changeSearchEngine(searchEngine: "Amazon.com")
    }

    func testDefaultSearchEngine() {
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
    }

    func testSearchWithFirefoxOption() {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        waitForExistence(app.webViews.staticTexts["cloud"], timeout: 10)
        // Select some text and long press to find the option
        app.webViews.staticTexts["cloud"].press(forDuration: 1)
        if !iPad() {
            waitForExistence(app.menus.children(matching: .menuItem).element(boundBy: 3))
            app.menus.children(matching: .menuItem).element(boundBy: 3).tap()
        }
        waitForExistence(app.menuItems["Search with Firefox"])
        app.menuItems["Search with Firefox"].tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "google")
        // Now there should be two tabs open
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)
    }
}
