// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Kai Azim — DynamicNotchKit (original)
// Copyright (c) 2026 Glendon Chin — OpenNook modifications
//
// Licensed under the MIT License.
// Original kit license: /ThirdPartyLicenses/DynamicNotchKit.txt
// Modifications license: /LICENSE-MIT-NOOKSURFACE

import AppKit
import Combine
import SwiftUI

/// A notch-pinned floating panel with `expanded` / `compact` / `hidden` states.
///
/// Three SwiftUI view types compose the surface:
/// - `Expanded` — the full panel that drops below the menu-bar notch.
/// - `CompactLeading` — the slot to the left of the notch when collapsed.
/// - `CompactTrailing` — the slot to the right of the notch when collapsed.
///
/// Driving the lifecycle:
/// ```swift
/// let nook = Nook(style: .standard) {
///     ExpandedView()
/// } compactLeading: {
///     LeadingGlyph()
/// } compactTrailing: {
///     TrailingGlyph()
/// }
///
/// await nook.expand()
/// try await Task.sleep(for: .seconds(2))
/// await nook.compact()
/// ```
///
/// Hover side-effects are described by ``NookHoverBehavior``; opening/closing/conversion timing
/// can be customized through ``transitionConfiguration``.
public final class Nook<Expanded, CompactLeading, CompactTrailing>: ObservableObject, NookControllable
where Expanded: View, CompactLeading: View, CompactTrailing: View {
    /// Exposed for callers that need to tweak window-level details (e.g. accessibility, level changes).
    public var windowController: NSWindowController?

    public let style: NookStyle
    public let hoverBehavior: NookHoverBehavior

    /// Lazily allocated namespace used for matched-geometry transitions between compact/expanded.
    @Published public internal(set) var namespace: Namespace.ID?

    public var transitionConfiguration = NookTransitionConfiguration()

    /// Resolves the screen the chrome should occupy when a caller doesn't pass one
    /// explicitly. Host apps set this to project a persisted display preference
    /// (built-in / main / a specific display) onto the surface — the closure is
    /// consulted on every `expand`/`compact` with a `nil` screen, on hover-driven
    /// transitions, and whenever the display set changes. Returning `nil` falls
    /// through to the window's current screen, then the system's main screen.
    public var screenProvider: (() -> NSScreen?)?

    /// How the chrome presents itself — notch-fused, free-floating, or `.auto` (notch on
    /// a notched display, floating elsewhere). See ``NookPresentation``.
    ///
    /// The effective layout is resolved per-window against the target screen; changing
    /// this rebuilds a currently-visible window in place so the new layout takes effect
    /// immediately. A hidden nook simply picks it up on its next `expand`/`compact`.
    public var presentation: NookPresentation = .auto {
        didSet {
            guard presentation != oldValue, state != .hidden, let screen = resolvedScreen else { return }
            initializeWindow(screen: screen, orderFront: false)
            showWindow()
        }
    }

    let expandedContent: Expanded
    let compactLeadingContent: CompactLeading
    let compactTrailingContent: CompactTrailing
    @Published var disableCompactLeading: Bool = false
    @Published var disableCompactTrailing: Bool = false

    /// Current lifecycle state. Host apps can observe this directly (it's `@Published`)
    /// or react through the ``onExpand`` / ``onCompact`` / ``onHide`` callbacks — the
    /// callbacks fire on every transition, including hover- and drag-driven ones that
    /// never pass through a host-called `expand`/`compact`.
    @Published public private(set) var state: NookState = .hidden
    @Published private(set) var notchSize: CGSize = .zero
    @Published private(set) var menubarHeight: CGFloat = 0

    /// Layout resolved for the current window's screen — `.notch` or `.floating`.
    /// Recomputed every time the panel window is built (see `initializeWindow`); drives
    /// `NookView`'s shape and positioning.
    @Published private(set) var layoutForm: NookChromeForm = .notch
    @Published public private(set) var isHovering: Bool = false
    @Published public var staysExpandedOnHoverExit: Bool = false

    /// `true` while a system file-drag session is over the panel. Drives the drop-mode UI
    /// in the expanded surface and the auto-expand from compact. The panel surfaces
    /// `NSDraggingDestination` callbacks; this published bool is the SwiftUI-friendly view.
    @Published public private(set) var isDragInFlight: Bool = false

    /// Drop callback invoked when AppKit hands us a file URL drop on the panel. Returning
    /// `true` accepts the drop; `false` rejects it. Set by the app layer to route the URLs
    /// through whatever registration / import flow it owns.
    public var onFileDrop: (([URL]) -> Bool)?

    /// Fired when the chrome transitions **into** the expanded surface — from any source:
    /// a host-called `expand`, a hover-grow, or a file drag auto-expanding the panel.
    public var onExpand: (() -> Void)?

    /// Fired when the chrome transitions **into** the compact pill.
    public var onCompact: (() -> Void)?

    /// Fired when the chrome transitions **into** the hidden state. Note the cold-launch
    /// sequence collapses to compact, so `onHide` only fires on a genuine hide afterwards.
    public var onHide: (() -> Void)?

    /// Snapshot of `state` at the moment the drag entered. Lets `draggingExited` restore
    /// the prior compact/expanded shape if the user releases outside the panel — we don't
    /// want to silently leave the nook expanded after an aborted drag.
    private var stateBeforeDrag: NookState?

    /// Backdrop layers behind compact + expanded chrome (vibrancy or flat fill).
    @Published public var backdropConfiguration = NookBackdropConfiguration.solidBlack

    /// Pins the chrome window's `NSAppearance`. `nil` follows the system appearance.
    ///
    /// This is the only thing that makes a forced light/dark theme render correctly: the
    /// backdrop's `NSVisualEffectView` resolves its material against the *window's*
    /// appearance, so without pinning it here a "Light" theme on a dark-mode Mac would
    /// still paint a dark frosted panel.
    public var chromeAppearance: NSAppearance? {
        didSet { windowController?.window?.appearance = chromeAppearance }
    }

    /// Most recent peripheral-feedback request. The view layer (`NookFeedbackOverlay`) watches
    /// this; bumping it with a new `id` re-arms the animation. Internal because callers should
    /// go through ``playFeedback(_:tint:duration:)`` rather than mutate directly.
    @Published var feedbackEvent: NookFeedbackEvent?

    /// Feedback queued while the chrome wasn't visible (`.hidden` during the boot race, or
    /// reset path). Replayed when state next transitions to `.compact`. Cleared on a real
    /// `.expanded` transition because the user has by then acknowledged the surface directly.
    private var pendingFeedback: NookFeedbackEvent?

    private var closePanelTask: Task<(), Never>?
    private var cancellables = Set<AnyCancellable>()

    public init(
        hoverBehavior: NookHoverBehavior = .all,
        style: NookStyle = .standard,
        @ViewBuilder expanded: @escaping () -> Expanded,
        @ViewBuilder compactLeading: @escaping () -> CompactLeading = { EmptyView() },
        @ViewBuilder compactTrailing: @escaping () -> CompactTrailing = { EmptyView() }
    ) {
        self.hoverBehavior = hoverBehavior
        self.style = style
        self.expandedContent = expanded()
        self.compactLeadingContent = compactLeading()
        self.compactTrailingContent = compactTrailing()

        observeScreenParameters()
        observeStateForPendingFeedback()
        observeStateForLifecycleHooks()
    }

    /// Convenience for the no-compact-content case. Compact mode collapses to hide.
    public convenience init(
        hoverBehavior: NookHoverBehavior = [.keepVisible],
        style: NookStyle = .standard,
        @ViewBuilder expanded: @escaping () -> Expanded
    ) where CompactLeading == EmptyView, CompactTrailing == EmptyView {
        self.init(
            hoverBehavior: hoverBehavior,
            style: style,
            expanded: expanded,
            compactLeading: { EmptyView() },
            compactTrailing: { EmptyView() }
        )
        self.disableCompactLeading = true
        self.disableCompactTrailing = true
    }

    var effectiveOpeningAnimation: Animation { transitionConfiguration.openingAnimation ?? style.openingAnimation }
    var effectiveClosingAnimation: Animation { transitionConfiguration.closingAnimation ?? style.closingAnimation }
    var effectiveConversionAnimation: Animation { transitionConfiguration.conversionAnimation ?? style.conversionAnimation }

    /// When the chrome becomes visible (state transitions out of `.hidden`), replay any
    /// feedback that was requested during the boot race. Single sink keeps lifetime tied
    /// to `Nook`'s cancellables; no unstructured tasks.
    private func observeStateForPendingFeedback() {
        $state
            .removeDuplicates()
            .sink { [weak self] newState in
                guard let self, newState != .hidden, let pending = self.pendingFeedback else { return }
                self.pendingFeedback = nil
                self.feedbackEvent = pending
            }
            .store(in: &cancellables)
    }

    /// Fire the host's lifecycle callbacks on every distinct state transition. A single
    /// `$state` sink catches transitions from *all* sources uniformly — host-called
    /// `expand`/`compact`, hover-driven grow/shrink, drag auto-expand — which is why the
    /// hooks live here rather than on a higher-level coordinator. `dropFirst()` skips the
    /// initial `.hidden` published at construction; `removeDuplicates()` collapses no-op
    /// re-publishes so a hook never double-fires for one logical transition.
    private func observeStateForLifecycleHooks() {
        $state
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newState in
                guard let self else { return }
                switch newState {
                case .expanded: self.onExpand?()
                case .compact: self.onCompact?()
                case .hidden: self.onHide?()
                }
            }
            .store(in: &cancellables)
    }

    /// The screen the chrome should occupy when no explicit screen is supplied.
    /// Consults the host-supplied ``screenProvider`` first, then the window's current
    /// screen, then the system. `nil` only when no display is attached at all.
    var resolvedScreen: NSScreen? {
        screenProvider?()
            ?? windowController?.window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    /// Re-place the panel on screen-parameter changes (display add/remove, resolution
    /// or arrangement changes). Combine sink keeps the observer's lifetime tied to
    /// `Nook` and frees us from an unstructured `Task` whose cancellation we never
    /// wired up.
    ///
    /// While hidden there's no window worth keeping — drop any stale one so the next
    /// `expand`/`compact` rebuilds on the then-current preferred screen. While visible,
    /// recompute the target via ``resolvedScreen`` and re-show there, so a host's
    /// display preference (and its disconnect fallback) follows the chrome live.
    private func observeScreenParameters() {
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.state != .hidden else {
                    self.deinitializeWindow()
                    return
                }
                guard let screen = self.resolvedScreen else { return }
                self.initializeWindow(screen: screen, orderFront: false)
                self.showWindow()
            }
            .store(in: &cancellables)
    }

    /// Apply hover side-effects (haptic, expand-on-hover, collapse-on-exit).
    func updateHoverState(_ hovering: Bool) {
        guard state != .hidden, hovering != isHovering else { return }

        isHovering = hovering

        if hoverBehavior.contains(.hapticFeedback) {
            let performer = NSHapticFeedbackManager.defaultPerformer
            performer.perform(.alignment, performanceTime: .default)
        }

        guard hovering || !staysExpandedOnHoverExit else {
            return
        }

        guard let screen = windowController?.window?.screen ?? resolvedScreen else { return }
        Task {
            if hovering {
                await _expand(on: screen, skipHide: true)
            } else {
                await _compact(on: screen, skipHide: true)
            }
        }
    }
}

