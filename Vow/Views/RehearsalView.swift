import SwiftUI
import AVFoundation

struct RehearsalView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let scene: Scene
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
            VStack(alignment: .leading, spacing: 26) {
                if complete {
                    CompletionMark()
                    Text("3 takes completed").font(.subheadline).foregroundStyle(Palette.secondary).accessibilityIdentifier("rehearsalComplete")
                } else {
                    Eyebrow(text: "Take \(take + 1) of 3 · \(scene.subtitle)")
                    Text(scene.prompt).font(.title3).lineSpacing(5)
                    Text(take == 0 ? "Tell the same story on all three takes." : "Retell the same story.").font(.subheadline).foregroundStyle(Palette.secondary)
                    if !store.data.gentleMode {
                        TimelineView(.explicit(timerDates)) { context in
                            let remaining = max(0, lengths[take] - Int(context.date.timeIntervalSince(started ?? context.date)))
                            HStack {
                                Text("\(remaining)").font(.system(size: 64, weight: .light, design: .serif)).monospacedDigit()
                                Text(remaining == 0 ? "Finish your thought." : "seconds").font(.caption).foregroundStyle(Palette.secondary)
                                Spacer()
                                if started == nil { Button("Start timer") { started = .now }.buttonStyle(.bordered).frame(minHeight: 44) }
                            }.accessibilityElement(children: .contain)
                        }
                    }
                    VoiceReplyPanel(voice: voice, spoken: $spoken, typed: $typed, reply: $reply)
                    DisclosureGroup("Phrase hints") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(store.phrases.filter { $0.scene == scene.id }.prefix(3)) { phrase in Text(phrase.frame).font(.subheadline) }
                        }.padding(.vertical, 12)
                    }
                    PrimaryButton(title: take == 2 ? "Finish" : "Start take \(take + 2)") {
                        voice.clear(); started = nil; spoken = false; reply = ""
                        if take < 2 { take += 1 } else { store.finishRehearsal(); complete = true }
                    }.disabled(!canAdvance || voice.isRecording || voice.isRequesting).opacity(canAdvance ? 1 : 0.45)
                }
            }
        }.navigationTitle("Story practice").navigationBarTitleDisplayMode(.inline)
            .onDisappear { voice.clear() }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stopRecording(); voice.stopPlayback(); started = nil }
            .onChange(of: scenePhase) { _, phase in if phase == .background { voice.suspend(); started = nil } else if phase == .inactive { voice.stopRecording(); voice.stopPlayback() } }
    }
}
