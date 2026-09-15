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
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @Namespace private var collectionPill
    @Namespace private var phraseZoom
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
        // The count describes the whole collection, Pro phrases included; the rows show what the plan opens.
        let collectionResults = purchases.hasFullAccess ? results
            : LibraryResults(phrases: store.phrases, collection: collection, query: query, sort: store.data.sortOrder,
                             reviews: store.data.reviews, saved: store.data.saved, difficulty: difficulty, groupByVerb: grouped)
        let shownCount = grouped ? collectionResults.groups.count : collectionResults.phrases.count
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
                                // Same as Home's mode switch: one weight, one sliding pill, 44 pt to touch.
                                Text(LocalizedStringKey(item.rawValue))
                                    .font(.footnote.weight(.medium))
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .padding(.horizontal, Spacing.xs)
                                    .foregroundStyle(collection == item ? accent.color : Palette.ink)
                                    .background {
                                        if collection == item {
                                            Capsule().fill(accent.soft).matchedGeometryEffect(id: "collectionPill", in: collectionPill)
                                        }
                                    }
                                    .hitArea(vertical: 6)
                            }.buttonStyle(PressStyle())
                                .accessibilityAddTraits(collection == item ? .isSelected : [])
                        }
                    }.padding(Spacing.xxs)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 100))
                        // Only the pill slides; the list below swaps at once.
                        .animation(reduceMotion ? Motion.reducedFade : Motion.snappy, value: collection)
                        .accessibilityIdentifier("libraryCollection")
                }
                (typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
                    : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.md))) {
                    resultCount(grouped: grouped, count: shownCount)
                        .contentTransition(.numericText(value: Double(shownCount)))
                        .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    filterMenu
                    sortMenu
                }
                if results.isEmpty {
                    emptyState
                    if !purchases.hasFullAccess { libraryProPrompt }
                } else if grouped {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(Array(results.groups.enumerated()), id: \.element.id) { index, group in
                            NavigationLink { VerbGroupView(verb: group.verb, difficulty: difficulty, savedOnly: collection == .saved) } label: {
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Text(group.verb).font(Typography.family).foregroundStyle(Palette.ink)
                                    Spacer(minLength: Spacing.sm)
                                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                                        Text("\(group.phrases.count) phrases").font(.subheadline.weight(.medium).monospacedDigit())
                                        Text(group.phrases.prefix(3).map(\.phrase).joined(separator: " · ")).font(.caption).foregroundStyle(Palette.secondary).multilineTextAlignment(.trailing)
                                    }
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary).padding(.top, Spacing.xs)
                                }.padding(Spacing.lg).foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("verbGroup-\(group.verb)")
                        }
                        if !purchases.hasFullAccess { libraryProPrompt }
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.phrases.enumerated()), id: \.element.id) { index, phrase in
                            NavigationLink { PhraseDetailView(phrase: phrase, siblings: results.phrases).zoomDestination(id: phrase.id, in: phraseZoom) } label: {
                                PhraseRow(phrase: phrase).zoomSource(id: phrase.id, in: phraseZoom)
                            }.buttonStyle(RowPressStyle()).accessibilityIdentifier("phraseRow-\(phrase.id)")
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

    /// The title sits centered as a navigation bar would place it, with Home's plain ink glyphs beside it:
    /// the system bar draws its own capsules around toolbar items, which look nothing like Home.
    private var header: some View {
        ZStack {
            Text("Phrases").font(.subheadline.weight(.medium)).frame(minHeight: 44)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                Spacer()
                NavigationLink { ParticleGalleryView() } label: {
                    Image(systemName: "circle.hexagongrid").frame(width: 44, height: 44)
                }.buttonStyle(PressStyle()).accessibilityLabel("Core images").accessibilityIdentifier("coreImages")
                Button { listening = true } label: {
                    Image(systemName: "headphones").frame(width: 44, height: 44)
                }.buttonStyle(PressStyle()).accessibilityLabel("Listen continuously").accessibilityIdentifier("openListening")
            }
        }.foregroundStyle(Palette.ink).padding(.top, Spacing.xs)
    }

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.secondary)
            TextField("Phrase or meaning", text: $query)
                .textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.search)
                .accessibilityAddTraits(.isSearchField).accessibilityIdentifier("librarySearch")
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.secondary).frame(width: 44, height: 44)
                }.buttonStyle(PressStyle()).accessibilityLabel("Clear search")
                    .padding(.trailing, -Spacing.sm) // the 44 pt target reaches into the field's padding, the glyph stays put
            }
        }.padding(.horizontal, Spacing.md).frame(minHeight: 44)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
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

    /// Literal keys per branch, so each count gets its own plural form ("1 idiom", "%lld件").
    private func resultCount(grouped: Bool, count: Int) -> Text {
        if grouped { return Text("\(count) verbs") }
        if collection == .idioms { return Text("\(count) idioms") }
        return Text("\(count) phrases")
    }

    /// Says why the list is empty and offers the next step, instead of a bare "nothing here".
    @ViewBuilder private var emptyState: some View {
        if collection == .saved && query.isEmpty {
            ContentUnavailableView {
                Label("No saved phrases", systemImage: "bookmark")
            } description: {
                Text("Tap the bookmark on any phrase to keep it here.")
            } actions: {
                Button("Browse all phrases") { collection = .all }
                    .font(Typography.control).buttonStyle(PressStyle()).frame(minHeight: 44)
            }
        } else {
            ContentUnavailableView {
                Label("No matching phrases", systemImage: "magnifyingglass")
            } description: {
                Text("Try another word, or choose a different level.")
            } actions: {
                if !query.isEmpty {
                    Button("Clear search") { query = "" }
                        .font(Typography.control).buttonStyle(PressStyle()).frame(minHeight: 44)
                }
            }
        }
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
                Text("\(phrases.count) phrases").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                LazyVStack(spacing: 0) {
                    ForEach(phrases) { phrase in
                        NavigationLink { PhraseDetailView(phrase: phrase, siblings: phrases) } label: { PhraseRow(phrase: phrase) }.buttonStyle(RowPressStyle()).accessibilityIdentifier("phraseRow-\(phrase.id)")
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
    @Environment(\.dynamicTypeSize) private var typeSize
    let phrase: Phrase
    /// The list this phrase was opened from: swiping left and right moves through it in the same order.
    var siblings: [Phrase] = []
    @State private var shown: String?

    var body: some View {
        let pages = siblings.filter { purchases.allows($0) }
        if purchases.allows(phrase), pages.count > 1, pages.contains(where: { $0.id == phrase.id }) {
            let current = shown ?? phrase.id
            TabView(selection: Binding(get: { current }, set: { shown = $0 })) {
                // Only the pager carries the title and Save button; per-page toolbars would stack up.
                ForEach(pages) { page in PhraseContentView(phrase: page, paged: true).tag(page.id) }
            }.tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityIdentifier("phraseNotesPages")
                .navigationTitle("Phrase notes").navigationBarTitleDisplayMode(.inline)
                // Home and the Phrases list hide their own bar; say plainly that this screen wants one.
                .toolbar(.visible, for: .navigationBar)
                .toolbar { SavePhraseButton(phraseID: current) }
        } else if purchases.allows(phrase) {
            PhraseContentView(phrase: phrase)
        } else {
            PaperPage { ProLockView() }
        }
    }
}

private struct PhraseContentView: View {
    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.openURL) private var openURL
    let phrase: Phrase
    /// Inside the swipe pager the title and Save button belong to the pager, not to each page.
    var paged = false
    @State private var voice = VoicePractice()
    @State private var session: PracticeSelection?
    @State private var note = ""
    @State private var now = Date.now

    /// Top to bottom: what the phrase is, what it means, recall, how to use it, where it leads, then your own practice.
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // The scene label is intentionally not shown here; Conversation focus and practice queues still use it.
                header
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage)
                    // The verb and its particle sit with the phrase itself, not at the far end of the page.
                    PhraseConnections(phrase: phrase)
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(phrase.examples.count > 1 ? "Examples" : "Example").font(Typography.section)
                        PhraseExamples(phrase: phrase, voice: voice)
                    }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
                }
                // Right after the meaning and examples, so checking and rating stay together.
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true,
                                     selected: store.memoryRating(for: phrase.id, on: now)) { rating in
                    // Recorded at the time the buttons previewed, so the saved interval is the one that was shown.
                    store.rateMemory(phrase, rating, now: now)
                    now = .now
                }.accessibilityIdentifier("detailRating")
                usage
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your sentence").font(Typography.section).accessibilityAddTraits(.isHeader)
                    TextField("Add an example…", text: $note, axis: .vertical).lineLimit(3...6).padding(Spacing.md).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium)).accessibilityIdentifier("personalNote")
                    PrimaryButton(title: String(localized: "Practice")) { voice.stopPlayback(); session = .init(phrases: [phrase]) }.accessibilityIdentifier("practicePhrase")
                }
                if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
            }
        }.modifier(PageChrome(paged: paged, phraseID: phrase.id))
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

    /// The phrase, then one quiet line of facts about it: kind and level together, and any other forms.
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(phrase.phrase).font(Typography.phrase)
            (typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.xs))) {
                // A tag for the kind, so it doesn't run into the level's own "B1 · 中級" separator.
                Text(phrase.isIdiom ? "Idiom" : "Phrasal verb")
                    .font(.caption.weight(.medium)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, Spacing.xs).padding(.vertical, Spacing.xxs)
                    .background(Palette.surface, in: Capsule())
                    .frame(minHeight: 44)
                    .accessibilityIdentifier(phrase.isIdiom ? "phraseKind-idiom" : "phraseKind-phrasalVerb")
                if phrase.difficulty != nil { PhraseDifficultyButton(phrase: phrase) }
            }
            if let aliases = phrase.aliases, !aliases.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text("Also").foregroundStyle(Palette.secondary)
                    Text(aliases.joined(separator: " · "))
                }.font(.subheadline).accessibilityElement(children: .combine)
            }
        }
    }

    private var hasUsage: Bool {
        !phrase.frame.isEmpty || !phrase.nuance.isEmpty || !phrase.contrast.isEmpty || phrase.referenceUsage != nil || dictionaryURL != nil
    }
    private var dictionaryURL: URL? {
        guard let url = URL(string: phrase.source), url.scheme == "https" else { return nil }
        return url
    }

    /// Each note says what it is: the pattern to reuse, a usage tip, how it differs from a look-alike,
    /// its other meanings, and the dictionary entry it came from.
    /// The section is always there, so every phrase's page has the same shape; without notes it says so.
    private var usage: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Usage").font(Typography.section).accessibilityAddTraits(.isHeader)
                if !hasUsage {
                    Text("No usage notes for this phrase yet.").font(.subheadline).foregroundStyle(Palette.secondary)
                }
                // The phrase is highlighted inside its pattern, as in the examples.
                if !phrase.frame.isEmpty { usageNote("Pattern") { PhraseExampleText(text: phrase.pattern, phrase: phrase, font: .title3) } }
                if !phrase.nuance.isEmpty { usageNote("Tip") { Text(phrase.nuance(in: store.data.meaningLanguage)).font(.body) } }
                if !phrase.contrast.isEmpty { usageNote("Compare") { Text(phrase.contrast(in: store.data.meaningLanguage)).font(.body) } }
                if let usage = phrase.referenceUsage {
                    DisclosureGroup("Other meanings") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text(usage.explanation(in: store.data.meaningLanguage)).font(.body)
                            ExampleSentenceView(text: usage.example, phrase: phrase, voice: voice, identifier: "referenceExample")
                        }.padding(.vertical, Spacing.sm)
                    }
                }
                if let url = dictionaryURL { dictionaryLink(url) }
        }
    }

    private func usageNote<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title).font(Typography.metadata).foregroundStyle(Palette.secondary)
            content().fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
    }

    /// Leaves the app, so it reads as a link out: the source's name and the outward arrow.
    private func dictionaryLink(_ url: URL) -> some View {
        Button { openURL(url) } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "character.book.closed").foregroundStyle(Palette.secondary).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Look up in a dictionary").font(.body)
                    Text(verbatim: Self.sourceName(for: url)).font(.caption).foregroundStyle(Palette.secondary)
                }
                Spacer(minLength: Spacing.sm)
                Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
                    .accessibilityHidden(true)
            }.padding(.leading, Spacing.md).padding(.trailing, Spacing.md - 2).padding(.vertical, Spacing.sm).frame(minHeight: 44)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
                .contentShape(RoundedRectangle(cornerRadius: Radius.medium))
        }.buttonStyle(PressStyle()).foregroundStyle(Palette.ink)
            .accessibilityAddTraits(.isLink)
            .accessibilityHint("Opens in Safari")
            .accessibilityIdentifier("dictionaryLink")
    }

    static func sourceName(for url: URL) -> String {
        switch url.host()?.replacingOccurrences(of: "www.", with: "") {
        case "dictionary.cambridge.org": "Cambridge Dictionary"
        case "oxfordlearnersdictionaries.com": "Oxford Learner's Dictionaries"
        case "merriam-webster.com": "Merriam-Webster"
        case "collinsdictionary.com": "Collins Dictionary"
        case "dictionary.com": "Dictionary.com"
        case "idioms.thefreedictionary.com": "The Free Dictionary"
        case let host?: host
        case nil: url.absoluteString
        }
    }
}