// MARK: - Public lifecycle

public extension Nook {
    /// Expand the chrome. Pass `nil` (the default) to let ``resolvedScreen`` pick the
    /// target — typically the host's persisted display preference via ``screenProvider``.
    func expand(on screen: NSScreen? = nil) async {
        guard let target = screen ?? resolvedScreen else { return }
        await _expand(on: target, skipHide: transitionConfiguration.skipIntermediateHides)
    }

    /// Collapse the chrome to its compact pill. Pass `nil` (the default) to let
    /// ``resolvedScreen`` pick the target.
    func compact(on screen: NSScreen? = nil) async {
        guard let target = screen ?? resolvedScreen else { return }
        await _compact(on: target, skipHide: transitionConfiguration.skipIntermediateHides)
    }

    func hide() async {
        await withCheckedContinuation { continuation in
            _hide {
                continuation.resume()
            }
        }
    }
}

// MARK: - Peripheral feedback

public extension Nook {
    /// Play a one-shot peripheral cue along the chrome's perimeter. Default is the shimmer sweep.
    ///
    /// Use this for low-priority "something happened" signals the user can catch in
    /// peripheral vision — a sync finished, a background task completed. Caller-owned
    /// timing — no internal queueing or debouncing; rapid successive calls re-anchor
    /// `startedAt` and the in-flight animation restarts. A cue requested while the chrome
    /// is hidden is queued and replayed the next time the nook becomes visible.
    func playFeedback(
        _ effect: NookFeedback = .shimmer,
        tint: Color = Color(nsColor: .controlAccentColor),
        duration: TimeInterval = 0.85,
        repeats: Bool = false
    ) {
        guard effect != .none else { return }
        let event = NookFeedbackEvent(
            id: UUID(),
            startedAt: Date(),
            effect: effect,
            duration: duration,
            tint: tint,
            respectsReduceMotion: true,
            repeats: repeats
        )
        switch state {
        case .compact, .expanded:
            // Chrome is visible (either as compact pill or expanded surface) — fire
            // immediately. The shimmer overlay strokes the same `NookShape` perimeter in
            // both states, so the visual reads on either.
            feedbackEvent = event
            pendingFeedback = nil
        case .hidden:
            // Boot race or user-hidden: queue for the next visible transition. The overlay
            // can't paint without chrome, but we don't want to drop the request entirely
            // because the cue's whole job is "tell the user when they're not looking."
            pendingFeedback = event
        }
    }
}

