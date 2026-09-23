import SwiftUI

struct ProLockView: View {
    /// Where this card sits, so the funnel can show which one people act on.
    var place = "list"
    @State private var purchase = false
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock").font(.title2).foregroundStyle(Palette.secondary)
                .accessibilityHidden(true)
            // One line does the explaining and the inviting.
            SecondaryButton(title: String(localized: "Unlock every phrase with Pro"), identifier: "unlockPro") { purchase = true }
        }.multilineTextAlignment(.center).padding(Spacing.lg)
            .frame(maxWidth: 400).frame(maxWidth: .infinity)
            .sheet(isPresented: $purchase) { PurchaseView(from: place) }
            .closesForReviewRequest($purchase)
            .onAppear { Analytics.shared.record(.proLockShown, ["place": place]) }
    }
}

struct PurchaseView: View {
    /// The screen this was opened from: the step before it in the funnel.
    var from = "unknown"

    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    private var facts: CatalogFacts { CatalogFacts(phrases: store.phrases) }
    var body: some View {
        let facts = facts
        return NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Izzy Pro").font(Typography.phrase).staggeredEntrance(0)
                    if purchases.hasFullAccess {
                        Label(japanese ? "購入済み" : "Purchased", systemImage: "checkmark.circle.fill").foregroundStyle(accent.color).accessibilityIdentifier("purchaseUnlocked")
                        Text(japanese ? "句動詞とイディオムをすべて閲覧・復習できます。" : "Browse and review every phrase.")
                    } else {
                        let claim = CatalogFacts.openEnded(facts.expressions).formatted()
                        Text(japanese ? "\(claim)以上の表現を、使える言葉に。" : "Make \(claim)+ expressions yours.")
                            .font(.title2).fixedSize(horizontal: false, vertical: true)
                            .staggeredEntrance(1)
                        comparison(facts).staggeredEntrance(2)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label(japanese ? "買い切り。自動更新はありません" : "One purchase. No subscription.", systemImage: "checkmark.seal")
                            Label(japanese ? "オフラインで使えます" : "Works offline", systemImage: "wifi.slash")
                            Label(japanese ? "学習履歴はiCloudで引き継げます" : "Your history carries over with iCloud", systemImage: "icloud")
                        }.font(.subheadline).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(3)
                        if purchases.isChecking || purchases.isLoading {
                            SwiftUI.ProgressView(japanese ? "購入情報を確認中…" : "Checking purchase information…")
                        }
                        if let product = purchases.product {
                            PrimaryButton(title: japanese ? "\(product.displayPrice)で全表現を解放" : "Unlock everything for \(product.displayPrice)") { Task { await purchases.purchase() } }
                                .disabled(purchases.isBusy || purchases.isChecking).accessibilityIdentifier("buyComplete")
                                .staggeredEntrance(4)
                        } else if !purchases.isLoading {
                            Button(japanese ? "価格を再読み込み" : "Reload price") { Task { await purchases.loadProduct() } }.frame(minHeight: 44).buttonStyle(PressStyle()).accessibilityIdentifier("reloadPrice")
                        }
                        Text(japanese
                             ? "無料のままでも、\(facts.freeExpressions)表現の学習・復習、コアイメージ\(facts.coreImages)種、練習、連続リスニング、背景\(facts.freeBackgrounds)種とフォント\(facts.freeFonts)種、保存とメモ各\(AccessPolicy.freeKeepLimit)件は続けて使えます。"
                             : "The free plan keeps its \(facts.freeExpressions) expressions, all \(facts.coreImages) core images, practice, continuous listening, \(facts.freeBackgrounds) backgrounds, \(facts.freeFonts) fonts, and up to \(AccessPolicy.freeKeepLimit) saved phrases and notes.")
                            .font(.caption).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(5)
                    }
                    if purchases.isBusy { SwiftUI.ProgressView().accessibilityLabel(japanese ? "処理中" : "Processing") }
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
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(japanese ? "閉じる" : "Done") { dismiss() } } }
        }.task {
            Analytics.shared.record(.proScreenOpened, ["from": from])
            if purchases.product == nil { await purchases.loadProduct() }
        }
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
                Text("Progress, saved phrases, and personal notes are stored in the app's local storage, which device backups may include. When Sync with iCloud is on, they are also stored in your private iCloud database, which only your Apple Account can access. Deleting the app removes its local data; the iCloud copy stays until you delete it from iCloud storage in the Settings app.")
                Text("Apple processes purchases. Izzy checks Apple-verified purchase records on your device to unlock access. Restoring a purchase restores access; learning history moves between devices with Sync with iCloud.")
                Text("Review reminders are optional. After you allow notifications, review dates and your chosen time are used to schedule notifications on this device. No learning history is sent to the developer. Turn reminders off in Settings to cancel scheduled notifications.")
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
