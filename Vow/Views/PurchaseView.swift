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
                        Text(japanese ? "1,300表現を、使える言葉に。" : "Make all 1,300 expressions yours.")
                            .font(.title2).fixedSize(horizontal: false, vertical: true)
                            .staggeredEntrance(1)
                        Text(japanese
                             ? "無料で使える100表現の先に、日常会話でよく出る句動詞とイディオムが1,200以上あります。Proはその全部を、例文・日本語訳・音声・復習つきで開きます。背景とフォントも、すべて選べるようになります。"
                             : "Beyond the 100 free expressions are 1,200 more phrasal verbs and idioms. Pro opens all of them, with examples, meanings, audio and reviews, and every background and phrase font.")
                            .font(.body).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
                            .staggeredEntrance(2)
                        comparison.staggeredEntrance(3)
                        appearance.staggeredEntrance(4)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label(japanese ? "買い切り。自動更新はありません" : "One purchase. No subscription.", systemImage: "checkmark.seal")
                            Label(japanese ? "オフラインで使えます" : "Works offline", systemImage: "wifi.slash")
                            Label(japanese ? "学習履歴は端末の中だけ" : "Your history stays on your device", systemImage: "lock")
                        }.font(.subheadline).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(5)
                        if purchases.isChecking || purchases.isLoading {
                            SwiftUI.ProgressView(japanese ? "購入情報を確認中…" : "Checking purchase information…")
                        }
                        if let product = purchases.product {
                            PrimaryButton(title: japanese ? "\(product.displayPrice)で全表現を解放" : "Unlock everything for \(product.displayPrice)") { Task { await purchases.purchase() } }
                                .disabled(purchases.isBusy || purchases.isChecking).accessibilityIdentifier("buyComplete")
                                .staggeredEntrance(6)
                        } else if !purchases.isLoading {
                            Button(japanese ? "価格を再読み込み" : "Reload price") { Task { await purchases.loadProduct() } }.frame(minHeight: 44).buttonStyle(PressStyle()).accessibilityIdentifier("reloadPrice")
                        }
                        Text(japanese ? "無料のままでも、100表現の学習・復習、コアイメージ35種、練習、連続リスニング、背景2種とフォント2種は続けて使えます。" : "The free plan keeps its 100 expressions, all 35 core images, practice, continuous listening, 2 backgrounds and 2 fonts.")
                            .font(.caption).foregroundStyle(Palette.secondary)
                            .staggeredEntrance(7)
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
    /// Free beside Pro, in the learner's own numbers: the difference is the collection, not the features.
    private var comparison: some View {
        let rows: [(String, String, String)] = japanese
            ? [("学べる表現", "100", "1,300"), ("例文と日本語訳", "240", "2,133"), ("間隔をあけた復習", "100表現", "すべて"), ("背景", "2種", "\(TodayBackground.allCases.count)種"), ("フレーズのフォント", "2種", "\(PhraseTypeface.allCases.count)種"), ("フレーズの保存とメモ", "○", "○")]
            : [("Expressions", "100", "1,300"), ("Examples with meanings", "240", "2,133"), ("Spaced reviews", "100", "All"), ("Backgrounds", "2", "\(TodayBackground.allCases.count)"), ("Phrase fonts", "2", "\(PhraseTypeface.allCases.count)"), ("Saved phrases and notes", "Yes", "Yes")]
        return VStack(spacing: 0) {
            HStack {
                Text(verbatim: " ").frame(maxWidth: .infinity, alignment: .leading)
                Text(japanese ? "無料" : "Free").frame(width: 72)
                Text("Vow Pro").frame(width: 72)
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

    /// What Pro changes on screen, shown rather than listed: the Pro backgrounds and fonts side by side.
    private var appearance: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(japanese ? "背景とフォントも、自分好みに" : "Make it look like yours")
                .font(Typography.section)
            HStack(spacing: Spacing.xs) {
                ForEach(TodayBackground.allCases.filter { !$0.isFree }.prefix(4), id: \.self) { background in
                    Color.clear.aspectRatio(3.0 / 4.0, contentMode: .fit)
                        .overlay { Image(background.imageName).resizable().scaledToFill() }
                        .clipShape(RoundedRectangle(cornerRadius: Radius.small))
                        .overlay { RoundedRectangle(cornerRadius: Radius.small).strokeBorder(Palette.outline, lineWidth: 1) }
                }
            }
            HStack(spacing: 0) {
                ForEach([PhraseTypeface.georgia, .didot, .rounded, .avenir, .typewriter], id: \.self) { face in
                    Text(verbatim: "Aa").font(face.font(size: 28)).dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
            }.foregroundStyle(Palette.ink)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel(japanese ? "Vow Proの背景とフォント" : "Vow Pro backgrounds and fonts")
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
                Text("vow does not require an account and has no advertising or analytics SDKs. The developer does not receive your notes or progress.")
                Text("vow does not use the microphone and does not record audio.")
                Text("Progress, saved phrases, and personal notes are stored in the app's local storage. Your device backup settings may include this data. Deleting the app removes its local data; restoring a device backup may restore it.")
                Text("Apple processes purchases. vow checks Apple-verified purchase records on your device to unlock access. Restoring a purchase does not restore learning history from another device.")
                Text("Review reminders are optional. After you allow notifications, review dates and your chosen time are used to schedule notifications on this device. No learning history is sent to the developer. Turn reminders off in Settings to cancel scheduled notifications.")
                Text("Example speech uses installed system voices. Your voice choice is saved on this device. Japanese meanings for every example are bundled in the app; no text is sent for translation.")
                Text("External reference links open their respective websites and follow those sites' privacy policies.")
                Link("Read privacy policy online", destination: AppSupport.privacyURL)
                    .frame(minHeight: 44).accessibilityIdentifier("onlinePrivacyPolicy")
                Link(AppSupport.email, destination: AppSupport.emailURL).frame(minHeight: 44)
                Text("Updated 16 September 2026").font(.caption).foregroundStyle(Palette.secondary)
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}