extension Nook {
    func _expand(on screen: NSScreen, skipHide: Bool) async {
        // Already expanded *on the requested screen* — nothing to do. A different
        // screen still needs work: the window must move, so fall through to the
        // rebuild path, which `needsNewWindow` below already handles.
        if state == .expanded, windowController?.window?.screen == screen { return }

        // Opening the nook acknowledges any *repeating* peripheral cue — those are meant
        // to keep nagging until the user looks, so once they're looking we kill them. A
        // one-shot cue (e.g. the launch shimmer greeting) is allowed to play through the
        // expand transition so the user actually sees it; the perimeter stroke renders on
        // expanded chrome just as well as on compact.
        if feedbackEvent?.repeats == true {
            feedbackEvent = nil
        }
        if pendingFeedback?.repeats == true {
            pendingFeedback = nil
        }

        closePanelTask?.cancel()

        let needsNewWindow = state == .hidden || windowController?.window?.screen != screen

        if needsNewWindow {
            initializeWindow(screen: screen, orderFront: false)

            withAnimation(effectiveOpeningAnimation) {
                self.state = .expanded
            }

            showWindow()
        } else {
            Task { @MainActor in
                if !skipHide {
                    withAnimation(effectiveClosingAnimation) {
                        self.state = .hidden
                    }

                    guard self.state == .hidden else { return }

                    try? await Task.sleep(for: .seconds(0.25))
                }

                withAnimation(effectiveConversionAnimation) {
                    self.state = .expanded
                }
            }
        }

        try? await Task.sleep(for: .seconds(0.55))
    }

