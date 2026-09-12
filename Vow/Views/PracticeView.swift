import SwiftUI

struct PracticeView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let phrases: [Phrase]
    var primedIDs: Set<String> = []
    @State private var index = 0
    @State private var phase = 0 // recall, compare, transfer, reflect
    @State private var reply = ""
    @State private var firstReply = ""
    @State private var usedHint = false
    @State private var hintExpanded = false
    @State private var spoken = false
    @State private var typed = false
    @State private var voice = VoicePractice()
    @State private var retry: [Phrase] = []
    @State private var ratings: [RecallRating] = []
    @State private var showExit = false
    private var queue: [Phrase] { phrases + retry }
    private var complete: Bool { index >= queue.count }
    private var phrase: Phrase? { complete ? nil : queue[index] }
    private var attempted: Bool { spoken || voice.hasRecording || !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: 24) {
                    if let phrase {
                        HStack {
                            Eyebrow(text: "\(index + 1) of \(queue.count) · \(["Retrieve", "Notice", "Transfer", "Reflect"][phase])")
                            Spacer()
                            Text("\(phase + 1)/4").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                        }
                        SwiftUI.ProgressView(value: Double(index * 4 + phase), total: Double(max(queue.count * 4, 1))).tint(Palette.accent).accessibilityLabel("Session progress")
                        if phase == 0 || phase == 2 { prompt(phrase) }
                        if phase == 1 { comparison(phrase) }
                        if phase == 3 { reflection(phrase) }
                    } else { completion }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .id("\(index)-\(phase)")
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { if complete { dismiss() } else { showExit = true } } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Close practice") }
            }
            .confirmationDialog("Leave this practice?", isPresented: $showExit, titleVisibility: .visible) {
                Button("Leave practice", role: .destructive) { dismiss() }
                Button("Keep practicing", role: .cancel) { }
            } message: { Text("Completed reviews are saved. Your current reply and recording will be discarded.") }
        }.interactiveDismissDisabled(!complete)
            .onDisappear { voice.clear() }
            .onChange(of: scenePhase) { _, value in if value == .background { voice.suspend() } else if value == .inactive { voice.stopRecording(); voice.stopPlayback() } }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stopRecording(); voice.stopPlayback() }
    }

    @ViewBuilder private func prompt(_ phrase: Phrase) -> some View {
        if phase == 0 && phrase.usesExampleRecall {
            Text("Complete the sentence.").font(.headline)
            Text(phrase.explanation(in: store.data.meaningLanguage)).font(.subheadline).foregroundStyle(Palette.secondary)
        }
        Text(phase == 0 ? phrase.cue : phrase.transferCue).font(.title3).lineSpacing(5).fixedSize(horizontal: false, vertical: true)
            .padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
        if phase == 2 && !phrase.usesExampleRecall { Text("Use the same phrase in this situation.").font(.subheadline).foregroundStyle(Palette.secondary) }
        if phase == 0 {
            DisclosureGroup("Hint", isExpanded: $hintExpanded) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(phrase.phrase).font(.system(.title2, design: .serif))
                    Text(phrase.explanation(in: store.data.meaningLanguage)).font(.subheadline)
                }.padding(.vertical, 10)
            }.font(.subheadline).onChange(of: hintExpanded) { _, expanded in if expanded { usedHint = true } }
        }
        VoiceReplyPanel(voice: voice, spoken: $spoken, typed: $typed, reply: $reply)
        PrimaryButton(title: phase == 0 ? "Compare reply" : "Review reply", symbol: "arrow.right") {
            voice.stopRecording(); voice.stopPlayback()
            if phase == 0 { firstReply = reply }
            move(to: phase + 1)
        }.disabled(!attempted || voice.isRecording || voice.isRequesting).opacity(attempted ? 1 : 0.45).accessibilityIdentifier("advanceReply")
    }

    @ViewBuilder private func comparison(_ phrase: Phrase) -> some View {
        Text(phrase.phrase).font(.system(.largeTitle, design: .serif)).accessibilityIdentifier("revealedPhrase")
        Text(phrase.explanation(in: store.data.meaningLanguage)).font(.title3)
        VStack(alignment: .leading, spacing: 16) {
            Text("“\(phrase.reply)”").font(.system(.title2, design: .serif)).lineSpacing(5)
            HStack(spacing: 20) {
                Button("Listen", systemImage: "speaker.wave.2") { voice.speak(phrase.reply) }.frame(minHeight: 44)
                Button("Slower", systemImage: "tortoise") { voice.speak(phrase.reply, slow: true) }.frame(minHeight: 44)
                if voice.hasRecording { Button("My take", systemImage: "play.circle") { voice.play() }.frame(minHeight: 44) }
            }.font(.caption.weight(.medium))
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
        if !firstReply.isEmpty { VStack(alignment: .leading, spacing: 8) { Eyebrow(text: "Your reply"); Text(firstReply).font(.body) } }
        if !phrase.frame.isEmpty || !phrase.nuance.isEmpty || !phrase.contrast.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                if !phrase.frame.isEmpty { Text(phrase.frame).font(.headline) }
                if !phrase.nuance.isEmpty { Text(phrase.nuance).font(.subheadline).foregroundStyle(Palette.secondary) }
                if !phrase.contrast.isEmpty { Text(phrase.contrast).font(.subheadline) }
            }
        }
        PrimaryButton(title: phrase.usesExampleRecall ? "Make your own sentence" : "Try a new situation") {
            voice.clear(); reply = ""; spoken = false
            move(to: 2)
        }.accessibilityIdentifier("tryTransfer")
    }

    @ViewBuilder private func reflection(_ phrase: Phrase) -> some View {
        Text(phrase.phrase).font(.title2.weight(.medium))
        if !phrase.transferReply.isEmpty {
            DisclosureGroup("Compare the new situation") {
                Text(phrase.transferReply).font(.body).padding(.vertical, 12)
            }
        } else {
            Text(phrase.explanation(in: store.data.meaningLanguage)).font(.subheadline).foregroundStyle(Palette.secondary)
            DisclosureGroup("Check your sentence") {
                Text("Does it keep the intended meaning? Check the verb form and word order against the example.").font(.body).padding(.vertical, 12)
                Text(phrase.reply).font(.body)
            }
        }
        if !reply.isEmpty { Text(reply).padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)) }
        if voice.hasRecording { Button("Listen to my reply", systemImage: "play.circle") { voice.play() }.frame(minHeight: 44) }
        Text(primedIDs.contains(phrase.id) ? "You previewed this phrase. Try unprompted recall after a gap." : usedHint ? "You used a hint. Rate your first attempt." : "Rate your first attempt.")
            .font(.subheadline).foregroundStyle(Palette.secondary)
        ForEach(RecallRating.allCases, id: \.self) { rating in
            Button { save(rating, phrase: phrase) } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(rating.title).font(.headline)
                        Text(rating == .again ? "Another try, then revisit in 10 minutes" : (rating == .effort ? "I found it, but had to search" : "I recalled it without a hint")).font(.caption).foregroundStyle(Palette.secondary)
                    }
                    Spacer(); Image(systemName: "arrow.right")
                }.padding(20).foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: 22))
            }.buttonStyle(PressStyle()).disabled((usedHint || primedIDs.contains(phrase.id)) && rating == .ready).opacity((usedHint || primedIDs.contains(phrase.id)) && rating == .ready ? 0.4 : 1).accessibilityIdentifier("rate-\(rating.rawValue)")
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 26) {
            CompletionMark()
            Text(phrases.isEmpty ? "No reviews due" : "Practice complete").font(.system(.largeTitle, design: .serif))
            Text(phrases.isEmpty ? "You're up to date. Explore a scene, or come back when your next review is ready." : "You practiced \(ratings.count) replies across \(phrases.count) phrases. Your next reviews are scheduled.").font(.body).foregroundStyle(Palette.secondary)
            PrimaryButton(title: "Done", symbol: "checkmark") { dismiss() }.accessibilityIdentifier("finishPractice")
        }
    }

    private func save(_ rating: RecallRating, phrase: Phrase) {
        guard rating != .ready || !(usedHint || primedIDs.contains(phrase.id)) else { return }
        let wasRetry = index >= phrases.count
        // Immediate retries are practice, never a second spaced-repetition success.
        if !wasRetry { store.rate(phrase, rating, mode: typed ? "typed" : "spoken") }
        if rating == .again, !wasRetry { retry.append(phrase) }
        ratings.append(rating)
        voice.clear(); reply = ""; firstReply = ""; spoken = false; usedHint = false
        hintExpanded = false; phase = 0; index += 1
    }
    private func move(to phase: Int) { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { self.phase = phase } }
}

