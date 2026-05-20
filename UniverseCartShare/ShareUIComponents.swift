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
    static let divider = UIColor(hex: "C4C4C4")
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

// MARK: - 담을 곳 (메인 세그먼트와 동일한 톤)

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