    func _compact(on screen: NSScreen, skipHide: Bool) async {
        // Already compact *on the requested screen* — nothing to do. A different
        // screen still needs the window moved, so fall through to the rebuild path.
        if state == .compact, windowController?.window?.screen == screen { return }

        if disableCompactLeading, disableCompactTrailing {
            await hide()
            return
        }

        closePanelTask?.cancel()

        let needsNewWindow = state == .hidden || windowController?.window?.screen != screen

        if needsNewWindow {
            initializeWindow(screen: screen, orderFront: false)

            withAnimation(effectiveOpeningAnimation) {
                self.state = .compact
            }

            showWindow()
        } else {
            Task { @MainActor in
                if !skipHide {
                    withAnimation(effectiveClosingAnimation) {
                        self.state = .hidden
                    }

                    try? await Task.sleep(for: .seconds(0.25))

                    guard self.state == .hidden else { return }
                }

                withAnimation(effectiveConversionAnimation) {
                    self.state = .compact
                }
            }
        }

        try? await Task.sleep(for: .seconds(0.55))
    }

    /// `keepVisible` defers the actual hide until the cursor leaves; otherwise we fade and tear down.
    func _hide(completion: (() -> Void)? = nil) {
        guard state != .hidden else {
            completion?()
            return
        }

        if hoverBehavior.contains(.keepVisible), isHovering {
            Task {
                try? await Task.sleep(for: .seconds(0.1))
                _hide(completion: completion)
            }
            return
        }

        withAnimation(effectiveClosingAnimation) {
            state = .hidden
            isHovering = false
        }

        closePanelTask?.cancel()
        closePanelTask = Task {
            try? await Task.sleep(for: .seconds(0.25))
            guard Task.isCancelled != true else { return }

            await fadeOutWindow()

            guard Task.isCancelled != true else { return }
            deinitializeWindow()
            completion?()
        }
    }

