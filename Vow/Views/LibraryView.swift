import SwiftUI

struct PhraseRow: View {
    @Environment(\.appAccent) private var accent
    @Environment(LearningStore.self) private var store
    let phrase: Phrase
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(phrase.phrase).font(.system(.title2, design: .serif))
                Text(phrase.explanation(in: store.data.meaningLanguage)).font(.subheadline).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if store.data.saved.contains(phrase.id) { Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(accent.color).accessibilityLabel("Saved") }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
        }.padding(.vertical, Spacing.sm).foregroundStyle(Palette.ink).contentShape(Rectangle())
    }
}

private struct PhraseSortMenu: View {
    @Environment(LearningStore.self) private var store
    var body: some View {
        Menu {
            Picker("Sort", selection: Binding(get: { store.data.sortOrder }, set: { store.configure(sort: $0) })) {
                ForEach(PhraseSort.allCases, id: \.self) { Text($0.title).tag($0) }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down").frame(width: 44, height: 44)
        }.accessibilityLabel("Sort phrases").accessibilityValue(store.data.sortOrder.title)
    }
}

struct LibraryView: View {
    @Environment(\.appAccent) private var accent
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(LearningStore.self) private var store
    @State private var query = ""
    @State private var collection = LibraryCollection.all
    var body: some View {
        let results = LibraryResults(phrases: store.phrases, collection: collection, query: query,
                                     sort: store.data.sortOrder, reviews: store.data.reviews, saved: store.data.saved)
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                (typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                    : AnyLayout(HStackLayout(spacing: Spacing.lg))) {
                    NavigationLink { ScenesView() } label: {
                        Label("Scenes", systemImage: "square.grid.2x2").frame(minHeight: 44)
                    }.accessibilityIdentifier("browseScenes")
                    NavigationLink { ParticleGalleryView() } label: {
                        Label("Core images", systemImage: "circle.hexagongrid").frame(minHeight: 44)
                    }.accessibilityIdentifier("coreImages")
                }
                Picker("Collection", selection: $collection) {
                    ForEach(LibraryCollection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                if results.isEmpty {
                    ContentUnavailableView(collection == .saved && query.isEmpty ? "No saved phrases" : "No matching phrases", systemImage: collection == .saved ? "bookmark" : "magnifyingglass")
                } else if collection == .verbs {
                    Text("\(results.groups.count) verbs").font(.caption).foregroundStyle(Palette.secondary)
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(results.groups) { group in
                            NavigationLink { VerbGroupView(verb: group.verb) } label: {
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Text(group.verb).font(.system(.title, design: .serif)).foregroundStyle(accent.color)
                                    Spacer(minLength: Spacing.sm)
                                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                                        Text("\(group.phrases.count) phrases").font(.subheadline.weight(.medium))
                                        Text(group.phrases.prefix(3).map(\.phrase).joined(separator: " · ")).font(.caption).foregroundStyle(Palette.secondary).multilineTextAlignment(.trailing)
                                    }
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary).padding(.top, Spacing.xs)
                                }.padding(Spacing.lg).foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("verbGroup-\(group.verb)")
                        }
                    }
                } else {
                    Text("\(results.phrases.count) phrases").font(.caption).foregroundStyle(Palette.secondary)
                    LazyVStack(spacing: 0) {
                        ForEach(results.phrases) { phrase in
                            NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }.buttonStyle(.plain).accessibilityIdentifier("phraseRow-\(phrase.id)")
                            Divider()
                        }
                    }
                }
            }
        }.navigationTitle("Phrases").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search a verb, phrase, or meaning")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { PhraseSortMenu() } }
    }
}

struct VerbGroupView: View {
    @Environment(LearningStore.self) private var store
    let verb: String
    var body: some View {
        let phrases = store.data.sortOrder.ordered(store.phrases.filter { $0.baseVerb == verb }, reviews: store.data.reviews)
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("\(phrases.count) phrases").font(.caption).foregroundStyle(Palette.secondary)
                LazyVStack(spacing: 0) {
                    ForEach(phrases) { phrase in
                        NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }.buttonStyle(.plain).accessibilityIdentifier("phraseRow-\(phrase.id)")
                        Divider()
                    }
                }
            }
        }.navigationTitle(verb).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { PhraseSortMenu() } }
    }
}

