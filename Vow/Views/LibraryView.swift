import SwiftUI

struct PhraseRow: View {
    @Environment(\.appAccent) private var accent
    @Environment(LearningStore.self) private var store
    let phrase: Phrase
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(phrase.phrase).font(Typography.phraseRow)
                if let difficulty = phrase.difficulty { PhraseDifficultyLabel(difficulty: difficulty) }
                PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, leadOnly: true, color: Palette.secondary)
            }
            Spacer(minLength: 0)
            if store.data.saved.contains(phrase.id) { Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(accent.color).accessibilityLabel("Saved") }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
        }.padding(.vertical, Spacing.sm).foregroundStyle(Palette.ink).contentShape(Rectangle())
    }
}

private struct PhraseSortMenu: View {
    @Environment(LearningStore.self) private var store
    /// Inline menus sit beside the filter and show their current choice; toolbar menus stay an icon.
    var inline = false
    var body: some View {
        Menu {
            // Plain buttons rather than a Picker: a Picker in this menu made the Phrases list open part-way down.
            ForEach(PhraseSort.allCases, id: \.self) { sort in
                Button { store.configure(sort: sort) } label: {
                    if store.data.sortOrder == sort { Label(sort.title, systemImage: "checkmark") } else { Text(sort.title) }
                }
            }
        } label: {
            if inline {
                MenuControlLabel(title: LocalizedStringKey(store.data.sortOrder.title), systemImage: "arrow.up.arrow.down")
            } else {
                Image(systemName: "arrow.up.arrow.down").frame(width: 44, height: 44)
            }
        }.accessibilityLabel("Sort phrases").accessibilityValue(store.data.sortOrder.title)
    }
}

