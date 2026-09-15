import SwiftUI

/// Lightweight, local-only introduction shown once on a fresh install.
/// Finishing hands over to the daily goal sheet, so the pace stays the learner's explicit choice.
/// Copy follows the saved meaning language, which a fresh install takes from the device language,
/// so the introduction and the purchase screen it opens never disagree. Illustrations reuse app tokens.
struct OnboardingView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var page = 0
    @State private var purchase = false
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    /// A restored or existing purchase turns the last page into a confirmation instead of an invitation.
    private var purchased: Bool { purchases.hasFullAccess }
    private var title: String {
        switch page {
        // Each title fits one line at the default text size on a 375pt-wide iPhone.
        case 0: return japanese ? "使える英語を、毎日。" : "Learn real English."
        case 1: return japanese ? "復習で、身につく。" : "Remember for good."
        default:
            if purchased { return japanese ? "Vow Proが有効です。" : "Vow Pro is ready." }
            return japanese ? "もっと学ぶなら、Pro。" : "More with Vow Pro."
        }
    }
    private var description: String {
        let count = store.phrases.count.formatted()  // Matches the grouped number on the card below.
        switch page {
        case 0: return japanese ? "句動詞やイディオムを、意味と例文から。音声を聞いて、会話で使うイメージをつかみましょう。" : "Explore phrasal verbs and idioms through meanings, examples and audio. Discover how they fit into everyday conversation."
        case 1: return japanese ? "毎日の小さな学習と、忘れる前の復習。覚え具合に合わせて、次に復習する日が決まります。1日に学ぶ数は自分で決められます。" : "Learn a little each day and revisit what you've learned. Your next review adapts to how well you remember. You choose how many new expressions to learn each day."
        default:
            // The card below lists the Pro facts; this line adds only what the card does not say.
            if purchased { return japanese ? "購入済みの内容を、この端末でそのまま使えます。" : "Your purchase is active on this device." }
            return japanese ? "無料でも句動詞50個とイディオム50個から始められます。" : "Start free with 50 phrasal verbs and 50 idioms."
        }
    }
    private var continueTitle: String {
        if page < 2 { return japanese ? "続ける" : "Continue" }
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
                        .padding(.vertical, Spacing.lg)
                        .staggeredEntrance(2)
                    if page == 2 && !purchased {
                        Button(japanese ? "Proの詳細を見る" : "Explore Pro") { purchase = true }
                            .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44)
                            .buttonStyle(PressStyle())
                            .accessibilityIdentifier("onboardingPro")
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
                    ForEach(0..<3) { index in
                        Capsule().fill(index == page ? accent.color : Palette.secondary.opacity(0.25))
                            .frame(width: index == page ? 24 : 6, height: 6)
                            .animation(reduceMotion ? nil : Motion.snappy, value: page)
                    }
                }.accessibilityElement(children: .ignore)
                    .accessibilityLabel(japanese ? "全3ページ中\(page + 1)ページ" : "Page \(page + 1) of 3")
                PrimaryButton(title: continueTitle) {
                    if page < 2 {
                        page += 1 // the new page's staggered entrance is the motion; the dots animate on their own
                    } else {
                        store.finishOnboarding()
                    }
                }.accessibilityIdentifier("onboardingContinue")
            }.padding(Spacing.lg).frame(maxWidth: 520).frame(maxWidth: .infinity)
                .background(Palette.paper)
        }
        .background(Palette.paper).foregroundStyle(Palette.ink)
        .sheet(isPresented: $purchase) { PurchaseView() }
    }

    private var illustration: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            switch page {
            case 0:
                HStack {
                    Text("PHRASAL VERB").font(Typography.metadata)
                    Spacer()
                    Image(systemName: "speaker.wave.2")
                }.foregroundStyle(Palette.secondary)
                Text("pick up").phraseFont(.largeTitle)
                Text(japanese ? "自然に身につける" : "Learn something naturally.").font(Typography.meaning)
                Divider()
                Text("“I picked up a few phrases on my trip.”")
                    .font(Typography.example).foregroundStyle(Palette.secondary)
            case 1:
                Label(japanese ? "今日の復習" : "Today's review", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(Typography.context).foregroundStyle(Palette.secondary)
                Text("pick up").phraseFont(.largeTitle)
                Text(japanese ? "意味を思い出せた？" : "Can you recall the meaning?").font(Typography.meaning)
                HStack(spacing: Spacing.sm) {
                    recallLabel(japanese ? "もう一度" : "Again", symbol: "arrow.counterclockwise")
                    recallLabel(japanese ? "覚えた" : "Got it", symbol: "checkmark")
                }
            default:
                HStack {
                    Text("Vow Pro").font(Typography.phraseRow)
                    Spacer()
                    Image(systemName: "rectangle.stack").font(.title2).foregroundStyle(Palette.secondary)
                }
                Divider()
                Label(japanese ? "全\(store.phrases.count)表現" : "All \(store.phrases.count) expressions", systemImage: "text.book.closed")
                Label(japanese ? "すべての表現を復習" : "Reviews for every expression", systemImage: "calendar")
                Label(japanese ? "買い切り・自動更新なし" : "One purchase. Yours to keep.", systemImage: "checkmark.circle")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboardingIllustration")
        .allowsHitTesting(false)
    }

    private func recallLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol).font(Typography.control)
            .padding(Spacing.md).frame(maxWidth: .infinity)
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: Radius.small))
    }
}
