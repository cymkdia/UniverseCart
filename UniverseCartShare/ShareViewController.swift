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
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .large)

    private var sharedURL: URL?
    private var extractedTitle: String?
    private var extractedImageURL: String?

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

        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            spinner,
            titleLabel,
            imageLabel,
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
        statusLabel.text = "메타데이터 불러오는 중...\n\(url.host ?? url.absoluteString)"
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

        titleLabel.text = metadata.title ?? "(제목 자동 추출 실패)"
        imageLabel.text = metadata.imageURL ?? "(이미지 URL 없음)"
        statusLabel.text = "확인 후 담기를 눌러주세요"
        saveButton.isEnabled = true
    }

    @objc private func didTapSave() {
        guard let url = sharedURL else { return }

        let pending = SharedPendingItem(
            id: UUID(),
            title: extractedTitle ?? url.host ?? "공유 상품",
            imageURL: extractedImageURL,
            productURL: url.absoluteString,
            mall: MallDetector.detect(from: url),
            createdAt: Date()
        )

        SharedItemStore.append(pending)
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    @objc private func didTapCancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "UniverseCartShare", code: 0))
    }
}
