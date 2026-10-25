import SwiftUI

struct ProLockView: View {
    /// Where this card sits, so the funnel can show which one people act on.
    var place = "list"
    /// The Pro expression behind this lock, when there is one; the purchase screen leads with it.
    var phrase: Phrase? = nil
    @Environment(PurchaseStore.self) private var purchases
    @State private var purchase = false
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock").font(.title2).foregroundStyle(Palette.secondary)
                .accessibilityHidden(true)
            if let phrase {
                Text(phrase.phrase).phraseFont(.title2).foregroundStyle(Palette.ink)
            }
            // One line does the explaining and the inviting.
            SecondaryButton(title: purchases.canStartTrial ? String(localized: "Try every phrase free for \(AccessPolicy.trialDays) days")
                                                           : String(localized: "Unlock every phrase with Pro"),
                            identifier: "unlockPro") { purchase = true }
        }.multilineTextAlignment(.center).padding(Spacing.lg)
            .frame(maxWidth: 400).frame(maxWidth: .infinity)
            .sheet(isPresented: $purchase) { PurchaseView(from: place, phrase: phrase) }
            .closesForReviewRequest($purchase)
            .onAppear { Analytics.shared.record(.proLockShown, ["place": place]) }
    }
}

/// iPad presents a sheet as a form, which is shorter than this screen and left the price button
/// below the fold. A page-sized sheet shows the whole screen at once; iPhone is unaffected, and on
/// iOS 17 the sheet keeps the size it had.
private struct PageSizedSheet: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18, *) { content.presentationSizing(.page) } else { content }
    }
}