    /// Mask any closing-frame artifacts behind a brief layer-opacity fade before tearing the window down.
    /// Animating the hosting layer (not `NSWindow.alphaValue`) keeps shadow and vibrancy compositing
    /// independent of the fade, and runs entirely on the compositor.
    @MainActor
    private func fadeOutWindow() async {
        guard let layer = hostingLayer else { return }

        await withCheckedContinuation { continuation in
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                continuation.resume()
            }
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = layer.presentation()?.opacity ?? layer.opacity
            animation.toValue = 0
            animation.duration = Self.fadeDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            layer.add(animation, forKey: "nook.opacity")
            layer.opacity = 0
            CATransaction.commit()
        }
    }
}

// MARK: - Window management

extension Nook {
    /// Duration of the hosting-layer fade used during show/teardown.
    static var fadeDuration: CFTimeInterval { 0.15 }

    /// The layer of the hosting view inside the panel. Layer-level fades run here so the
    /// `NSWindow` itself (and its shadow/vibrancy compositing) stays at full alpha.
    var hostingLayer: CALayer? {
        guard let view = windowController?.window?.contentView else { return nil }
        view.wantsLayer = true
        return view.layer
    }
}

private extension Nook {
    func initializeWindow(screen: NSScreen, orderFront: Bool = true) {
        deinitializeWindow()

        notchSize = screen.notchFrameWithMenubarAsBackup.size
        menubarHeight = screen.menubarHeight
        layoutForm = presentation.isFloating(screenHasNotch: screen.hasNotch) ? .floating : .notch

        let hostingView = NSHostingView(rootView: NookContentView(nook: self))
        hostingView.wantsLayer = true
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Drag-receiving overlay sits on top of the SwiftUI hosting view so file-drag
        // events reach us before `NSHostingView` consumes them. It's hit-test-transparent
        // (returns nil) so pointer interactions pass through unchanged.
        let dragInterceptor = NookDragInterceptingView()
        dragInterceptor.wantsLayer = true
        dragInterceptor.dragDestination = self
        dragInterceptor.translatesAutoresizingMaskIntoConstraints = false

        // Plain container holds both as siblings; the interceptor is added last so it
        // sits above the hosting view in the subview list (and therefore in z-order).
        let container = NSView()
        container.wantsLayer = true
        container.addSubview(hostingView)
        container.addSubview(dragInterceptor)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dragInterceptor.topAnchor.constraint(equalTo: container.topAnchor),
            dragInterceptor.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            dragInterceptor.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dragInterceptor.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        let panel = NookPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.contentView = container
        panel.appearance = chromeAppearance

        let size = NSSize(
            width: screen.frame.width,
            height: screen.frame.height / 2
        )
        let origin = NSPoint(
            x: screen.frame.midX - (size.width / 2),
            y: screen.frame.maxY - size.height
        )

        panel.setFrame(NSRect(origin: origin, size: size), display: false)
        panel.layoutIfNeeded()

        if orderFront {
            panel.orderFrontRegardless()
        }

        windowController = .init(window: panel)
    }

