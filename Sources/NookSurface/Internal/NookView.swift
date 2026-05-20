// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Kai Azim — DynamicNotchKit (original)
// Copyright (c) 2026 Glendon Chin — OpenNook modifications
//
// Licensed under the MIT License.
// Original kit license: /ThirdPartyLicenses/DynamicNotchKit.txt
// Modifications license: /LICENSE-MIT-NOOKSURFACE

import SwiftUI

/// The notch chrome itself: arches around the menu-bar notch, switches between expanded and
/// compact-with-side-slots, and paints the configured backdrop behind both.
struct NookView<Expanded, CompactLeading, CompactTrailing>: View
where Expanded: View, CompactLeading: View, CompactTrailing: View {
    @ObservedObject private var nook: Nook<Expanded, CompactLeading, CompactTrailing>
    @State private var compactLeadingWidth: CGFloat = 0
    @State private var compactTrailingWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let safeAreaInset: CGFloat = 8

    init(nook: Nook<Expanded, CompactLeading, CompactTrailing>) {
        self.nook = nook
    }

    private var expandedCornerRadii: (top: CGFloat, bottom: CGFloat) {
        (top: nook.style.topCornerRadius, bottom: nook.style.bottomCornerRadius)
    }

    private var compactCornerRadii: (top: CGFloat, bottom: CGFloat) {
        (top: 6, bottom: 14)
    }

    private var minWidth: CGFloat {
        nook.notchSize.width + (topCornerRadius * 2)
    }

    private var topCornerRadius: CGFloat {
        nook.state == .expanded ? expandedCornerRadii.top : compactCornerRadii.top
    }

    private var bottomCornerRadius: CGFloat {
        nook.state == .expanded ? expandedCornerRadii.bottom : compactCornerRadii.bottom
    }

    /// In compact mode, slot-width asymmetry shifts the whole shape so the gap stays centered on the notch.
    private var xOffset: CGFloat {
        nook.state == .compact ? compactXOffset : 0
    }

    private var compactXOffset: CGFloat {
        (compactTrailingWidth - compactLeadingWidth) / 2
    }

    /// Backdrop sits behind chrome content, both flattened into a single layer, then clipped
    /// to the animatable notch shape. Compositing as one group means the spring animation can
    /// scale content + backdrop atomically — no magic overshoot padding required to plug
    /// edge gaps mid-bounce.
    ///
    /// The matching `.contentShape(NookShape)` is critical: `.clipShape` only clips drawing,
    /// not hit-testing. Without it, the hover region falls back to the rectangular bounds —
    /// which extend down into the would-be-expanded area because the expanded content's
    /// `.fixedSize()` doesn't actually collapse to 0×0 when wrapped in a max-frame. Result:
    /// hovering in the empty space below a compact nook triggers the hover-grow animation.
    /// Hit-testing the same `NookShape` we render confines hover to the visible chrome.
    var body: some View {
        notchContent()
            .background { notchBackdrop() }
            .overlay { feedbackOverlay() }
            .compositingGroup()
            .clipShape(notchShape)
            .contentShape(notchShape)
            .onHover(perform: nook.updateHoverState)
            .offset(x: xOffset)
            .animation(nook.effectiveConversionAnimation, value: nook.state)
            .animation(nook.effectiveConversionAnimation, value: [compactLeadingWidth, compactTrailingWidth])
    }

    /// Peripheral cue overlay. Sits above backdrop+content but inside the compositing group,
    /// so the shimmer stroke flattens with the chrome before the notch shape carves the visible
    /// region — no edge gaps mid-bounce, no spillover beyond the arch.
    private func feedbackOverlay() -> some View {
        NookFeedbackOverlay(
            event: nook.feedbackEvent,
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius,
            reduceMotion: reduceMotion
        )
    }

    private var notchShape: NookShape {
        NookShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    private func notchBackdrop() -> some View {
        let configuration = nook.backdropConfiguration
        return Group {
            if configuration.usesVisualEffect {
                ZStack {
                    VisualEffectView(
                        material: configuration.material,
                        blendingMode: configuration.blendingMode
                    )
                    Color(
                        red: configuration.tintRed,
                        green: configuration.tintGreen,
                        blue: configuration.tintBlue
                    )
                    .opacity(configuration.tintOpacity)
                    Color.black.opacity(configuration.darkenOpacity)
                }
            } else {
                Color(
                    red: configuration.opaqueRed,
                    green: configuration.opaqueGreen,
                    blue: configuration.opaqueBlue
                )
            }
        }
    }

    private func notchContent() -> some View {
        ZStack {
            compactContent()
                .fixedSize()
                .offset(x: nook.state == .compact ? 0 : compactXOffset)
                .frame(
                    width: nook.state == .compact ? nil : nook.notchSize.width,
                    height: (nook.state == .compact && nook.isHovering) ? nook.menubarHeight : nook.notchSize.height
                )

            expandedContent()
                .fixedSize()
                .frame(
                    maxWidth: nook.state == .expanded ? nil : 0,
                    maxHeight: nook.state == .expanded ? nil : 0
                )
                .offset(x: nook.state == .compact ? -compactXOffset : 0)
        }
        .padding(.horizontal, topCornerRadius)
        .fixedSize()
        .frame(minWidth: minWidth, minHeight: nook.notchSize.height)
    }

    private func compactContent() -> some View {
        HStack(spacing: 0) {
            if nook.state == .compact, !nook.disableCompactLeading {
                nook.compactLeadingContent
                    .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: 8) }
                    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 4) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 8) }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { compactLeadingWidth = $0 }
                    .transition(.blur(intensity: 6).combined(with: .scale(x: 0, anchor: .trailing)).combined(with: .opacity))
            }

            Spacer()
                .frame(width: nook.notchSize.width)

            if nook.state == .compact, !nook.disableCompactTrailing {
                nook.compactTrailingContent
                    .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: 8) }
                    .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 4) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 8) }
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { compactTrailingWidth = $0 }
                    .transition(.blur(intensity: 6).combined(with: .scale(x: 0, anchor: .leading)).combined(with: .opacity))
            }
        }
        .frame(height: nook.notchSize.height)
        .onChange(of: nook.disableCompactLeading) { _ in
            if nook.disableCompactLeading {
                compactLeadingWidth = 0
            }
        }
        .onChange(of: nook.disableCompactTrailing) { _ in
            if nook.disableCompactTrailing {
                compactTrailingWidth = 0
            }
        }
    }

    private func expandedContent() -> some View {
        HStack(spacing: 0) {
            if nook.state == .expanded {
                nook.expandedContent
                    .transition(.blur(intensity: 6).combined(with: .scale(y: 0.72, anchor: .top)).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 0) }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: safeAreaInset) }
        .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: safeAreaInset) }
        .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: safeAreaInset) }
        .frame(minWidth: nook.notchSize.width)
    }
}
