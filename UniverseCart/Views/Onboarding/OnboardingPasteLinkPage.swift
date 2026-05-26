import SwiftUI

struct OnboardingPasteLinkPage: View {
    let onFinish: () -> Void

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var noticeMessage: String?
    @State private var fetchedTitle = ""
    @State private var fetchedImageURL: String?
    @State private var fetchedPrice: Int?
    @State private var detectedMall: Mall = .etc
    @State private var hasFetched = false
    @State private var clipboardBanner: String?

    var body: some View {
        OnboardingPageScaffold {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingHeader(
                    title: "평소 갖고 싶던 것,\n링크 하나만 담아볼까요?",
                    subtitle: "상품 링크를 붙여넣으면 이미지·가격을 자동으로 불러와 담아요."
                )

                if let clipboardBanner {
                    clipboardBannerView(clipboardBanner)
                }

                urlField

                fetchButton

                if let noticeMessage {
                    Text(noticeMessage)
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if hasFetched {
                    previewCard
                }

                Text("복사한 링크가 없나요? 쇼핑몰에서 상품의 ‘링크 복사’를 누른 뒤 다시 와요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding(.bottom, 16)
        } footer: {
            VStack(spacing: 14) {
                OnboardingPrimaryButton(title: "위시리스트에 담기", action: saveAndFinish)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)

                Button("나중에 할게요", action: onFinish)
                    .font(.subheadline)
                    .foregroundStyle(UCColor.textSecond)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
        }
        .onAppear(perform: loadClipboardURLIfAvailable)
    }

    private var canSave: Bool {
        hasFetched && !fetchedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func clipboardBannerView(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: "03C75A"))
            Text("클립보드에서 링크 발견 \(text)")
                .font(.caption)
                .foregroundStyle(UCColor.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "E8F7EE"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var urlField: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .foregroundStyle(UCColor.textSecond)

            TextField("https://...", text: $urlText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var fetchButton: some View {
        Button {
            Task { await fetchProduct() }
        } label: {
            Group {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("불러오는 중...")
                    }
                } else {
                    Text("상품 정보 가져오기")
                }
            }
        }
        .buttonStyle(UCBorderedButtonStyle())
        .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
    }

    private var previewCard: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text("\(detectedMall.displayName) · 패션")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)

                Text(fetchedTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCColor.textPrimary)
                    .lineLimit(2)

                if let fetchedPrice {
                    Text(formatKRW(fetchedPrice))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(UCColor.textPrimary)
                } else {
                    Text("가격 입력하기")
                        .font(.subheadline)
                        .foregroundStyle(UCColor.textSecond)
                }

                Label("자동으로 불러왔어요", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(hex: "03C75A"))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let fetchedImageURL, let url = URL(string: fetchedImageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Rectangle().fill(UCColor.border)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(UCColor.border)
                .frame(width: 80, height: 80)
        }
    }

    private func loadClipboardURLIfAvailable() {
        guard let raw = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: raw),
              url.scheme?.hasPrefix("http") == true
        else { return }

        urlText = raw
        clipboardBanner = shortURLLabel(for: url)
        Task { await fetchProduct() }
    }

    private func shortURLLabel(for url: URL) -> String {
        let path = url.path.isEmpty ? "" : url.path
        let combined = (url.host ?? "") + path
        if combined.count <= 32 { return combined }
        return String(combined.prefix(29)) + "..."
    }

    @MainActor
    private func fetchProduct() async {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true else {
            noticeMessage = "올바른 http/https 링크를 입력해 주세요."
            hasFetched = false
            return
        }

        isLoading = true
        noticeMessage = nil
        defer { isLoading = false }

        let result = await OGMetadataExtractor.fetch(from: url)
        detectedMall = MallDetector.detect(from: url)
        fetchedTitle = result.metadata.title ?? url.host ?? "공유 상품"
        fetchedImageURL = result.metadata.imageURL
        fetchedPrice = result.metadata.price
        hasFetched = true
        noticeMessage = result.displayMessage
    }

    private func saveAndFinish() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        let productURL = ProductURLNormalizer.canonicalString(from: trimmed) ?? trimmed

        let item = Item(
            id: UUID(),
            title: fetchedTitle,
            imageURL: fetchedImageURL,
            price: fetchedPrice,
            productURL: productURL,
            mall: detectedMall,
            category: .fashion,
            listType: .wishlist
        )

        var items = ItemStore.load() ?? []
        _ = ItemUpsert.apply(item, to: &items, moveUpdatedToTop: true)
        ItemStore.save(items)
        NotificationCenter.default.post(name: .localItemsDidChange, object: nil)
        onFinish()
    }

    private func formatKRW(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}