    /// Show with the hosting layer starting at opacity 0, then animate to 1. The window itself
    /// is at full alpha — only the SwiftUI content fades in, masking any first-frame layout pop.
    func showWindow() {
        guard let window = windowController?.window else { return }

        let layer = hostingLayer
        layer?.opacity = 0

        window.orderFrontRegardless()

        guard let layer else { return }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = Self.fadeDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "nook.opacity")
        layer.opacity = 1
    }

    func deinitializeWindow() {
        guard let windowController else { return }
        windowController.close()
        self.windowController = nil
    }
}

// MARK: - NookDragDestination

extension Nook: NookDragDestination {
    /// Called when AppKit reports a file drag is over the panel. Snapshot the prior state
    /// (so we can restore on cancel), flip `isDragInFlight` for the SwiftUI surface, and
    /// auto-expand if we were collapsed so the drop zone is visible.
    func nookPanelDraggingEntered(_ urls: [URL]) -> NSDragOperation {
        if !isDragInFlight {
            stateBeforeDrag = state
        }
        isDragInFlight = true

        if state == .compact || state == .hidden {
            let screen = windowController?.window?.screen ?? resolvedScreen
            if let screen {
                Task { await _expand(on: screen, skipHide: true) }
            }
        }
        return .copy
    }

    /// Drag left without dropping. Restore the prior state — typically collapse back to
    /// compact since most drags-near-the-notch don't end in a drop.
    func nookPanelDraggingExited() {
        guard isDragInFlight else { return }
        isDragInFlight = false

        let prior = stateBeforeDrag
        stateBeforeDrag = nil

        guard let prior else { return }
        let screen = windowController?.window?.screen ?? resolvedScreen
        guard let screen else { return }
        Task {
            switch prior {
            case .compact:
                await _compact(on: screen, skipHide: true)
            case .hidden:
                _hide()
            case .expanded:
                break
            }
        }
    }

    /// File drop landed. Hand the URLs to the registered callback; if it accepts, leave
    /// the nook expanded so the registration UI is visible, otherwise restore prior state.
    func nookPanelPerformDrop(_ urls: [URL]) -> Bool {
        let accepted = onFileDrop?(urls) ?? false

        isDragInFlight = false
        let prior = stateBeforeDrag
        stateBeforeDrag = nil

        if !accepted, let prior {
            let screen = windowController?.window?.screen ?? resolvedScreen
            if let screen {
                Task {
                    switch prior {
                    case .compact:
                        await _compact(on: screen, skipHide: true)
                    case .hidden:
                        _hide()
                    case .expanded:
                        break
                    }
                }
            }
        }
        return accepted
    }
}