import AVFoundation

struct VoiceReplyPanel: View {
    @Bindable var voice: VoicePractice
    @Binding var spoken: Bool
    @Binding var typed: Bool
    @Binding var reply: String
    @State private var requestTask: Task<Void, Never>?
    @FocusState private var typing: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if typed {
                TextField("Your reply…", text: $reply, axis: .vertical)
                    .lineLimit(3...6).focused($typing).padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)).accessibilityIdentifier("replyField")
                    .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { typing = false } } }
            } else {
                HStack(spacing: 16) {
                    Button {
                        if voice.isRecording { voice.stopRecording() }
                        else { requestTask = Task { await voice.start() } }
                    } label: {
                        Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill").font(.title2)
                            .frame(width: 64, height: 64).foregroundStyle(.white)
                            .background(voice.isRecording ? Palette.action : Palette.charcoal, in: Circle())
                    }.buttonStyle(PressStyle()).disabled(voice.isRequesting).accessibilityLabel(voice.isRecording ? "Stop recording" : "Record my reply")
                    VStack(alignment: .leading, spacing: 5) {
                        Text(voice.isRequesting ? "Allow the microphone to record" : (voice.isRecording ? "Recording" : (voice.hasRecording ? "Recording ready" : "Record a reply"))).font(.headline)
                        if voice.isRecording {
                            TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                                HStack(spacing: 8) {
                                    Text("\(Int(voice.elapsed))s / 180s").monospacedDigit()
                                    Capsule().fill(Palette.accent).frame(width: max(4, voice.level * 80), height: 5)
                                }.font(.caption).accessibilityLabel("Recording")
                            }
                        }
                    }
                }
                if voice.hasRecording {
                    Button(voice.isPlaying ? "Stop playback" : "Listen to my take", systemImage: voice.isPlaying ? "stop.circle" : "play.circle") { if voice.isPlaying { voice.stopPlayback() } else { voice.play() } }.frame(minHeight: 44)
                }
                Toggle("I said my reply without recording", isOn: $spoken).font(.subheadline).tint(Palette.accent)
            }
            Button(typed ? "Speak instead" : "Type a reply", systemImage: typed ? "mic" : "keyboard") {
                voice.clear(); spoken = false; reply = ""; typed.toggle()
            }.font(.subheadline).frame(minHeight: 44)
            if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
        }.onDisappear { requestTask?.cancel() }
    }
}