struct LibraryView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(LearningStore.self) private var store
    @State private var listening = false
    @State private var query = ""
    @State private var collection = LibraryCollection.all
    @State private var difficulty: PhraseDifficulty?
    @State private var groupByVerb = false
    var body: some View {
        let grouped = groupByVerb && collection != .idioms
        let results = LibraryResults(phrases: store.phrases.filter { purchases.allows($0) }, collection: collection, query: query,
                                     sort: store.data.sortOrder, reviews: store.data.reviews, saved: store.data.saved,
                                     difficulty: difficulty, groupByVerb: grouped)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                header
                searchField
                if typeSize.isAccessibilitySize {
                    Menu {
                        Picker("Collection", selection: $collection) {
                            ForEach(LibraryCollection.allCases, id: \.self) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
                        }
                    } label: {
                        Label(LocalizedStringKey(collection.rawValue), systemImage: "chevron.down")
                            .font(Typography.control).frame(minHeight: 44)
                    }.accessibilityIdentifier("libraryCollection")
                        .accessibilityLabel("Collection").accessibilityValue(collection.rawValue)
                } else {
                    // Same switch as the Home modes: four equal segments that scale their text instead of truncating.
                    HStack(spacing: 0) {
                        ForEach(LibraryCollection.allCases, id: \.self) { item in
                            Button { collection = item } label: {
                                Text(LocalizedStringKey(item.rawValue))
                                    .font(.footnote.weight(collection == item ? .semibold : .medium))
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .padding(.horizontal, Spacing.xs)
                                    .selectionSurface(collection == item, cornerRadius: 100, restFill: .clear)
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(collection == item ? .isSelected : [])
                        }
                    }.padding(Spacing.xxs)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 100))
                        .accessibilityIdentifier("libraryCollection")
                }
                (typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
                    : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.md))) {
                    Text(grouped ? "\(results.groups.count) verbs" : (collection == .idioms ? "\(results.phrases.count) idioms" : "\(results.phrases.count) phrases"))
                        .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    filterMenu
                    sortMenu
                }
                if results.isEmpty {
                    ContentUnavailableView(collection == .saved && query.isEmpty ? "No saved phrases" : "No matching phrases", systemImage: collection == .saved ? "bookmark" : "magnifyingglass")
                    if !purchases.hasFullAccess { libraryProPrompt }
                } else if grouped {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(Array(results.groups.enumerated()), id: \.element.id) { index, group in
                            NavigationLink { VerbGroupView(verb: group.verb, difficulty: difficulty, savedOnly: collection == .saved) } label: {
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Text(group.verb).font(Typography.family).foregroundStyle(Palette.ink)
                                    Spacer(minLength: Spacing.sm)
                                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                                        Text("\(group.phrases.count) phrases").font(.subheadline.weight(.medium))
                                        Text(group.phrases.prefix(3).map(\.phrase).joined(separator: " · ")).font(.caption).foregroundStyle(Palette.secondary).multilineTextAlignment(.trailing)
                                    }
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary).padding(.top, Spacing.xs)
                                }.padding(Spacing.lg).foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("verbGroup-\(group.verb)")
                        }
                        if !purchases.hasFullAccess { libraryProPrompt }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.phrases.enumerated()), id: \.element.id) { index, phrase in
                            NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }.buttonStyle(.plain).accessibilityIdentifier("phraseRow-\(phrase.id)")
                            Divider()
                        }
                        if !purchases.hasFullAccess { libraryProPrompt }
                    }
                }
            }.frame(maxWidth: 680).padding(.horizontal, Spacing.lg).padding(.bottom, Spacing.xl).frame(maxWidth: .infinity)
        }.scrollDismissesKeyboard(.interactively).background { ReadingBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $listening) {
                ListeningView(initialCollection: collection == .idioms ? .idioms : collection == .saved ? .saved : collection == .phrasalVerbs ? .phrasalVerbs : .all)
            }
            .closesForReviewRequest($listening)
    }

    /// One menu narrows the list: by level, and by verb family. Idioms have no verb, so that
    /// option is hidden for them.
    private var filterMenu: some View {
        let levelTitle = difficulty?.rawValue ?? String(localized: "All levels")
        let grouped = groupByVerb && collection != .idioms
        return Menu {
            Picker("Level", selection: $difficulty) {
                Text("All levels").tag(Optional<PhraseDifficulty>.none)
                ForEach(PhraseDifficulty.allCases, id: \.self) { level in
                    Text(level.label(for: store.data.difficultyDisplay)).tag(Optional(level))
                }
            }
            if collection != .idioms {
                // A Button, not a Toggle: a Toggle inside a Menu in this scroll view made the list open mid-way.
                Button { groupByVerb.toggle() } label: {
                    Label("Group by verb", systemImage: groupByVerb ? "checkmark" : "square.stack")
                }
            }
        } label: {
            MenuControlLabel(title: grouped ? "\(levelTitle) · By verb" : LocalizedStringKey(levelTitle),
                                systemImage: "line.3.horizontal.decrease")
        }.accessibilityIdentifier("libraryFilter").accessibilityLabel("Filter phrases")
            .accessibilityValue(grouped ? "\(difficulty?.rawValue ?? "All levels") · By verb" : (difficulty?.rawValue ?? "All levels"))
    }

    /// Same row as Home: a quiet title on the left, plain 44pt icons on the right.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text("Phrases").font(.subheadline.weight(.medium)).frame(minHeight: 44)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            NavigationLink { ParticleGalleryView() } label: {
                Image(systemName: "circle.hexagongrid").frame(width: 44, height: 44)
            }.accessibilityLabel("Core images").accessibilityIdentifier("coreImages")
            Button { listening = true } label: {
                Image(systemName: "headphones").frame(width: 44, height: 44)
            }.accessibilityLabel("Listen continuously").accessibilityIdentifier("openListening")
        }.foregroundStyle(Palette.ink).padding(.leading, Spacing.xs).padding(.top, Spacing.xs)
    }

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.secondary)
            TextField("Phrase or meaning", text: $query)
                .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.search)
                .accessibilityAddTraits(.isSearchField).accessibilityIdentifier("librarySearch")
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.secondary) }
                    .accessibilityLabel("Clear search")
            }
        }.padding(.horizontal, Spacing.md).frame(minHeight: 44)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var sortMenu: some View {
        Menu {
            ForEach(PhraseSort.allCases, id: \.self) { sort in
                Button { store.configure(sort: sort) } label: {
                    if store.data.sortOrder == sort { Label(sort.title, systemImage: "checkmark") } else { Text(sort.title) }
                }
            }
        } label: {
            MenuControlLabel(title: LocalizedStringKey(store.data.sortOrder.title), systemImage: "arrow.up.arrow.down")
        }.accessibilityLabel("Sort phrases").accessibilityValue(store.data.sortOrder.title)
    }

    private var libraryProPrompt: some View {
        // No container identifier: it would override the identifiers of the card's own button and text.
        ProLockView().padding(.vertical, Spacing.lg)
    }
}

