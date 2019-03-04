/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Shared
import UIKit

struct SettingsUX {
    static let TableViewHeaderFooterHeight = CGFloat(44)

}

extension UILabel {
    // iOS bug: NSAttributed string color is ignored without setting font/color to nil
    func assign(attributed: NSAttributedString?) {
        guard let attributed = attributed else { return }
        let attribs = attributed.attributes(at: 0, effectiveRange: nil)
        if attribs[NSAttributedStringKey.foregroundColor] == nil {
            // If the text color attribute isn't set, use the table view row text color.
            textColor = UIColor.theme.tableView.rowText
        } else {
            textColor = nil
        }
        attributedText = attributed
    }
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting: NSObject {
    fileprivate var _title: NSAttributedString?
    fileprivate var _footerTitle: NSAttributedString?
    fileprivate var _cellHeight: CGFloat?
    fileprivate var _image: UIImage?

    weak var delegate: SettingsDelegate?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: URL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }
    var footerTitle: NSAttributedString? { return _footerTitle }
    var cellHeight: CGFloat? { return _cellHeight}
    fileprivate(set) var accessibilityIdentifier: String?

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCellStyle { return .subtitle }

    var accessoryType: UITableViewCellAccessoryType { return .none }

    var textAlignment: NSTextAlignment { return .natural }

    var image: UIImage? { return _image }

    fileprivate(set) var enabled: Bool = true

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(_ cell: UITableViewCell) {
        cell.detailTextLabel?.assign(attributed: status)
        cell.detailTextLabel?.attributedText = status
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.assign(attributed: title)
        cell.textLabel?.textAlignment = textAlignment
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
        cell.selectionStyle = enabled ? .default : .none
        cell.accessibilityIdentifier = accessibilityIdentifier
        cell.imageView?.image = _image
        if let title = title?.string {
            if let detailText = cell.detailTextLabel?.text {
                cell.accessibilityLabel = "\(title), \(detailText)"
            } else if let status = status?.string {
                cell.accessibilityLabel = "\(title), \(status)"
            } else {
                cell.accessibilityLabel = title
            }
        }
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.indentationWidth = 0
        cell.layoutMargins = .zero
        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = .zero
        if let cell = cell as? ThemedTableViewCell {
            cell.applyTheme()
        }
    }

