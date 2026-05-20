// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Carbon
import Foundation

public final class HotkeyController {
    public typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var handler: Handler?

    public init() {}

    deinit {
        unregister()
    }

    /// Registers a global hotkey. Carbon `keyCode` is a `kVK_*` virtual key code;
    /// `modifiers` is a Carbon modifier mask (`cmdKey | optionKey | …`). Calling this
    /// again replaces any previously registered hotkey.
    @discardableResult
    public func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping Handler) -> OSStatus {
        unregister()
        self.handler = handler

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData else {
                return noErr
            }

            let controller = Unmanaged<HotkeyController>.fromOpaque(userData).takeUnretainedValue()
            controller.handler?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        guard handlerStatus == noErr else {
            unregister()
            return handlerStatus
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E4F4F4B), id: 1) // "NOOK"
        let hotKeyStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard hotKeyStatus == noErr else {
            unregister()
            return hotKeyStatus
        }

        return noErr
    }

    public func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }

        hotKeyRef = nil
        eventHandler = nil
        handler = nil
    }
}
