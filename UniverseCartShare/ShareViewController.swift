//
//  ShareViewController.swift
//  UniverseCartShare
//

import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let titleLabel = UILabel()
    private let imageLabel = UILabel()

    private let priceLabel = UILabel()
    private let priceTextField = UITextField()

    private let listTypeLabel = UILabel()
    private let listTypeControl = UISegmentedControl(items: ["위시리스트", "내 장바구니"])

    private let categoryLabel = UILabel()
    private let categoryControl = UISegmentedControl(items: ["패션", "홈리빙", "식품", "뷰티"])

    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .large)

    private var sharedURL: URL?
    private var extractedTitle: String?
    private var extractedImageURL: String?
    private var extractedPrice: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()

        Task {
            await loadSharedURL()
        }
    }

    private func setupUI() {
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .body)

        titleLabel.numberOfLines = 2
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        imageLabel.numberOfLines = 2
        imageLabel.font = .preferredFont(forTextStyle: .caption1)
        imageLabel.textColor = .secondaryLabel

        priceLabel.font = .preferredFont(forTextStyle: .subheadline)
        priceLabel.textColor = .label

        priceTextField.placeholder = "가격 직접 입력 (원)"
        priceTextField.keyboardType = .numberPad
        priceTextField.borderStyle = .roundedRect
        priceTextField.isHidden = true

        listTypeLabel.text = "담을 곳"
        listTypeLabel.font = .preferredFont(forTextStyle: .subheadline)
        listTypeControl.selectedSegmentIndex = 0

        categoryLabel.text = "카테고리"
        categoryLabel.font = .preferredFont(forTextStyle: .subheadline)
        categoryControl.selectedSegmentIndex = 0

        saveButton.setTitle("담기", for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        saveButton.isEnabled = false

        cancelButton.setTitle("취소", for: .normal)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 16
        buttonRow.distribution = .fillEqually

        let priceSection = UIStackView(arrangedSubviews: [priceLabel, priceTextField])
        priceSection.axis = .vertical
        priceSection.spacing = 8

        let listTypeSection = UIStackView(arrangedSubviews: [listTypeLabel, listTypeControl])
        listTypeSection.axis = .vertical
        listTypeSection.spacing = 8

        let categorySection = UIStackView(arrangedSubviews: [categoryLabel, categoryControl])
        categorySection.axis = .vertical
        categorySection.spacing = 8

        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            spinner,
            titleLabel,
            imageLabel,
            priceSection,
            listTypeSection,
            categorySection,
            buttonRow
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    private var selectedListType: ListType {
        listTypeControl.selectedSegmentIndex == 0 ? .wishlist : .cart
    }

    private var selectedCategory: Category {
        switch categoryControl.selectedSegmentIndex {
        case 0: return .fashion
        case 1: return .home
        case 2: return .food
        default: return .beauty
        }
    }

    @MainActor
    private func loadSharedURL() async {
        statusLabel.text = "공유 URL 확인 중..."
        spinner.startAnimating()

        guard let url = await extractSharedURL() else {
            spinner.stopAnimating()
            statusLabel.text = "URL을 찾지 못했어요. Safari/쇼핑앱에서 링크를 공유해 주세요."
            return
        }

        sharedURL = url
        statusLabel.text = "상품 정보 불러오는 중...\n\(url.host ?? url.absoluteString)"
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
        let metadata = await OGMetadataExtractor.fetch(from: url)
        spinner.stopAnimating()

        extractedTitle = metadata.title
        extractedImageURL = metadata.imageURL
        extractedPrice = metadata.price

        titleLabel.text = metadata.title ?? "(제목 자동 추출 실패)"
        imageLabel.text = metadata.imageURL ?? "(이미지 URL 없음)"

        if let price = metadata.price {
            priceLabel.text = "가격: \(formatKRW(price))"
            priceTextField.isHidden = true
            priceTextField.text = "\(price)"
        } else {
            priceLabel.text = "가격을 찾지 못했어요 — 직접 입력해 주세요"
            priceTextField.isHidden = false
            priceTextField.text = ""
        }

        statusLabel.text = "담을 곳·카테고리 선택 후 담기"
        saveButton.isEnabled = true
    }

    private func resolvedPriceForSave() -> (price: Int?, priceManual: Bool) {
        if !priceTextField.isHidden {
            let manualDigits = priceTextField.text?.filter(\.isNumber) ?? ""
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

        let pending = SharedPendingItem(
            id: UUID(),
            title: extractedTitle ?? url.host ?? "공유 상품",
            imageURL: extractedImageURL,
            price: price,
            priceManual: priceManual,
            productURL: url.absoluteString,
            mall: MallDetector.detect(from: url),
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