    // Called when the pref is tapped.
    func onClick(_ navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(_ navigationController: UINavigationController?) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, delegate: SettingsDelegate? = nil, enabled: Bool? = nil) {
        self._title = title
        self._footerTitle = footerTitle
        self._cellHeight = cellHeight
        self.delegate = delegate
        self.enabled = enabled ?? true
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection: Setting {
    fileprivate let children: [Setting]

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, children: [Setting]) {
        self.children = children
        super.init(title: title, footerTitle: footerTitle, cellHeight: cellHeight)
    }

    var count: Int {
        var count = 0
        for setting in children where !setting.hidden {
            count += 1
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children where !setting.hidden {
            if i == val {
                return setting
            }
            i += 1
        }
        return nil
    }
}

private class PaddedSwitch: UIView {
    fileprivate static let Padding: CGFloat = 8

    init(switchView: UISwitch) {
        super.init(frame: .zero)

        addSubview(switchView)

        frame.size = CGSize(width: switchView.frame.width + PaddedSwitch.Padding, height: switchView.frame.height)
        switchView.frame.origin = CGPoint(x: PaddedSwitch.Padding, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting {
    let prefKey: String? // Sometimes a subclass will manage its own pref setting. In that case the prefkey will be nil

    fileprivate let prefs: Prefs
    fileprivate let defaultValue: Bool
    fileprivate let settingDidChange: ((Bool) -> Void)?
    fileprivate let statusText: NSAttributedString?

    init(prefs: Prefs, prefKey: String? = nil, defaultValue: Bool, attributedTitleText: NSAttributedString, attributedStatusText: NSAttributedString? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = attributedStatusText
        super.init(title: attributedTitleText)
    }

    convenience init(prefs: Prefs, prefKey: String? = nil, defaultValue: Bool, titleText: String, statusText: String? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        var statusTextAttributedString: NSAttributedString?
        if let statusTextString = statusText {
            statusTextAttributedString = NSAttributedString(string: statusTextString, attributes: [NSAttributedStringKey.foregroundColor: UIColor.theme.tableView.headerTextLight])
        }
        self.init(prefs: prefs, prefKey: prefKey, defaultValue: defaultValue, attributedTitleText: NSAttributedString(string: titleText, attributes: [NSAttributedStringKey.foregroundColor: UIColor.theme.tableView.rowText]), attributedStatusText: statusTextAttributedString, settingDidChange: settingDidChange)
    }

    override var status: NSAttributedString? {
        return statusText
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)

        let control = UISwitchThemed()
        control.onTintColor = UIConstants.SystemBlueColor
        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        control.accessibilityIdentifier = prefKey

        displayBool(control)
        if let title = title {
            if let status = status {
                control.accessibilityLabel = "\(title.string), \(status.string)"
            } else {
                control.accessibilityLabel = title.string
            }
            cell.accessibilityLabel = nil
        }
        cell.accessoryView = PaddedSwitch(switchView: control)
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ control: UISwitch) {
        writeBool(control)
        settingDidChange?(control.isOn)
        UnifiedTelemetry.recordEvent(category: .action, method: .change, object: .setting, value: self.prefKey, extras: ["to": control.isOn])
    }

    // These methods allow a subclass to control how the pref is saved
    func displayBool(_ control: UISwitch) {
        guard let key = prefKey else {
            return
        }
        control.isOn = prefs.boolForKey(key) ?? defaultValue
    }

    func writeBool(_ control: UISwitch) {
        guard let key = prefKey else {
            return
        }
        prefs.setBool(control.isOn, forKey: key)
    }
}

class PrefPersister: SettingValuePersister {
    fileprivate let prefs: Prefs
    let prefKey: String

    init(prefs: Prefs, prefKey: String) {
        self.prefs = prefs
        self.prefKey = prefKey
    }

    func readPersistedValue() -> String? {
        return prefs.stringForKey(prefKey)
    }

    func writePersistedValue(value: String?) {
        if let value = value {
            prefs.setString(value, forKey: prefKey)
        } else {
            prefs.removeObjectForKey(prefKey)
        }
    }
}

class StringPrefSetting: StringSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingIsValid isValueValid: ((String?) -> Bool)? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(defaultValue: defaultValue, placeholder: placeholder, accessibilityIdentifier: accessibilityIdentifier, persister: PrefPersister(prefs: prefs, prefKey: prefKey), settingIsValid: isValueValid, settingDidChange: settingDidChange)
    }
}

class WebPageSetting: StringPrefSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURLOrEmpty,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
    }

    override func prepareValidValue(userInput value: String?) -> String? {
        guard let value = value else {
            return nil
        }
        return URIFixup.getURL(value)?.absoluteString
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.accessoryType = .checkmark
        textField.textAlignment = .left
    }

    static func isURLOrEmpty(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else {
            return true
        }
        return URL(string: string)?.isWebPage() ?? false
    }
}


protocol SettingValuePersister {
    func readPersistedValue() -> String?
    func writePersistedValue(value: String?)
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional settingIsValid and settingDidChange callback
/// If settingIsValid returns false, the Setting will not change and the text remains red.
class StringSetting: Setting, UITextFieldDelegate {
    var Padding: CGFloat = 15

    fileprivate let defaultValue: String?
    fileprivate let placeholder: String
    fileprivate let settingDidChange: ((String?) -> Void)?
    fileprivate let settingIsValid: ((String?) -> Bool)?
    fileprivate let persister: SettingValuePersister

    let textField = UITextField()

    init(defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, persister: SettingValuePersister, settingIsValid isValueValid: ((String?) -> Bool)? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.persister = persister

        super.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }
        if let placeholderColor = UIColor.theme.general.settingsTextPlaceholder {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        } else {
            textField.placeholder = placeholder
        }