struct PurchaseView: View {
    /// The screen this was opened from: the step before it in the funnel.
    var from = "unknown"
    /// The Pro expression that was tapped, when there was one: the screen leads with it.
    var phrase: Phrase? = nil

    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    private var facts: CatalogFacts { CatalogFacts(phrases: store.phrases) }
    /// The learner's own free-plan progress and the Pro expressions Home would bring them next.
    private var offer: ProOffer {
        ProOffer(phrases: store.phrases, memory: store.data.memoryReviews ?? [:], kind: store.data.homeKindFilter,
                 levels: store.data.homeLevelFilter, focus: store.data.focus)
    }
    var body: some View {
        let facts = facts
        return NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Izzy Pro").font(Typography.phrase).staggeredEntrance(0)
                    if purchases.isPurchased {
                        Label(japanese ? "購入済み" : "Purchased", systemImage: "checkmark.circle.fill").foregroundStyle(accent.color).accessibilityIdentifier("purchaseUnlocked")
                        Text(japanese ? "句動詞とイディオムをすべて閲覧・復習できます。" : "Browse and review every phrase.")
                    } else {
                        let offer = offer
                        headline(facts).staggeredEntrance(1)
                        if purchases.isTrialing, let ends = purchases.trialEnds {
                            Label(japanese ? "無料体験は\(ends.formatted(date: .abbreviated, time: .shortened))まで" : "Free trial until \(ends.formatted(date: .abbreviated, time: .shortened))",
                                  systemImage: "hourglass")
                                .font(.subheadline.weight(.medium)).foregroundStyle(accent.color)
                                .accessibilityIdentifier("trialStatus")
                        }
                        if offer.freeLearned > 0 || offer.paused > 0 { progress(offer).staggeredEntrance(2) }
                        if phrase == nil, !offer.next.isEmpty { nextUp(offer).staggeredEntrance(2) }
                        comparison(facts).staggeredEntrance(3)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label(japanese ? "買い切り。自動更新はありません" : "One purchase. No subscription.", systemImage: "checkmark.seal")
                            Label(japanese ? "オフラインで使えます" : "Works offline", systemImage: "wifi.slash")
                            Label(japanese ? "学習履歴は端末の中だけ" : "Your history stays on your device", systemImage: "lock")
                        }.font(.subheadline).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(4)
                        Text(japanese
                             ? "無料のままでも、\(facts.freeExpressions)表現の学習・復習、コアイメージ\(facts.coreImages)種、練習、連続リスニング、背景\(facts.freeBackgrounds)種とフォント\(facts.freeFonts)種、保存とメモ各\(AccessPolicy.freeKeepLimit)件は続けて使えます。"
                             : "The free plan keeps its \(facts.freeExpressions) expressions, all \(facts.coreImages) core images, practice, continuous listening, \(facts.freeBackgrounds) backgrounds, \(facts.freeFonts) fonts, and up to \(AccessPolicy.freeKeepLimit) saved phrases and notes.")
                            .font(.caption).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(5)
                    }
                    if let notice = purchases.notice { Text(message(notice)).font(.subheadline).foregroundStyle(Palette.secondary).accessibilityIdentifier("purchaseNotice") }
                    Button(japanese ? "購入を復元" : "Restore purchases") { Task { await purchases.restore() } }
                        .frame(minHeight: 44).buttonStyle(PressStyle()).disabled(purchases.isBusy).accessibilityIdentifier("restorePurchases")
                    HStack(spacing: Spacing.lg) {
                        NavigationLink(japanese ? "プライバシー" : "Privacy") { PrivacyView() }
                        Link(japanese ? "利用規約" : "Terms", destination: AppSupport.termsURL)
                    }.font(.caption).frame(minHeight: 44)
                }
            }.navigationBarTitleDisplayMode(.inline)
                // A sheet inherits its presenter's alignment; Home's save button would center this copy.
                .multilineTextAlignment(.leading)
                // The way forward stays in reach however far the reasons above it scroll.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !purchases.isPurchased { actions(facts) }
                }
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(japanese ? "閉じる" : "Done") { dismiss() } } }
        }.modifier(PageSizedSheet()).task {
            Analytics.shared.record(.proScreenOpened, purchases.canStartTrial ? ["from": from, "offer": "trial"] : ["from": from])
            if purchases.product == nil { await purchases.loadProduct() }
        }
    }

    /// The tapped expression when there is one, then the collection as an open-ended claim.
    @ViewBuilder private func headline(_ facts: CatalogFacts) -> some View {
        let claim = CatalogFacts.openEnded(facts.expressions).formatted()
        if let phrase {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(japanese ? "「\(phrase.phrase)」は、Izzy Proで学べます。" : "Learn “\(phrase.phrase)” with Izzy Pro.")
                    .font(.title2).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("purchasePhrase")
                Text(japanese ? "\(claim)以上の表現を、使える言葉に。" : "Make \(claim)+ expressions yours.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
            }
        } else {
            Text(japanese ? "\(claim)以上の表現を、使える言葉に。" : "Make \(claim)+ expressions yours.")
                .font(.title2).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// How far the free plan has taken this learner, and any reviews that are waiting for Pro.
    private func progress(_ offer: ProOffer) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(japanese ? "学んだ無料の表現" : "Free expressions learned")
                Spacer(minLength: Spacing.sm)
                Text(verbatim: "\(offer.freeLearned.formatted()) / \(offer.freeTotal.formatted())")
                    .monospacedDigit().foregroundStyle(Palette.secondary)
            }.font(.subheadline)
            ProgressView(value: Double(offer.freeLearned), total: Double(max(1, offer.freeTotal))).tint(accent.mark)
            if offer.paused > 0 {
                Text(japanese ? "学習済みのPro表現\(offer.paused.formatted())個の復習は、Proで再開します。"
                     : "Reviews for the \(offer.paused.formatted()) Pro expressions you've learned resume with Pro.")
                    .font(.caption).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
            } else if offer.freeLearned >= offer.freeTotal {
                Text(japanese ? "無料の表現は、すべて学びました。" : "You've learned every free expression.")
                    .font(.caption).foregroundStyle(Palette.secondary)
            }
        }.accessibilityElement(children: .combine).accessibilityIdentifier("purchaseProgress")
    }

    /// The first Pro expressions Home would bring this learner, at their levels, with their meanings.
    private func nextUp(_ offer: ProOffer) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(japanese ? "Proで次に学ぶ表現" : "Next with Pro")
                Spacer(minLength: Spacing.sm)
                if offer.lockedCount > offer.next.count {
                    Text(japanese ? "ほか\((offer.lockedCount - offer.next.count).formatted())個" : "+\((offer.lockedCount - offer.next.count).formatted()) more")
                        .monospacedDigit()
                }
            }.font(Typography.metadata).foregroundStyle(Palette.secondary)
            ForEach(offer.next) { phrase in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text(phrase.phrase).phraseFont(.title3)
                        if let difficulty = phrase.difficulty { PhraseDifficultyLabel(difficulty: difficulty) }
                    }
                    PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, leadOnly: true, color: Palette.secondary)
                }
            }
        }.padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .accessibilityElement(children: .combine).accessibilityIdentifier("purchaseNextUp")
    }

    /// The trial when this Apple Account still has one, with everything App Review asks a trial to say
    /// before it starts; otherwise the purchase. Buying stays one tap away in both.
    private func actions(_ facts: CatalogFacts) -> some View {
        VStack(spacing: Spacing.sm) {
            if purchases.isChecking || purchases.isLoading {
                SwiftUI.ProgressView(japanese ? "購入情報を確認中…" : "Checking purchase information…").font(.caption)
            }
            if purchases.canStartTrial, let product = purchases.product {
                PrimaryButton(title: japanese ? "\(AccessPolicy.trialDays)日間、無料で試す" : "Try it free for \(AccessPolicy.trialDays) days") { Task { await purchases.startTrial() } }
                    .disabled(purchases.isBusy).accessibilityIdentifier("startTrial")
                Text(japanese
                     ? "\(AccessPolicy.trialDays)日間、すべての表現・背景・フォントを使えます。終わると自動で無料プラン（\(facts.freeExpressions)表現）に戻り、料金はかかりません。Proを続けるには\(product.displayPrice)の買い切りで購入します。"
                     : "Every expression, background and font for \(AccessPolicy.trialDays) days. When it ends you're back on the free plan (\(facts.freeExpressions) expressions) and nothing is charged; keeping Pro is a one-time \(product.displayPrice).")
                    .font(.caption).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(japanese ? "\(product.displayPrice)で購入する" : "Buy now for \(product.displayPrice)") { Task { await purchases.purchase() } }
                    .font(Typography.control).frame(minHeight: 44).buttonStyle(PressStyle())
                    .disabled(purchases.isBusy || purchases.isChecking).accessibilityIdentifier("buyComplete")
            } else if let product = purchases.product {
                PrimaryButton(title: japanese ? "\(product.displayPrice)で全表現を解放" : "Unlock everything for \(product.displayPrice)") { Task { await purchases.purchase() } }
                    .disabled(purchases.isBusy || purchases.isChecking).accessibilityIdentifier("buyComplete")
                Text(japanese ? "買い切り・自動更新なし" : "One-time purchase · no subscription")
                    .font(.caption).foregroundStyle(Palette.secondary)
            } else if !purchases.isLoading {
                Button(japanese ? "価格を再読み込み" : "Reload price") { Task { await purchases.loadProduct() } }.frame(minHeight: 44).buttonStyle(PressStyle()).accessibilityIdentifier("reloadPrice")
            }
            if purchases.isBusy { SwiftUI.ProgressView().accessibilityLabel(japanese ? "処理中" : "Processing") }
        }.padding(.horizontal, Spacing.lg).padding(.top, Spacing.md).padding(.bottom, Spacing.sm)
            .frame(maxWidth: 680).frame(maxWidth: .infinity)
            .background(Palette.paper)
            .overlay(alignment: .top) { Divider() }
    }

    /// Free beside Pro, in the learner's own numbers: the difference is the collection, not the features.
    /// Every figure comes from the catalog; the full collection is open-ended so it stays true as it grows.
    private func comparison(_ facts: CatalogFacts) -> some View {
        let all = "\(CatalogFacts.openEnded(facts.expressions).formatted())+"
        let examples = "\(CatalogFacts.openEnded(facts.examples).formatted())+"
        let keep = AccessPolicy.freeKeepLimit
        let rows: [(String, String, String)] = japanese
            ? [("学べる表現", "\(facts.freeExpressions)", all), ("例文と日本語訳", "\(facts.freeExamples)", examples), ("間隔をあけた復習", "\(facts.freeExpressions)表現", "すべて"), ("背景", "\(facts.freeBackgrounds)種", "\(facts.backgrounds)種"), ("フレーズのフォント", "\(facts.freeFonts)種", "\(facts.fonts)種"), ("フレーズの保存とメモ", "各\(keep)件", "無制限")]
            : [("Expressions", "\(facts.freeExpressions)", all), ("Examples with meanings", "\(facts.freeExamples)", examples), ("Spaced reviews", "\(facts.freeExpressions)", "All"), ("Backgrounds", "\(facts.freeBackgrounds)", "\(facts.backgrounds)"), ("Phrase fonts", "\(facts.freeFonts)", "\(facts.fonts)"), ("Saved phrases and notes", "\(keep) each", "Unlimited")]
        return VStack(spacing: 0) {
            HStack {
                Text(verbatim: " ").frame(maxWidth: .infinity, alignment: .leading)
                Text(japanese ? "無料" : "Free").frame(width: 72)
                Text("Izzy Pro").frame(width: 72)
            }.font(Typography.metadata).foregroundStyle(Palette.secondary)
                .padding(.bottom, Spacing.xs)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Divider() }
                HStack {
                    Text(verbatim: row.0).frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: row.1).foregroundStyle(Palette.secondary).frame(width: 72)
                    Text(verbatim: row.2).foregroundStyle(accent.color).fontWeight(.medium).frame(width: 72)
                }.font(.subheadline.monospacedDigit()).padding(.vertical, Spacing.sm)
            }
        }.padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .accessibilityElement(children: .combine)
    }

    private func message(_ notice: PurchaseStore.Notice) -> String {
        switch notice {
        case .unavailable: return japanese ? "価格を取得できませんでした。接続を確認して再読み込みしてください。" : "The price is unavailable. Check your connection and reload."
        case .failed: return japanese ? "手続きを完了できませんでした。時間をおいて再試行してください。" : "The request couldn't be completed. Please try again."
        case .pending: return japanese ? "購入は承認待ちです。承認されると自動で解放されます。" : "Your purchase is awaiting approval. Access unlocks when approved."
        case .cancelled: return japanese ? "購入をキャンセルしました。" : "Purchase cancelled."
        case .restored: return japanese ? "購入を復元しました。" : "Your purchase has been restored."
        case .nothingToRestore: return japanese ? "このApple Accountには復元できる購入が見つかりませんでした。" : "No purchase was found for this Apple Account."
        case .unverified: return japanese ? "購入を検証できませんでした。購入の復元をお試しください。" : "The purchase couldn't be verified. Try restoring purchases."
        }
    }
}

