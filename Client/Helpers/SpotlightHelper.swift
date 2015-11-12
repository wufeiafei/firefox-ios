/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit


let browsingActivityType: String = "org.mozilla.firefox.browsing"

class SpotlightHelper: NSObject {
    private(set) var activity: NSUserActivity? {
        willSet {
            print("invalidating \(activity?.webpageURL)")
            activity?.invalidate()
        }
        didSet {
            activity?.delegate = self
        }
    }

    private let createNewTab: (url: NSURL) -> ()

    init (createNewTab openURL: (url: NSURL) -> ()) {
        createNewTab = openURL
    }

    deinit {
        // Invalidate the currently held user activity (in willSet)
        // and release it.
        activity = nil
    }

    func updateIndexWith(notfication: [NSObject: AnyObject]) {
        let activity = createUserActivity()
        activity.title = notfication["title"] as? String
        activity.webpageURL = notfication["url"] as? NSURL
        if #available(iOS 9, *) {
            activity.eligibleForSearch = true
        }
        self.activity = activity
        //let keywords = activity.title?.componentsSeparatedByString(" ") ?? []
        //            activity.keywords = Set(keywords)
        //            activity.userInfo = ["Search" : ["Icecream" , "Nuts", "Biscuits"]]
        activity.becomeCurrent()
    }

    func becomeCurrent() {
        activity?.becomeCurrent()
    }

    func createUserActivity() -> NSUserActivity {
        return NSUserActivity(activityType: browsingActivityType)
    }
}

extension SpotlightHelper: NSUserActivityDelegate {
    @objc func userActivityWasContinued(userActivity: NSUserActivity) {
        print("userActivityWasContinued \(userActivity.webpageURL)")
        if let url = userActivity.webpageURL {
            createNewTab(url: url)
        }
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
        // As yet unused.
    }
}
