//
//  ShareUIComponents.swift
//  UniverseCartShare
//

import UIKit

enum UCUIKitColor {
    static let bg = UIColor(hex: "FFFFFF")
    static let surface = UIColor(hex: "F4F4F4")
    static let border = UIColor(hex: "E4E4E4")
    static let textPrimary = UIColor(hex: "19191A")
    static let textSecond = UIColor(hex: "5D5D5D")
    static let textDisabled = UIColor(hex: "A0A0A0")
    static let divider = UIColor(hex: "C4C4C4")
    static let accent = UIColor(hex: "FF4800")
    static let accentSoft = UIColor(hex: "FFEFEB")

    static func mallColor(_ mall: Mall) -> UIColor {
        switch mall {
        case .cm29: return textPrimary
        case .musinsa: return UIColor(hex: "2962FF")
        case .wconcept: return UIColor(hex: "D81B60")
        case .naver: return UIColor(hex: "03C75A")
        case .kurly: return UIColor(hex: "5F0080")
        case .etc: return textDisabled
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Surface card (메인 리스트 요약 바·행 카드와 동일 톤)

final class ShareSurfaceCardView: UIView {
    private let contentStack = UIStackView()

    init() {
        super.init(frame: .zero)
        backgroundColor = UCUIKitColor.surface
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = UCUIKitColor.border.cgColor

        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setArrangedSubviews(_ views: [UIView]) {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach { contentStack.addArrangedSubview($0) }
    }
}

// MARK: - 상품 미리보기 (리스트 행과 비슷한 구성)

final class ShareProductPreviewView: UIView {
    let thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = UCUIKitColor.border
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UCUIKitColor.textPrimary
        return label
    }()

    let mallRow = UIStackView()
    private let mallDot = UIView()
    let mallLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UCUIKitColor.textSecond
        return label
    }()

    let metaLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 12)
        label.textColor = UCUIKitColor.textSecond
        return label
    }()

    let priceField: UITextField = {
        let field = UITextField()
        field.placeholder = "가격 직접 입력 (원)"
        field.keyboardType = .numberPad
        field.font = .systemFont(ofSize: 15)
        field.textColor = UCUIKitColor.textPrimary
        field.backgroundColor = UCUIKitColor.bg
        field.layer.cornerRadius = 7
        field.layer.borderWidth = 1
        field.layer.borderColor = UCUIKitColor.border.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        field.leftViewMode = .always
        field.isHidden = true
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let textStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        mallDot.layer.cornerRadius = 3
        mallDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mallDot.widthAnchor.constraint(equalToConstant: 6),
            mallDot.heightAnchor.constraint(equalToConstant: 6),
        ])

        mallRow.axis = .horizontal
        mallRow.spacing = 6
        mallRow.alignment = .center
        mallRow.addArrangedSubview(mallDot)
        mallRow.addArrangedSubview(mallLabel)

        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(mallRow)
        textStack.addArrangedSubview(metaLabel)
        textStack.addArrangedSubview(priceField)

        let row = UIStackView(arrangedSubviews: [thumbnailView, textStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: 72),
            thumbnailView.heightAnchor.constraint(equalToConstant: 72),
            priceField.heightAnchor.constraint(equalToConstant: 40),

            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(mall: Mall, title: String, meta: String?, priceText: String?, showPriceField: Bool) {
        titleLabel.text = title
        mallLabel.text = mall.listLabel
        mallDot.backgroundColor = UCUIKitColor.mallColor(mall)
        metaLabel.text = meta
        metaLabel.isHidden = meta == nil || meta?.isEmpty == true

        if showPriceField {
            priceField.isHidden = false
            metaLabel.isHidden = true
        } else {
            priceField.isHidden = true
            if let priceText {
                metaLabel.text = priceText
                metaLabel.isHidden = false
                metaLabel.font = .systemFont(ofSize: 15, weight: .semibold)
                metaLabel.textColor = UCUIKitColor.textPrimary
            }
        }
    }

    func setThumbnail(urlString: String?) {
        thumbnailView.image = nil
        thumbnailView.backgroundColor = UCUIKitColor.border

        guard let urlString,
              let url = URL(string: urlString)
        else { return }

        Task {
            if let image = await ShareImageLoader.load(from: url) {
                await MainActor.run {
                    self.thumbnailView.image = image
                    self.thumbnailView.backgroundColor = .clear
                }
            }
        }
    }
}

