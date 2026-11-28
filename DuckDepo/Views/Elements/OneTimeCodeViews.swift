//
//  OneTimeCodeViews.swift
//  DuckDepo
//

import SwiftUI

/// The current code, updated as it changes: "123 456".
struct OneTimeCodeText: View {

    let code: OneTimeCode

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let current = code.code(at: context.date)
            Text(OneTimeCode.formatted(current))
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(.tint)
                .contentTransition(.numericText())
                .animation(.default, value: current)
        }
    }
}

/// A one-time code on the password's page: the code, how long it has left, and a copy button.
struct OneTimeCodeRow: View {

    let code: OneTimeCode
    let onCopy: (String) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let current = code.code(at: context.date)
            let remaining = code.secondsRemaining(at: context.date)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("otp_title")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(OneTimeCode.formatted(current))
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .contentTransition(.numericText())
                        .animation(.default, value: current)
                }
                Spacer()
                CountdownRing(remaining: remaining, period: code.period)
                Button {
                    onCopy(current)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("otp_copy"))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("otp_accessibility \(current) \(remaining)"))
        }
    }
}

/// Seconds left on the current code, as a ring that empties. Turns red in the last few seconds.
private struct CountdownRing: View {

    let remaining: Int
    let period: Int

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 28

    var body: some View {
        // Not `.accentColor`: the project has no AccentColor asset, so that could be system blue.
        let color: Color = remaining <= 5 ? .red : .duckYellow
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(remaining) / CGFloat(max(period, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remaining)
            Text(remaining, format: .number)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(remaining <= 5 ? .red : .secondary)
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: remaining)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    List {
        OneTimeCodeRow(code: OneTimeCode(text: "JBSWY3DPEHPK3PXP")!) { _ in }
        OneTimeCodeText(code: OneTimeCode(text: "JBSWY3DPEHPK3PXP")!)
    }
    .tint(.duckYellow)
}