/// Speaking is free; the selected lesson content follows catalog access.
struct SpeakingSessionView: View {
    @Environment(PurchaseStore.self) private var purchases
    let phrases: [Phrase]
    var primedIDs: Set<String> = []
    var body: some View {
        let available = phrases.filter { purchases.allows($0) }
        PracticeView(phrases: available, primedIDs: primedIDs)
            .id(available.map(\.id))
    }
}

struct PrivacyView: View {
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Privacy").font(Typography.phrase) // page titles are serif, as on the purchase screen
                Text("Izzy does not require an account and has no advertising, and no third-party analytics SDK. The developer does not receive your notes, your saved phrases, what you search for, or which expressions you study.")
                Text("Izzy sends anonymous usage to izzy.unvalley.me, a server the developer runs: which screens are opened, that a review was rated and with which of the four ratings, whether it was a phrasal verb or an idiom, the settings in use, and the steps of the Izzy Pro purchase flow. It is identified only by a random value created when the app is installed and gone when it is deleted. No IP address is stored and nothing is shared with anyone else. Turn it off in Settings under Usage data.")
                Text("Progress, saved phrases, and personal notes are stored in the app's local storage. Your device backup settings may include this data. Deleting the app removes its local data; restoring a device backup may restore it.")
                Text("Apple processes purchases. Izzy checks Apple-verified purchase records on your device to unlock access. Restoring a purchase does not restore learning history from another device.")
                Text("Review reminders are scheduled on this device from your review dates and the time you choose. Turning them off in Settings cancels any scheduled reminders.")
                Text("Example speech uses installed system voices. Your voice choice is saved on this device. Japanese meanings for every example are bundled in the app; no text is sent for translation.")
                Text("External reference links open their respective websites and follow those sites' privacy policies.")
                Link("Read privacy policy online", destination: AppSupport.privacyURL)
                    .frame(minHeight: 44).accessibilityIdentifier("onlinePrivacyPolicy")
                Link(AppSupport.email, destination: AppSupport.emailURL).frame(minHeight: 44)
                Text("Updated 23 September 2026").font(.caption).foregroundStyle(Palette.secondary)
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}
