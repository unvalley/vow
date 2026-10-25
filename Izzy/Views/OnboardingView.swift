import SwiftUI

/// Lightweight, local-only introduction shown once on a fresh install.
/// Finishing hands over to the daily goal sheet, so the pace stays the learner's explicit choice.
/// Copy follows the saved meaning language, which a fresh install takes from the device language,
/// so the introduction and the purchase screen it opens never disagree. The first two pages are stills
/// of Home built from its own parts and a free phrase from the catalog, so they always match the app.
/// The third is an optional level check that sets the levels Home learns from and leads into Pro with
/// the learner's own levels; the fourth is Pro.
struct OnboardingView: View {
    private static let pages = 4, checkPage = 2, proPage = 3
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var page = 0
    @State private var purchase = false
    @State private var check = LevelCheckView.Stage.invitation
    /// Shown as it will appear on Home, and free, so the learner meets it again without Pro.
    private var sample: Phrase? {
        store.phrases.first { $0.id == "07-catch-up" } ?? store.phrases.first { AccessPolicy.freePhraseIDs.contains($0.id) }
    }
    private var facts: CatalogFacts { CatalogFacts(phrases: store.phrases) }
    /// The catalog as an open-ended claim (3,000以上), so the copy stays true as expressions are added.
    private var catalogClaim: String {
        let claim = CatalogFacts.openEnded(facts.expressions).formatted()
        return japanese ? "\(claim)以上の表現" : "\(claim)+ expressions"
    }
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    /// The levels the check recommends, once it has.
    private var recommended: Set<PhraseDifficulty>? {
        if case .result(let levels, _, _) = check, !levels.isEmpty { return levels }
        return nil
    }
    private func names(_ levels: Set<PhraseDifficulty>) -> String {
        levels.sorted().map(\.rawValue).joined(separator: japanese ? "・" : " · ")
    }
    /// Expressions at these levels for the kind Home learns, and how many of them the free plan opens.
    private func counts(_ levels: Set<PhraseDifficulty>) -> (all: Int, free: Int) {
        let at = store.phrases.filter { store.data.homeKindFilter.allows($0) && $0.difficulty.map(levels.contains) == true }
        return (at.count, at.filter { AccessPolicy.allows($0, purchased: false) }.count)
    }
    /// A restored or existing purchase turns the last page into a confirmation instead of an invitation.
    private var purchased: Bool { purchases.isPurchased }
    private var title: String {
        switch page {
        // Each title fits one line at the default text size on a 375pt-wide iPhone.
        case 0: return japanese ? "使える英語を、毎日。" : "Learn real English."
        case 1: return japanese ? "復習で、身につく。" : "Remember for good."
        case Self.checkPage:
            if let recommended { return japanese ? "おすすめは\(names(recommended))。" : "Start with \(names(recommended))." }
            if check == .asking { return japanese ? "この意味は？" : "What does it mean?" }
            return japanese ? "レベルを確かめる。" : "Find your level."
        default:
            if purchased { return japanese ? "Izzy Proが有効です。" : "Izzy Pro is ready." }
            return japanese ? "もっと学ぶなら、Pro。" : "More with Izzy Pro."
        }
    }
    private var description: String {
        switch page {
        case 0: return japanese ? "句動詞やイディオムを、意味と例文から。音声を聞いて、会話で使うイメージをつかみましょう。" : "Explore phrasal verbs and idioms through meanings, examples and audio. Discover how they fit into everyday conversation."
        case 1: return japanese ? "毎日の小さな学習と、忘れる前の復習。覚え具合に合わせて、次に復習する日が決まります。1日に学ぶ数は自分で決められます。" : "Learn a little each day and revisit what you've learned. Your next review adapts to how well you remember. You choose how many new expressions to learn each day."
        case Self.checkPage:
            if let recommended {
                let count = counts(recommended)
                if purchased {
                    return japanese ? "\(names(recommended))の\(count.all.formatted())表現を、Homeで学んでいきます。"
                        : "Home will work through the \(count.all.formatted()) expressions at \(names(recommended))."
                }
                return japanese ? "\(names(recommended))の表現は\(count.all.formatted())個。無料で\(count.free)個、Izzy Proならすべて学べます。"
                    : "\(names(recommended)) holds \(count.all.formatted()) expressions: \(count.free) free, and every one with Izzy Pro."
            }
            if check == .asking {
                return japanese ? "知らなければ「わからない」を。当て推量より、結果が正確になります。"
                    : "If you don't know, choose “Not sure”: the result is truer than with a guess."
            }
            let questions = LevelCheck.levels.count * 2
            return japanese ? "\(questions)問、1分ほど。答えに合わせて、Homeで学ぶレベルを選びます。"
                : "\(questions) questions, about a minute. Your answers choose the levels Home teaches."
        default:
            // The card below lists the Pro facts; this line adds only what the card does not say.
            if purchased { return japanese ? "購入済みの内容を、この端末でそのまま使えます。" : "Your purchase is active on this device." }
            if let recommended {
                let count = counts(recommended)
                return japanese ? "Izzy Proなら、\(names(recommended))の\(count.all.formatted())表現をすべて。無料でも\(count.free)表現から始められます。"
                    : "Izzy Pro opens all \(count.all.formatted()) expressions at \(names(recommended)). You can start with \(count.free) for free."
            }
            let facts = facts
            return japanese ? "無料でも句動詞\(facts.freePhrasalVerbs)個とイディオム\(facts.freeIdioms)個から始められます。"
                : "Start free with \(facts.freePhrasalVerbs) phrasal verbs and \(facts.freeIdioms) idioms."
        }
    }
    private var continueTitle: String {
        if page < Self.proPage { return japanese ? "次へ" : "Continue" }
        return japanese ? "はじめる" : "Get started"
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // One line: short copy fits as is; larger text shrinks slightly, accessibility sizes wrap.
                    // Each page is seen once, so its title, text and illustration enter in steps.
                    Text(title).font(Typography.phrase)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader).accessibilityIdentifier("onboardingTitle")
                        .staggeredEntrance(0)
                    Text(description).font(Typography.meaning).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .staggeredEntrance(1)
                    illustration
                        .frame(maxWidth: .infinity, minHeight: 260)
                        .staggeredEntrance(2)
                    if page == Self.proPage && !purchased {
                        SecondaryButton(title: purchases.canStartTrial
                                            ? (japanese ? "\(AccessPolicy.trialDays)日間、無料でProを試す" : "Try Pro free for \(AccessPolicy.trialDays) days")
                                            : (japanese ? "Proの詳細を見る" : "Explore Pro"),
                                        identifier: "onboardingPro") { purchase = true }
                            .staggeredEntrance(3)
                    }
                    Spacer(minLength: 0)
                }.id(page)
                .padding(Spacing.lg)
                .frame(maxWidth: 520)
                .frame(minHeight: max(0, geometry.size.height), alignment: .top)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<Self.pages, id: \.self) { index in
                        Capsule().fill(index == page ? accent.mark : Palette.secondary.opacity(0.25))
                            .frame(width: index == page ? 24 : 6, height: 6)
                            .animation(reduceMotion ? nil : Motion.snappy, value: page)
                    }
                }.accessibilityElement(children: .ignore)
                    .accessibilityLabel(japanese ? "全\(Self.pages)ページ中\(page + 1)ページ" : "Page \(page + 1) of \(Self.pages)")
                continueControl
            }.padding(Spacing.lg).frame(maxWidth: 520).frame(maxWidth: .infinity)
                .background(Palette.paper)
        }
        .background(Palette.paper).foregroundStyle(Palette.ink)
        .sheet(isPresented: $purchase) { PurchaseView(from: "onboarding") }
    }

    /// The page's way forward. Before the check has a result it is optional, so moving on is a plain Skip
    /// rather than the screen's main action; with a result, the main action takes its levels.
    @ViewBuilder private var continueControl: some View {
        if page == Self.checkPage, let recommended {
            VStack(spacing: Spacing.xxs) {
                PrimaryButton(title: japanese ? "このレベルで始める" : "Learn at these levels") {
                    finishCheck(PhraseLevelFilter(levels: recommended), step: "finished")
                }.accessibilityIdentifier("onboardingContinue")
                Button(japanese ? "すべてのレベルで学ぶ" : "Learn from every level") { finishCheck(.all, step: "allLevels") }
                    .font(Typography.control).frame(minHeight: 44).buttonStyle(PressStyle())
                    .accessibilityIdentifier("levelCheckAllLevels")
            }
        } else if page == Self.checkPage {
            Button(japanese ? "スキップ" : "Skip") { finishCheck(nil, step: check == .asking ? "abandoned" : "skipped") }
                .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44).buttonStyle(PressStyle())
                .accessibilityIdentifier("onboardingContinue")
        } else {
            PrimaryButton(title: continueTitle) {
                if page < Self.proPage {
                    page += 1 // the new page's staggered entrance is the motion; the dots animate on their own
                } else {
                    store.finishOnboarding()
                }
            }.accessibilityIdentifier("onboardingContinue")
        }
    }

    private func finishCheck(_ levels: PhraseLevelFilter?, step: String) {
        if let levels { store.configure(homeLevels: levels) }
        Analytics.shared.record(.levelCheck, ["step": step, "levels": levels.map { $0.isAll ? "all" : $0.ordered.map(\.rawValue).joined(separator: ",") } ?? "unchanged"])
        page += 1
    }

    @ViewBuilder private var illustration: some View {
        if page < Self.checkPage, let sample {
            homePreview(sample)
        } else if page == Self.checkPage {
            LevelCheckView(stage: $check)
        } else {
            proCard
        }
    }

    /// Home as the learner will see it: the phrase over their background, then either the meaning
    /// and example that the info button raises, or the review answers with their next intervals.
    private func homePreview(_ phrase: Phrase) -> some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Text(phrase.phrase).phraseFont(.largeTitle).lineLimit(1).minimumScaleFactor(0.6)
                if let difficulty = phrase.difficulty { PhraseDifficultyLabel(difficulty: difficulty) }
                HStack(spacing: Spacing.xl) {
                    Image(systemName: "speaker.wave.2")
                    // The button that raises the sheet below carries the accent on the first page.
                    Image(systemName: "info.circle").foregroundStyle(page == 0 ? accent.mark : Palette.ink)
                    Image(systemName: "bookmark")
                }.font(.title3).padding(.top, Spacing.xs).accessibilityHidden(true)
            }.padding(.top, Spacing.xl).padding(.horizontal, Spacing.lg)
            Spacer(minLength: Spacing.lg)
            if page == 0 {
                answerPeek(phrase)
            } else {
                MemoryRatingControls(state: sampleReview, now: .now, compact: true,
                                     title: "Review: did you remember the meaning?") { _ in }
                    .padding([.horizontal, .bottom], Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .background { TodayLandscapeBackground(background: store.data.background(fullAccess: purchased)) }
        .clipShape(RoundedRectangle(cornerRadius: Radius.large))
        .overlay { RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.secondary.opacity(0.15)) }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboardingIllustration")
        .allowsHitTesting(false)
    }

    /// The top of the answer sheet: the same meaning and example views the sheet itself uses.
    private func answerPeek(_ phrase: Phrase) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Capsule().fill(Palette.secondary.opacity(0.3)).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity).accessibilityHidden(true)
            PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage)
            if let example = phrase.examples.first {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    PhraseExampleText(text: "“\(example)”", phrase: phrase).fixedSize(horizontal: false, vertical: true)
                    if japanese, let translation = phrase.exampleTranslations?[example] {
                        Text(translation).font(.subheadline).foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg).padding(.top, Spacing.sm).padding(.bottom, Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.paper, in: UnevenRoundedRectangle(topLeadingRadius: Radius.large, topTrailingRadius: Radius.large))
        .shadow(color: .black.opacity(0.06), radius: 12, y: -2)
    }

    /// A phrase remembered twice and due today, so each answer previews a different real interval
    /// (after a single review, Good and Easy both land on the same day).
    private var sampleReview: MemoryReview {
        let day: TimeInterval = 86_400
        let first = MemoryScheduler.review(nil, rating: .good, now: .now.addingTimeInterval(-8 * day))
        return MemoryScheduler.review(first, rating: .good, now: .now.addingTimeInterval(-7 * day))
    }

    private var proCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Izzy Pro").font(Typography.phraseRow)
                Spacer()
                Image(systemName: "rectangle.stack").font(.title2).foregroundStyle(Palette.secondary)
            }
            Divider()
            Label(catalogClaim, systemImage: "text.book.closed")
            Label(japanese ? "すべての表現を復習" : "Reviews for every expression", systemImage: "calendar")
            Label(japanese ? "買い切り・自動更新なし" : "One purchase. Yours to keep.", systemImage: "checkmark.circle")
            if purchases.canStartTrial {
                Label(japanese ? "\(AccessPolicy.trialDays)日間、無料で試せます" : "Free to try for \(AccessPolicy.trialDays) days", systemImage: "hourglass")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboardingIllustration")
    }
}