        cell.tintColor = self.persister.readPersistedValue() != nil ? UIColor.theme.tableView.rowActionAccessory : UIColor.clear
        textField.textAlignment = .center
        textField.delegate = self
        textField.tintColor = UIColor.theme.tableView.rowActionAccessory
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraitNone
        cell.contentView.addSubview(textField)

        textField.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        }
        textField.text = self.persister.readPersistedValue() ?? defaultValue
        textFieldDidChange(textField)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    fileprivate func isValid(_ value: String?) -> Bool {
        guard let test = settingIsValid else {
            return true
        }
        return test(prepareValidValue(userInput: value))
    }

    /// This gives subclasses an opportunity to treat the user input string
    /// before it is saved or tested.
    /// Default implementation does nothing.
    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        let color = isValid(textField.text) ? UIColor.theme.tableView.rowText : UIColor.theme.general.destructiveRed
        textField.textColor = color
    }

    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return isValid(textField.text)
    }

    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text
        if !isValid(text) {
            return
        }
        self.persister.writePersistedValue(value: prepareValidValue(userInput: text))
        // Call settingDidChange with text or nil.
        settingDidChange?(text)
    }
}

class CheckmarkSetting: Setting {
    let onChanged: () -> Void
    let isEnabled: () -> Bool
    private let subtitle: NSAttributedString?

    override var status: NSAttributedString? {
        return subtitle
    }

    init(title: NSAttributedString, subtitle: NSAttributedString?, accessibilityIdentifier: String? = nil, isEnabled: @escaping () -> Bool, onChanged: @escaping () -> Void) {
        self.subtitle = subtitle
        self.onChanged = onChanged
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.accessoryType = .checkmark
        cell.tintColor = isEnabled() ? UIColor.theme.tableView.rowActionAccessory : UIColor.clear
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if !isEnabled() {
            onChanged()
        }
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional isEnabled and mandatory onClick callback
/// isEnabled is called on each tableview.reloadData. If it returns
/// false then the 'button' appears disabled.
class ButtonSetting: Setting {
    var Padding: CGFloat = 8

    let onButtonClick: (UINavigationController?) -> Void
    let destructive: Bool
    let isEnabled: (() -> Bool)?

    init(title: NSAttributedString?, destructive: Bool = false, accessibilityIdentifier: String, isEnabled: (() -> Bool)? = nil, onClick: @escaping (UINavigationController?) -> Void) {
        self.onButtonClick = onClick
        self.destructive = destructive
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)

        if isEnabled?() ?? true {
            cell.textLabel?.textColor = destructive ? UIColor.theme.general.destructiveRed : UIColor.theme.general.highlightBlue
        } else {
            cell.textLabel?.textColor = UIColor.theme.tableView.disabledRowText
        }
        cell.textLabel?.snp.makeConstraints({ make in
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        })
        cell.textLabel?.textAlignment = .center
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if isEnabled?() ?? true {
            onButtonClick(navigationController)
        }
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
class AccountSetting: Setting, FxAContentViewControllerDelegate {
    unowned var settings: SettingsTableViewController

    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if settings.profile.getAccount() != nil {
            cell.selectionStyle = .none
        }
    }

    override var accessoryType: UITableViewCellAccessoryType { return .none }

    func contentViewControllerDidSignIn(_ viewController: FxAContentViewController, withFlags flags: FxALoginFlags) {
        // This method will get called twice: once when the user signs in, and once
        // when the account is verified by email – on this device or another.
        // If the user hasn't dismissed the fxa content view controller,
        // then we should only do that (thus finishing the sign in/verification process)
        // once the account is verified.
        // By the time we get to here, we should be syncing or just about to sync in the
        // background, most likely from FxALoginHelper.
        if flags.verified {
            _ = settings.navigationController?.popToRootViewController(animated: true)
            // Reload the data to reflect the new Account immediately.
            settings.tableView.reloadData()
            // And start advancing the Account state in the background as well.
            settings.refresh()
        }
    }

    func contentViewControllerDidCancel(_ viewController: FxAContentViewController) {
        NSLog("didCancel")
        _ = settings.navigationController?.popToRootViewController(animated: true)
    }
}

class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return !profile.hasAccount() }
}