struct VerbGroupView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    let verb: String
    var difficulty: PhraseDifficulty? = nil
    /// Opened from the Saved collection: the family shows only the saved phrases its card counted.
    var savedOnly = false
    var body: some View {
        let phrases = store.data.sortOrder.ordered(store.phrases.filter {
            !$0.isIdiom && $0.baseVerb == verb && purchases.allows($0) && (difficulty == nil || $0.difficulty == difficulty)
                && (!savedOnly || store.data.saved.contains($0.id))
        }, reviews: store.data.reviews)
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
    let phrase: Phrase
    var body: some View {
        if purchases.allows(phrase) { PhraseContentView(phrase: phrase) }
        else { PaperPage { ProLockView() } }
    }
}

private struct PhraseContentView: View {
    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    let phrase: Phrase
    @State private var voice = VoicePractice()
    @State private var session: PracticeSelection?
    @State private var note = ""
    @State private var now = Date.now
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // The scene label is intentionally not shown here; Conversation focus and practice queues still use it.
                Text(phrase.phrase).font(Typography.phrase)
                PhraseDifficultyButton(phrase: phrase)
                PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage)
                PhraseConnections(phrase: phrase)
                if let aliases = phrase.aliases, !aliases.isEmpty {
                    Text(aliases.joined(separator: " · ")).font(.subheadline).foregroundStyle(Palette.secondary)
                }
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(phrase.examples.count > 1 ? "Examples" : "Example").font(Typography.section)
                    PhraseExamples(phrase: phrase, voice: voice)
                }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
                // The meaning is on screen here, so a rating counts like one given after opening the answer on Home.
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true,
                                     selected: store.memoryRating(for: phrase.id, on: now)) { rating in
                    // Recorded at the time the buttons previewed, so the saved interval is the one that was shown.
                    store.rateMemory(phrase, rating, now: now)
                    now = .now
                }.accessibilityIdentifier("detailRating")
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
                            ExampleSentenceView(text: usage.example, phrase: phrase, voice: voice, identifier: "referenceExample")
                        }.padding(.vertical, Spacing.sm)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your sentence").font(.headline)
                    TextField("Add an example…", text: $note, axis: .vertical).lineLimit(3...6).padding(Spacing.md).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)).accessibilityIdentifier("personalNote")
                    }
                PrimaryButton(title: "Practice speaking") { voice.stopPlayback(); session = .init(phrases: [phrase]) }.accessibilityIdentifier("practicePhrase")
                if let url = URL(string: phrase.source), url.scheme == "https" { Link("Dictionary", destination: url).font(.subheadline).frame(minHeight: 44) }
                if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
            }
        }.navigationTitle("Phrase notes").navigationBarTitleDisplayMode(.inline)
            .toolbar { SavePhraseButton(phraseID: phrase.id) }
            .onAppear { note = store.data.notes[phrase.id] ?? ""; now = .now }
            .onChange(of: note) { _, newValue in store.note(newValue, for: phrase.id) }
            .onChange(of: scenePhase) { _, value in if value == .active { now = .now } else { voice.stopPlayback() } }
            // The rating row's intervals and today's highlight follow the clock, as on Home.
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in now = .now }
            .onDisappear { voice.clear() }
            .fullScreenCover(item: $session) { SpeakingSessionView(phrases: $0.phrases, primedIDs: [phrase.id]) }
            .closesForReviewRequest($session)
    }
}

/// Parallel links for the verb family and particle images, shared by Today and phrase details.
struct PhraseConnections: View {
    let phrase: Phrase
    var body: some View {
        if phrase.isIdiom {
            Text("Idiom").font(.subheadline).foregroundStyle(Palette.secondary)
                .accessibilityIdentifier("phraseKind-idiom")
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { links }
                VStack(spacing: Spacing.xs) { links }
            }.font(.subheadline).buttonStyle(.plain).foregroundStyle(Palette.ink)
        }
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
    @Bindable var voice: VoicePractice
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(phrase.examples.enumerated()), id: \.offset) { index, example in
                ExampleSentenceView(text: example, phrase: phrase, voice: voice,
                                    identifier: index == 0 ? "featuredExample" : "featuredExample-\(index)")
                    .id(example)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
