/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TabbedHomePanelController: ThemedNavigationController {
    var currentPanelType: NewTabPage?
    var currentPanel: (HomePanel & UIViewController)?

    convenience init?(choice: NewTabPage, profile: Profile) {
        var homePanelVC: (UIViewController & HomePanel)?
        switch choice {
        case .topSites:
            homePanelVC = ActivityStreamPanel(profile: profile)
        case .bookmarks:
            homePanelVC = BookmarksPanel(profile: profile)
        case .history:
            homePanelVC = HistoryPanel(profile: profile)
        case .readingList:
            homePanelVC = ReadingListPanel(profile: profile)
        case .downloads:
            homePanelVC = DownloadsPanel(profile: profile)
        default:
            break
        }
        guard let panel = homePanelVC else { return nil }
        self.init(rootViewController: panel)
        self.currentPanelType = choice
        self.currentPanel = homePanelVC
        self.setNavigationBarHidden(true, animated: false)
        self.interactivePopGestureRecognizer?.delegate = nil
        self.view.alpha = 0
    }
}
