import SwiftUI
import AVFoundation

struct RehearsalView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let scene: Scene
    @ScaledMetric(relativeTo: .largeTitle) private var timerSize = 64.0
    @State private var take = 0
    @State private var started: Date?
    @State private var complete = false
    @State private var spoken = false
    @State private var typed = false
    @State private var reply = ""
    @State private var voice = VoicePractice()
    private let lengths = [60, 45, 30]
    private var canAdvance: Bool { spoken || voice.hasRecording || !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var timerDates: [Date] {
        guard let started else { return [.now] }
        return (0...lengths[take]).map { started.addingTimeInterval(Double($0)) }
    }
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if complete {
                    CompletionMark()
                    Text("3 takes completed").font(.subheadline).foregroundStyle(Palette.secondary).accessibilityIdentifier("rehearsalComplete")
                } else {
                    Eyebrow(text: "Take \(take + 1) of 3 · \(scene.subtitle)")
                    Text(scene.prompt).font(Typography.meaning)
                    Text(take == 0 ? "Tell the same story on all three takes." : "Retell the same story.").font(.subheadline).foregroundStyle(Palette.secondary)
                    if !store.data.gentleMode {
                        TimelineView(.explicit(timerDates)) { context in
                            let remaining = max(0, lengths[take] - Int(context.date.timeIntervalSince(started ?? context.date)))
                            (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm)) : AnyLayout(HStackLayout(spacing: Spacing.sm))) {
                                Text("\(remaining)").font(.system(size: timerSize, weight: .regular)).monospacedDigit()
                                Text(remaining == 0 ? "Finish your thought." : "seconds").font(.caption).foregroundStyle(Palette.secondary)
                                if !typeSize.isAccessibilitySize { Spacer() }
                                if started == nil { Button("Start timer") { started = .now }.buttonStyle(.bordered).frame(minHeight: 44) }
                            }.accessibilityElement(children: .contain)
                        }
                    }
                    VoiceReplyPanel(voice: voice, spoken: $spoken, typed: $typed, reply: $reply)
                    DisclosureGroup("Phrase hints") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(store.phrases.filter { $0.scene == scene.id && purchases.allows($0) }.prefix(3)) { phrase in Text(phrase.frame).font(.subheadline) }
                        }.padding(.vertical, Spacing.sm)
                    }
                    PrimaryButton(title: take == 2 ? "Finish" : "Start take \(take + 2)") {
                        voice.clear(); started = nil; spoken = false; reply = ""
                        if take < 2 { take += 1 } else { store.finishRehearsal(); complete = true }
                    }.disabled(!canAdvance || voice.isRecording || voice.isRequesting)
                }
            }
        }.navigationTitle("Story practice").navigationBarTitleDisplayMode(.inline)
            .onDisappear { voice.clear() }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stopRecording(); voice.stopPlayback(); started = nil }
            .onChange(of: scenePhase) { _, phase in if phase == .background { voice.suspend(); started = nil } else if phase == .inactive { voice.stopRecording(); voice.stopPlayback() } }
    }
}
