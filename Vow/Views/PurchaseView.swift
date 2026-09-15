import SwiftUI

struct ProLockView: View {
    @State private var purchase = false
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock").font(.title2).foregroundStyle(Palette.secondary)
                .accessibilityHidden(true)
            // One line does the explaining and the inviting.
            SecondaryButton(title: String(localized: "Unlock every phrase with Pro"), identifier: "unlockPro") { purchase = true }
        }.multilineTextAlignment(.center).padding(Spacing.lg)
            .frame(maxWidth: 400).frame(maxWidth: .infinity)
            .sheet(isPresented: $purchase) { PurchaseView() }
            .closesForReviewRequest($purchase)
    }
}

struct PurchaseView: View {
    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    var body: some View {
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Vow Pro").font(Typography.phrase).staggeredEntrance(0)
                    if purchases.hasFullAccess {
                        Label(japanese ? "購入済み" : "Purchased", systemImage: "checkmark.circle.fill").foregroundStyle(accent.color).accessibilityIdentifier("purchaseUnlocked")
                        Text(japanese ? "句動詞とイディオムをすべて閲覧・復習できます。" : "Browse and review every phrase.")
                    } else {
                        Text(japanese ? "学んだ表現を、会話で使える言葉に。" : "Turn phrases you know into words you can use.").font(.title2)
                            .staggeredEntrance(1)
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label(japanese ? "全\(store.phrases.count)表現を解放" : "All \(store.phrases.count) phrases", systemImage: "text.bubble")
                            Label(japanese ? "すべての表現を間隔反復で復習" : "Spaced reviews for the full collection", systemImage: "calendar")
                        }.font(.body).padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
                            .staggeredEntrance(2)
                        Text(japanese ? "買い切り・自動更新なし" : "One purchase. No subscription.").font(.headline)
                            .staggeredEntrance(3)
                        if purchases.isChecking || purchases.isLoading {
                            SwiftUI.ProgressView(japanese ? "購入情報を確認中…" : "Checking purchase information…")
                        }
                        if let product = purchases.product {
                            PrimaryButton(title: japanese ? "\(product.displayPrice)で解放" : "Unlock for \(product.displayPrice)") { Task { await purchases.purchase() } }
                                .disabled(purchases.isBusy || purchases.isChecking).accessibilityIdentifier("buyComplete")
                        } else if !purchases.isLoading {
                            Button(japanese ? "価格を再読み込み" : "Reload price") { Task { await purchases.loadProduct() } }.frame(minHeight: 44).accessibilityIdentifier("reloadPrice")
                        }
                        Text(japanese ? "無料プランでも、句動詞50個・イディオム50個、コアイメージ35種類、Speaking、全5シーンのストーリー練習、復習、連続リスニングを使えます。" : "The free plan includes 50 phrasal verbs, 50 idioms, all 35 core images, speaking, all 5 story scenes, spaced reviews and continuous listening.")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
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
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(japanese ? "閉じる" : "Done") { dismiss() } } }
        }.task { if purchases.product == nil { await purchases.loadProduct() } }
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
                Text("vow does not require an account and has no advertising or analytics SDKs. The developer does not receive your practice audio, replies, notes, or progress.")
                Text("Recordings are temporary files on your device. They are removed when you leave an exercise; abandoned files are removed on the next launch. You can practice without microphone access.")
                Text("Progress, saved phrases, and personal notes are stored in the app's local storage. Your device backup settings may include this data. Deleting the app removes its local data; restoring a device backup may restore it.")
                Text("Apple processes purchases. vow checks Apple-verified purchase records on your device to unlock access. Restoring a purchase does not restore learning history from another device.")
                Text("Review reminders are optional. After you allow notifications, review dates and your chosen time are used to schedule notifications on this device. No learning history is sent to the developer. Turn reminders off in Settings to cancel scheduled notifications.")
                Text("Example speech uses installed system voices. Your voice choice is saved on this device. Japanese meanings for every example are bundled in the app; no text is sent for translation.")
                Text("External reference links open their respective websites and follow those sites' privacy policies.")
                Link("Read privacy policy online", destination: AppSupport.privacyURL)
                    .frame(minHeight: 44).accessibilityIdentifier("onlinePrivacyPolicy")
                Link(AppSupport.email, destination: AppSupport.emailURL).frame(minHeight: 44)
                Text("Updated 13 September 2026").font(.caption).foregroundStyle(Palette.secondary)
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}