struct PhraseDetailView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let phrase: Phrase
    @State private var voice = VoicePractice()
    @State private var session: PracticeSelection?
    @State private var note = ""
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Eyebrow(text: Scene.all.first { $0.id == phrase.scene }?.subtitle ?? "Conversation")
                Text(phrase.phrase).font(.system(.largeTitle, design: .serif))
                Text(phrase.explanation(in: store.data.meaningLanguage)).font(.title3)
                PhraseConnections(phrase: phrase)
                if let aliases = phrase.aliases, !aliases.isEmpty {
                    Text(aliases.joined(separator: " · ")).font(.subheadline).foregroundStyle(Palette.secondary)
                }
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(phrase.examples.count > 1 ? "Examples" : "Example").font(.headline)
                    PhraseExamples(phrase: phrase)
                    HStack(spacing: Spacing.sm) {
                        Button("Listen", systemImage: "speaker.wave.2") { voice.speak(phrase.reply) }.frame(minHeight: 44)
                        Spacer()
                        Button("Slower", systemImage: "tortoise") { voice.speak(phrase.reply, slow: true) }.frame(minHeight: 44)
                    }.font(.subheadline)
                }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
                if !phrase.frame.isEmpty || !phrase.nuance.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        if !phrase.frame.isEmpty { Text(phrase.frame).font(.title3) }
                        if !phrase.nuance.isEmpty { Text(phrase.nuance).font(.body).foregroundStyle(Palette.secondary) }
                    }
                }
                if !phrase.contrast.isEmpty { Text(phrase.contrast).font(.body) }
                if let usage = phrase.referenceUsage {
                    DisclosureGroup("More usage") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text(usage.explanation(in: store.data.meaningLanguage)).font(.body)
                            Text("“\(usage.example)”").font(.system(.title3, design: .serif))
                            Button("Listen", systemImage: "speaker.wave.2") { voice.speak(usage.example) }.frame(minHeight: 44)
                        }.padding(.vertical, Spacing.sm)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your sentence").font(.headline)
                    TextField("Add an example…", text: $note, axis: .vertical).lineLimit(3...6).padding(Spacing.md).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)).accessibilityIdentifier("personalNote")
                    }
                PrimaryButton(title: purchases.allows(phrase) ? "Practice speaking" : "Unlock speaking practice") { voice.stopPlayback(); session = .init(phrases: [phrase]) }.accessibilityIdentifier("practicePhrase")
                if let url = URL(string: phrase.source), url.scheme == "https" { Link("Dictionary", destination: url).font(.subheadline).frame(minHeight: 44) }
                if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
            }
        }.navigationTitle("Phrase notes").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button { store.toggleSaved(phrase.id) } label: { Image(systemName: store.data.saved.contains(phrase.id) ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44) }.accessibilityLabel(store.data.saved.contains(phrase.id) ? "Unsave phrase" : "Save phrase") }
            .onAppear { note = store.data.notes[phrase.id] ?? "" }
            .onChange(of: note) { _, newValue in store.note(newValue, for: phrase.id) }
            .onChange(of: scenePhase) { _, value in if value != .active { voice.stopPlayback() } }
            .onDisappear { voice.clear() }
            .fullScreenCover(item: $session) { PracticeAccessView(phrases: $0.phrases, primedIDs: [phrase.id]) }
    }
}

/// Parallel links for the verb family and particle images, shared by Today and phrase details.
struct PhraseConnections: View {
    @Environment(\.appAccent) private var accent
    let phrase: Phrase
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.xs) { links }
            VStack(spacing: Spacing.xs) { links }
        }.font(.subheadline).buttonStyle(.plain).foregroundStyle(accent.color)
    }
    @ViewBuilder private var links: some View {
        NavigationLink { VerbGroupView(verb: phrase.baseVerb) } label: {
            Label(phrase.baseVerb, systemImage: "square.stack")
                .padding(.horizontal, Spacing.sm).frame(minHeight: 44)
                .background(Palette.surface, in: Capsule())
        }.accessibilityLabel("Verb family: \(phrase.baseVerb)").accessibilityIdentifier("phraseVerb-\(phrase.baseVerb)")
        ForEach(phrase.particleConcepts) { concept in
            NavigationLink { ParticleImageDetailView(concept: concept) } label: {
                Label(concept.id, systemImage: "circle.hexagongrid")
                    .padding(.horizontal, Spacing.sm).frame(minHeight: 44)
                    .background(Palette.surface, in: Capsule())
            }.accessibilityLabel("Core image: \(concept.id)").accessibilityIdentifier("phraseImage-\(concept.id)")
        }
    }
}

struct PhraseExamples: View {
    let phrase: Phrase
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(phrase.examples.enumerated()), id: \.offset) { index, example in
                Text("“\(example)”").font(.system(.title3, design: .serif)).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(index == 0 ? "featuredExample" : "featuredExample-\(index)")
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
