/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

open class BasePayloadJSON {
    var _json: JSON
    required public init(_ jsonString: String) {
        self._json = JSON.init(parseJSON: jsonString)
    }

    public init(_ json: JSON) {
        self._json = json
    }

    // Override me.
    fileprivate func isValid() -> Bool {
        return self._json.error == nil
    }
}

/**
 * http://docs.services.mozilla.com/sync/objectformats.html
 * "In addition to these custom collection object structures, the
 *  Encrypted DataObject adds fields like id and deleted."
 */
open class CleartextPayloadJSON: BasePayloadJSON {
    // Override me.
    override open func isValid() -> Bool {
        return super.isValid() && _json["id"].isStringOrNull
    }

    open var id: String {
        return _json["id"].string!
    }

    open var deleted: Bool {
        let d = _json["deleted"]
        if let bool = d.bool {
            return bool
        } else {
            return false
        }
    }

    // Override me.
    // Doesn't check id. Should it?
    open func equalPayloads (_ obj: CleartextPayloadJSON) -> Bool {
        return self.deleted == obj.deleted
    }
}

//extension JSON {
//    public var isStringOrNull: Bool {
//        return self.isStringOrNull || self.isNull
//    }
//}