enum ShareImageLoader {
    static func load(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - 버튼

enum ShareButtonStyle {
    static func applyPrimary(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UCUIKitColor.accent
        button.layer.cornerRadius = 7
    }

    static func applySecondary(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UCUIKitColor.textPrimary, for: .normal)
        button.backgroundColor = UCUIKitColor.bg
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.layer.borderColor = UCUIKitColor.border.cgColor
    }

    static let actionHeight: CGFloat = 44
}

// MARK: - 담을 곳 (메인 세그먼트와 동일)

final class ShareSegmentBar: UIView {
    var selectedIndex: Int = 0 {
        didSet { refreshSelection() }
    }

    var onSelectionChange: ((Int) -> Void)?

    private let titles: [String]
    private let backgroundPanel = UIView()
    private var buttons: [UIButton] = []

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundPanel.backgroundColor = UCUIKitColor.surface
        backgroundPanel.layer.cornerRadius = 7
        backgroundPanel.layer.borderWidth = 1
        backgroundPanel.layer.borderColor = UCUIKitColor.border.cgColor
        addSubview(backgroundPanel)

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.layer.cornerRadius = 5
            button.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)
            backgroundPanel.addSubview(button)
            buttons.append(button)
        }

        refreshSelection()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 40)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundPanel.frame = bounds

        let inset: CGFloat = 4
        let innerWidth = bounds.width - inset * 2
        let buttonWidth = innerWidth / CGFloat(max(titles.count, 1))

        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(
                x: inset + buttonWidth * CGFloat(index),
                y: inset,
                width: buttonWidth,
                height: bounds.height - inset * 2
            )
        }

        refreshSelection()
    }

    @objc private func didTapSegment(_ sender: UIButton) {
        selectedIndex = sender.tag
        onSelectionChange?(sender.tag)
        refreshSelection()
    }

    private func refreshSelection() {
        for button in buttons {
            let selected = button.tag == selectedIndex
            button.backgroundColor = selected ? UCUIKitColor.textPrimary : .clear
            button.setTitleColor(selected ? UCUIKitColor.bg : UCUIKitColor.textPrimary, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: selected ? .semibold : .regular)
        }
    }
}

// MARK: - 카테고리 바 (메인 | 구분 스타일)

final class ShareCategoryBarView: UIView {
    var selectedCategory: Category = .fashion {
        didSet { refreshSelection() }
    }

    var onSelectionChange: ((Category) -> Void)?

    private let horizontalInset: CGFloat = 8
    private let categories = Category.allCases
    private var buttons: [UIButton] = []
    private var dividers: [UILabel] = []
    private let bottomLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        for (index, category) in categories.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(category.displayName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.6
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.setTitleColor(UCUIKitColor.textSecond, for: .normal)
            button.addTarget(self, action: #selector(didTapCategory(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }

        for _ in 0..<categories.count - 1 {
            let divider = UILabel()
            divider.text = "|"
            divider.font = .systemFont(ofSize: 12)
            divider.textColor = UCUIKitColor.divider
            divider.textAlignment = .center
            addSubview(divider)
            dividers.append(divider)
        }

        bottomLine.backgroundColor = UCUIKitColor.border
        addSubview(bottomLine)
        refreshSelection()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 40)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let innerWidth = bounds.width - horizontalInset * 2
        let weightSum = categories.map(\.barLayoutWeight).reduce(0, +)
        var x = horizontalInset

        for (index, category) in categories.enumerated() {
            let cellWidth = innerWidth * category.barLayoutWeight / weightSum
            buttons[index].frame = CGRect(x: x, y: 0, width: cellWidth, height: bounds.height)
            x += cellWidth

            if index < dividers.count {
                dividers[index].frame = CGRect(x: x - 0.5, y: 0, width: 1, height: bounds.height)
            }
        }

        bottomLine.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
    }

    @objc private func didTapCategory(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0, index < categories.count else { return }
        selectedCategory = categories[index]
        onSelectionChange?(selectedCategory)
        refreshSelection()
    }

    private func refreshSelection() {
        for (index, button) in buttons.enumerated() {
            let selected = categories[index] == selectedCategory
            button.setTitleColor(
                selected ? UCUIKitColor.textPrimary : UCUIKitColor.textSecond,
                for: .normal
            )
            button.titleLabel?.font = .systemFont(
                ofSize: 11,
                weight: selected ? .semibold : .regular
            )
        }
    }
}
