//
//  ShareViewController.swift
//  UniverseCartShare
//

import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerLabel = UILabel()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private let previewCard = ShareSurfaceCardView()
    private let productPreview = ShareProductPreviewView()

    private let listTypeBar = ShareSegmentBar(titles: ["위시리스트", "내 장바구니"])
    private let categoryBar = ShareCategoryBarView()

    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var sharedURL: URL?
    private var detectedMall: Mall = .etc
    private var extractedTitle: String?
    private var extractedImageURL: String?
    private var extractedPrice: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UCUIKitColor.bg
        setupUI()

        Task {
            await loadSharedURL()
        }
    }

    private func setupUI() {
        headerLabel.text = "Universe Cart"
        headerLabel.font = .systemFont(ofSize: 20, weight: .bold)
        headerLabel.textColor = UCUIKitColor.textPrimary

        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UCUIKitColor.textSecond
        statusLabel.text = "공유 URL 확인 중..."

        spinner.hidesWhenStopped = true
        spinner.color = UCUIKitColor.textSecond

        previewCard.setArrangedSubviews([productPreview])
        previewCard.alpha = 0.6

        ShareButtonStyle.applyPrimary(saveButton, title: "담기")
        ShareButtonStyle.applySecondary(cancelButton, title: "취소")
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        saveButton.isEnabled = false
        saveButton.alpha = 0.45

        let buttonRow = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually

        let statusRow = UIStackView(arrangedSubviews: [spinner, statusLabel])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(statusRow)
        contentStack.addArrangedSubview(previewCard)
        contentStack.addArrangedSubview(listTypeBar)
        contentStack.addArrangedSubview(categoryBar)
        contentStack.addArrangedSubview(buttonRow)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: ShareButtonStyle.actionHeight),
            cancelButton.heightAnchor.constraint(equalToConstant: ShareButtonStyle.actionHeight),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
    }

    private var selectedListType: ListType {
        listTypeBar.selectedIndex == 0 ? .wishlist : .cart
    }

    private var selectedCategory: Category {
        categoryBar.selectedCategory
    }

    @MainActor
    private func loadSharedURL() async {
        setSaveEnabled(false)
        statusLabel.text = "공유 URL 확인 중..."
        spinner.startAnimating()
        previewCard.alpha = 0.6

        guard let url = await extractSharedURL() else {
            spinner.stopAnimating()
            statusLabel.text = "URL을 찾지 못했어요. Safari·쇼핑앱에서 링크를 공유해 주세요."
            productPreview.configure(
                mall: .etc,
                title: "링크를 불러오지 못했어요",
                meta: nil,
                priceText: nil,
                showPriceField: false
            )
            return
        }

        sharedURL = url
        detectedMall = MallDetector.detect(from: url)
        statusLabel.text = "상품 정보 불러오는 중..."
        await fetchMetadata(for: url)
    }

    private func extractSharedURL() async -> URL? {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let url = await loadURL(from: provider, type: UTType.url.identifier) {
                    return url
                }

                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let url = await loadURL(from: provider, type: UTType.plainText.identifier) {
                    return url
                }
            }
        }

        return nil
    }

    private func loadURL(from provider: NSItemProvider, type: String) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                if let text = item as? String,
                   let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
                   url.scheme?.hasPrefix("http") == true {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    @MainActor
    private func fetchMetadata(for url: URL) async {
        let result = await OGMetadataExtractor.fetch(from: url)
        spinner.stopAnimating()
        previewCard.alpha = 1

        let metadata = result.metadata
        extractedTitle = metadata.title
        extractedImageURL = metadata.imageURL
        extractedPrice = metadata.price

        let title = metadata.title ?? "(제목 자동 추출 실패)"
        let hostMeta = url.host.map { "링크: \($0)" }

        if let price = metadata.price {
            productPreview.configure(
                mall: detectedMall,
                title: title,
                meta: hostMeta,
                priceText: formatKRW(price),
                showPriceField: false
            )
            productPreview.priceField.text = "\(price)"
        } else {
            productPreview.configure(
                mall: detectedMall,
                title: title,
                meta: hostMeta,
                priceText: nil,
                showPriceField: true
            )
            productPreview.priceField.text = ""
        }

        productPreview.setThumbnail(urlString: metadata.imageURL)

        if let message = result.displayMessage {
            statusLabel.text = message
        } else {
            statusLabel.text = "담을 곳과 카테고리를 선택한 뒤 담기를 눌러 주세요."
        }

        setSaveEnabled(true)
    }

    private func setSaveEnabled(_ enabled: Bool) {
        saveButton.isEnabled = enabled
        saveButton.alpha = enabled ? 1 : 0.45
    }

    private func resolvedPriceForSave() -> (price: Int?, priceManual: Bool) {
        if !productPreview.priceField.isHidden {
            let manualDigits = productPreview.priceField.text?.filter(\.isNumber) ?? ""
            if let manual = Int(manualDigits), manual > 0 {
                return (manual, true)
            }
            return (nil, false)
        }
        return (extractedPrice, false)
    }

    @objc private func didTapSave() {
        guard let url = sharedURL else { return }

        let (price, priceManual) = resolvedPriceForSave()
        let productURL = ProductURLNormalizer.canonicalString(from: url.absoluteString)
            ?? url.absoluteString

        let pending = SharedPendingItem(
            id: UUID(),
            title: extractedTitle ?? url.host ?? "공유 상품",
            imageURL: extractedImageURL,
            price: price,
            priceManual: priceManual,
            productURL: productURL,
            mall: detectedMall,
            listType: selectedListType,
            category: selectedCategory,
            createdAt: Date()
        )

        SharedItemStore.append(pending)
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @objc private func didTapCancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "UniverseCartShare", code: 0))
    }

    private func formatKRW(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}
