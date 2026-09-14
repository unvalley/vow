import SwiftUI

struct ListeningView: View {
    var initialCollection: ListeningCollection = .all
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(ListeningPlayer.self) private var player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var preferences = ListeningPreferences()

    private var preview: ListeningSession {
        ListeningSession(phrases: store.data.sortOrder.ordered(store.phrases, reviews: store.data.reviews),
                         purchased: purchases.hasFullAccess, saved: store.data.saved,
                         preferences: preferences, meaningLanguage: store.data.meaningLanguage)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    if let session = player.session, let phrase = session.phrase {
                        Section {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("\(session.index + 1) / \(session.phrases.count)")
                                    .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                                    .accessibilityIdentifier("listeningPosition")
                                Text(phrase.phrase).font(Typography.phrase)
                                    .accessibilityIdentifier("listeningPhrase")
                                PhraseMeaning(phrase: phrase, language: session.meaningLanguage, font: .body)
                                if let segment = session.segment, session.segmentIndex > 0, segment.text != phrase.explanation(in: session.meaningLanguage) {
                                    Text(segment.text).font(.subheadline).foregroundStyle(Palette.secondary)
                                        .accessibilityIdentifier("listeningSegment")
                                }
                                if player.isFinished { Text("Playlist complete").font(.subheadline) }
                                playbackControls
                                if let deadline = player.sleepDeadline {
                                    Text("Stops at \(deadline.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption).foregroundStyle(Palette.secondary)
                                }
                            }.padding(.vertical, Spacing.sm).id("listeningNow")
                            Button("Stop listening", role: .destructive) { player.stop() }
                                .frame(minHeight: 44).accessibilityIdentifier("stopListening")
                        } footer: {
                            Text("Playback continues when you close this screen or lock your device.")
                        }
                    }

                    if let message = player.message {
                        Section { Text(message).font(.subheadline).accessibilityIdentifier("listeningMessage") }
                    }

                    Section {
                        Picker("Collection", selection: $preferences.collection) {
                            ForEach(ListeningCollection.allCases, id: \.self) { collection in
                                Text(LocalizedStringKey(collection.title)).tag(collection)
                                    .accessibilityIdentifier("listeningCollection-\(collection.rawValue)")
                            }
                        }.accessibilityIdentifier("listeningCollection")
                        Text("\(preview.phrases.count) expressions").font(.subheadline.monospacedDigit())
                            .foregroundStyle(Palette.secondary).accessibilityIdentifier("listeningCount")
                        Toggle("Include meanings", isOn: $preferences.includesMeaning).accessibilityIdentifier("listeningMeanings")
                        Toggle("Include an example", isOn: $preferences.includesExample).accessibilityIdentifier("listeningExamples")
                        Toggle("Shuffle", isOn: $preferences.shuffled)
                        Toggle("Repeat playlist", isOn: $preferences.repeats)
                        Toggle("Slower speech", isOn: $preferences.slower)
                        Picker("Sleep timer", selection: $preferences.sleepMinutes) {
                            Text("Off").tag(0)
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                            Text("60 minutes").tag(60)
                        }
                    } header: {
                        Text("Playlist")
                    } footer: {
                        Text("Meanings follow your meaning-language setting. English uses your selected reading voice. Listening does not change your review schedule.")
                    }
                    Section {
                        Button(LocalizedStringKey(player.hasSession ? "Apply & restart" : "Start listening"), systemImage: "play.fill") {
                            store.configureListening(preferences)
                            player.start(preview, voiceID: store.data.speechVoiceID)
                        }.frame(maxWidth: .infinity, minHeight: 48)
                            .disabled(preview.phrases.isEmpty).accessibilityIdentifier("startListening")
                    }
                }.scrollContentBackground(.hidden).background { ReadingBackground() }
                    .navigationTitle("Continuous listening").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                    .onChange(of: player.hasSession) { _, active in
                        if active { proxy.scrollTo("listeningNow", anchor: .top) }
                    }
            }
        }
        .onAppear {
            if let session = player.session { preferences = session.preferences }
            else {
                preferences = store.data.listeningPreferences ?? .init()
                preferences.collection = initialCollection
            }
        }
    }

    private var playbackControls: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.lg))
        return layout {
            Button { player.skip(-1) } label: { Image(systemName: "backward.end.fill").frame(minWidth: 44, minHeight: 44) }
                .accessibilityLabel("Previous expression").accessibilityIdentifier("listeningPrevious")
                .disabled(player.session?.canGoBack != true)
            Button { player.toggle() } label: {
                Label(LocalizedStringKey(player.isPlaying ? "Pause" : "Play"), systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(Typography.control).frame(minWidth: 100, minHeight: 52)
            }.accessibilityIdentifier("listeningPlayPause")
            Button { player.skip(1) } label: { Image(systemName: "forward.end.fill").frame(minWidth: 44, minHeight: 44) }
                .accessibilityLabel("Next expression").accessibilityIdentifier("listeningNext")
                .disabled(player.session?.canGoForward != true)
        }.buttonStyle(.plain).frame(maxWidth: .infinity)
    }
}

struct ListeningMiniPlayer: View {
    @Environment(ListeningPlayer.self) private var player
    let open: () -> Void

    var body: some View {
        if let phrase = player.session?.phrase {
            HStack(spacing: Spacing.xs) {
                Button(action: open) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "headphones")
                        Text(phrase.phrase).font(.subheadline.weight(.medium)).lineLimit(1)
                        Spacer(minLength: 0)
                    }.frame(minHeight: 48).contentShape(Rectangle())
                }.accessibilityLabel("Open continuous listening").accessibilityValue(phrase.phrase)
                    .accessibilityIdentifier("listeningMiniPlayer")
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").frame(width: 48, height: 48)
                }.accessibilityLabel(Text(player.isPlaying ? "Pause" : "Play")).accessibilityIdentifier("miniListeningPlayPause")
                Button { player.stop() } label: { Image(systemName: "xmark").frame(width: 44, height: 48) }
                    .accessibilityLabel("Stop listening").accessibilityIdentifier("miniStopListening")
            }.buttonStyle(.plain).foregroundStyle(Palette.ink)
                .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.xxs)
                .background(Palette.paper).overlay(alignment: .top) { Divider() }
        }
    }
}
