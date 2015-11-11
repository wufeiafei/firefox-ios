/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit


let browsingActivityType: String = "org.mozilla.firefox.browsing"

class SpotlightHelper {
    private(set) var activity: NSUserActivity? {
        didSet {
//            activity?.delegate =
        }
    }

    init () {

    }

    deinit {

    }

    func createUserActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: browsingActivityType)
        self.activity = activity
        return activity
    }

}


extension SpotlightHelper: BrowserHelper {
    static func name() -> String {
        return "SpotlightHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return nil
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Never called.
    }
}