class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.hasAccount() }
}

@objc
protocol SettingsDelegate: AnyObject {
    func settingsOpenURLInNewTab(_ url: URL)
}

// The base settings view controller.
class SettingsTableViewController: ThemedTableViewController {

    typealias SettingsGenerator = (SettingsTableViewController, SettingsDelegate?) -> [SettingSection]

    fileprivate let Identifier = "CellIdentifier"
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    var settings = [SettingSection]()

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile!
    var tabManager: TabManager!

    var hasSectionSeparatorLine = true

    /// Used to calculate cell heights.
    fileprivate lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = UISwitchThemed()
        return cell
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(width: view.frame.width, height: 30))
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settings = generateSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(syncDidChangeState), name: .ProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncDidChangeState), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(firefoxAccountDidChange), name: .FirefoxAccountChanged, object: nil)

        applyTheme()
    }

    override func applyTheme() {
        settings = generateSettings()
        super.applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        [Notification.Name.ProfileDidStartSyncing, Notification.Name.ProfileDidFinishSyncing, Notification.Name.FirefoxAccountChanged].forEach { name in
            NotificationCenter.default.removeObserver(self, name: name, object: nil)
        }
    }

    // Override to provide settings in subclasses
    func generateSettings() -> [SettingSection] {
        return []
    }

    @objc fileprivate func syncDidChangeState() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func refresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        if let account = self.profile.getAccount() {
            account.advance().upon { state in
                DispatchQueue.main.async { () -> Void in
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.reloadData()
        }
    }

    @objc func firefoxAccountDidChange() {
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            let cell = ThemedTableViewCell(style: setting.style, reuseIdentifier: nil)
            setting.onConfigureCell(cell)
            cell.backgroundColor = UIColor.theme.tableView.rowBackground
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as? ThemedTableSectionHeaderFooterView else {
            return nil
        }

        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle.uppercased()
        }
        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 || !hasSectionSeparatorLine {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        headerView.applyTheme()
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionSetting = settings[section]
        guard let sectionFooter = sectionSetting.footerTitle?.string,
            let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as? ThemedTableSectionHeaderFooterView else {
                return nil
        }
        footerView.titleLabel.text = sectionFooter
        footerView.titleAlignment = .top
        footerView.showBottomBorder = false
        footerView.applyTheme()
        return footerView
    }

    // To hide a footer dynamically requires returning nil from viewForFooterInSection
    // and setting the height to zero.
    // However, we also want the height dynamically calculated, there is a magic constant
    // for that: `UITableViewAutomaticDimension`.
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionSetting = settings[section]
        if let _ = sectionSetting.footerTitle?.string {
            return UITableViewAutomaticDimension
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = settings[indexPath.section]
        // Workaround for calculating the height of default UITableViewCell cells with a subtitle under
        // the title text label.
        if let setting = section[indexPath.row], setting is BoolSetting && setting.status != nil {
            return calculateStatusCellHeightForSetting(setting)
        }
        if let setting = section[indexPath.row], let height = setting.cellHeight {
            return height
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onClick(navigationController)
        }
    }

    fileprivate func calculateStatusCellHeightForSetting(_ setting: Setting) -> CGFloat {
        dummyToggleCell.layoutSubviews()

        let topBottomMargin: CGFloat = 10
        let width = dummyToggleCell.contentView.frame.width - 2 * dummyToggleCell.separatorInset.left

        return
            heightForLabel(dummyToggleCell.textLabel!, width: width, text: setting.title?.string) +
            heightForLabel(dummyToggleCell.detailTextLabel!, width: width, text: setting.status?.string) +
            2 * topBottomMargin
    }

    fileprivate func heightForLabel(_ label: UILabel, width: CGFloat, text: String?) -> CGFloat {
        guard let text = text else { return 0 }

        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs = [NSAttributedStringKey.font: label.font as Any]
        let boundingRect = NSString(string: text).boundingRect(with: size,
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }
}
