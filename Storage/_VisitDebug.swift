/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
@objc public enum _VisitType: Int {
    case unknown = 0

    /**
     * This transition type means the user followed a link and got a new toplevel
     * window.
     */
    case link = 1

    /**
     * This transition type means that the user typed the page's URL in the
     * URL bar or selected it from URL bar autocomplete results, clicked on
     * it from a history query (from the History sidebar, History menu,
     * or history query in the personal toolbar or Places organizer).
     */
    case typed = 2

    case bookmark = 3
    case embed = 4
    case permanentRedirect = 5
    case temporaryRedirect = 6
    case download = 7
    case framedLink = 8
}

open class _Visit: Hashable {
    open let type: _VisitType

    open var hashValue: Int {
        return 123
    }

    public init(type: _VisitType = .unknown) {
        self.type = type
    }

    open class func fromJSON() -> _Visit? {
        return nil
    }

    open func toJSON() {
        let o: [String: Any] = ["type": self.type.rawValue]
    }

    public static func ==(lhs: _Visit, rhs: _Visit) -> Bool {
        return true
    }
}

open class _SiteVisit: _Visit {
    var id: Int? = nil

    open override var hashValue: Int {
        return 123
    }

    public override init(type: _VisitType = .unknown) {
        super.init(type: type)
    }
}

public func ==(lhs: _SiteVisit, rhs: _SiteVisit) -> Bool {
    if let lhsID = lhs.id, let rhsID = rhs.id {
        if lhsID != rhsID {
            return false
        }
    } else {
        if lhs.id != nil || rhs.id != nil {
            return false
        }
    }

    // TODO: compare Site.
    return true
}