/// A single page owns the title and Save button; inside the swipe pager they belong to the pager,
/// so the pages must not set them at all (an empty title would win over the pager's).
private struct PageChrome: ViewModifier {
    let paged: Bool
    let phraseID: String
    func body(content: Content) -> some View {
        if paged {
            content
        } else {
            content.navigationTitle("Phrase notes").navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
                .toolbar { SavePhraseButton(phraseID: phraseID) }
        }
    }
}

/// The phrase taken apart: its verb (with how many phrases share it) and each particle (with its core-image
/// sketch and meaning). Each card says where it leads, unlike bare word chips. Idioms have neither.
struct PhraseConnections: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dynamicTypeSize) private var typeSize
    let phrase: Phrase

    var body: some View {
        if !phrase.isIdiom {
            let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
                NavigationLink { VerbGroupView(verb: phrase.baseVerb) } label: {
                    card(caption: "Verb family", title: phrase.baseVerb,
                         detail: Text("\(familyCount) phrases")) {
                        Image(systemName: "square.stack").font(.title2).foregroundStyle(Palette.secondary)
                            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    }
                }.buttonStyle(PressStyle())
                    .accessibilityLabel("Verb family: \(phrase.baseVerb), \(familyCount) phrases")
                    .accessibilityIdentifier("phraseVerb-\(phrase.baseVerb)")
                ForEach(phrase.particleConcepts) { concept in
                    NavigationLink { ParticleImageDetailView(concept: concept) } label: {
                        card(caption: "Core image", title: concept.id,
                             detail: Text(verbatim: concept.title(in: store.data.meaningLanguage))) {
                            // The sketch fills the card's width, so its route and marker stay legible.
                            ParticleDiagram(concept: concept).frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56)
                        }
                    }.buttonStyle(PressStyle())
                        .accessibilityLabel("Core image: \(concept.id), \(concept.title(in: store.data.meaningLanguage))")
                        .accessibilityIdentifier("phraseImage-\(concept.id)")
                }
            }
        }
    }

    private var familyCount: Int {
        store.phrases.filter { !$0.isIdiom && $0.baseVerb == phrase.baseVerb && purchases.allows($0) }.count
    }

    private func card<Visual: View>(caption: LocalizedStringKey, title: String, detail: Text, @ViewBuilder visual: () -> Visual) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            visual()
            Text(caption).font(Typography.metadata).foregroundStyle(Palette.secondary).padding(.top, Spacing.xxs)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(verbatim: title).font(Typography.phraseRow).foregroundStyle(Palette.ink)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
            }
            detail.font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }.padding(Spacing.md).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
            .contentShape(RoundedRectangle(cornerRadius: Radius.medium))
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
