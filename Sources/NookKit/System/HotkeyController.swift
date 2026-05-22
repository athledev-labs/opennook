// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Glendon Chin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// A copy is included at /LICENSE in the repository root.

import Carbon
import Foundation

/// Registers any number of global hotkeys and routes each to its own handler.
///
/// A multi-module host needs more than one shortcut at a time — the show/hide toggle,
/// a module-cycle key, a direct-jump key per module. Each registration is keyed by a
/// caller-chosen string id so it can be replaced or removed independently; a single
/// shared Carbon event handler dispatches presses to the right handler by hotkey id.
public final class HotkeyController {
    public typealias Handler = () -> Void

    private struct Registration {
        let carbonID: UInt32
        let ref: EventHotKeyRef?
        let handler: Handler
    }

    /// Active registrations, keyed by the caller's string id.
    private var registrations: [String: Registration] = [:]

    /// Handlers keyed by Carbon hotkey id — the dispatch table the event callback uses.
    private var handlersByCarbonID: [UInt32: Handler] = [:]

    private var eventHandler: EventHandlerRef?
    private var nextCarbonID: UInt32 = 1

    public init() {}

    deinit {
        unregisterAll()
    }

    /// Registers a global hotkey under `id`, replacing any existing registration for the
    /// same `id`. Carbon `keyCode` is a `kVK_*` virtual key code; `modifiers` is a
    /// Carbon modifier mask (`cmdKey | optionKey | …`). Returns `noErr` on success.
    @discardableResult
    public func register(
        _ id: String,
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping Handler
    ) -> OSStatus {
        unregister(id)

        let handlerStatus = installEventHandlerIfNeeded()
        guard handlerStatus == noErr else { return handlerStatus }

        let carbonID = nextCarbonID
        nextCarbonID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E4F4F4B), id: carbonID) // "NOOK"
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr else { return status }

        registrations[id] = Registration(carbonID: carbonID, ref: ref, handler: handler)
        handlersByCarbonID[carbonID] = handler
        return noErr
    }

    /// Removes the registration for `id`, if any.
    public func unregister(_ id: String) {
        guard let registration = registrations.removeValue(forKey: id) else { return }
        if let ref = registration.ref {
            UnregisterEventHotKey(ref)
        }
        handlersByCarbonID.removeValue(forKey: registration.carbonID)
    }

    /// Removes every registration and tears down the shared event handler.
    public func unregisterAll() {
        for id in Array(registrations.keys) {
            unregister(id)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    /// Installs the one shared keyboard event handler, lazily. The handler reads the
    /// pressed hotkey's id from the event and dispatches to the matching `Handler`.
    private func installEventHandlerIfNeeded() -> OSStatus {
        guard eventHandler == nil else { return noErr }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        return InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData, let event else { return noErr }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return noErr }

            let controller = Unmanaged<HotkeyController>.fromOpaque(userData).takeUnretainedValue()
            controller.handlersByCarbonID[hotKeyID.id]?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }
}
