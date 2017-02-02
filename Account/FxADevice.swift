/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

typealias PushParams = (callback: String, publicKey: String?, authKey: String?)

public struct FxADevice {
    let name: String
    let id: String?
    let type: String?
    let pushAuthKey: String?
    let pushPublicKey: String?
    let pushCallback: String?
    let isCurrentDevice: Bool

    private init(name: String, id: String?, type: String?, isCurrentDevice: Bool = false, push: PushParams?) {
        self.name = name
        self.id = id
        self.type = type
        self.isCurrentDevice = isCurrentDevice
        self.pushAuthKey = push?.authKey
        self.pushPublicKey = push?.publicKey
        self.pushCallback = push?.callback
    }

    static func forRegister(name: String, type: String, push: PushParams?) -> FxADevice {
        return FxADevice(name: name, id: nil, type: type, push: push)
    }

    static func forUpdate(name: String, id: String, push: PushParams?) -> FxADevice {
        return FxADevice(name: name, id: id, type: nil, push: push)
    }

    func toJSON() -> JSON {
        var parameters = [String: String]()
        parameters["name"] = name
        parameters["id"] = id
        parameters["type"] = type
        parameters["pushCallback"] = pushCallback
        parameters["pushPublicKey"] = pushPublicKey
        parameters["pushAuthKey"] = pushAuthKey

        return JSON(parameters)
    }

    static func fromJSON(json: JSON) -> FxADevice? {
        guard !json.isError,
            let id = json["id"].asString,
            let name = json["name"].asString,
            let type = json["type"].asString else {
                return nil
        }

        let isCurrentDevice = json["isCurrentDevice"].asBool ?? false

        let push: PushParams?
        if let pushCallback = json["pushCallback"].asString {
            push = (callback: pushCallback, publicKey: json["pushPublicKey"].asString, authKey: json["pushAuthKey"].asString)
        } else {
            push = nil
        }

        return FxADevice(name: name, id: id, type: type, isCurrentDevice: isCurrentDevice, push: push)
    }
}
