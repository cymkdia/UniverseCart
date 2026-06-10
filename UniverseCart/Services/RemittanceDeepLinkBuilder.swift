import Foundation
import UIKit

struct SettlementBankOption: Identifiable, Hashable {
    let id: String
    let displayName: String
    let kakaoBankCode: String
    let tossBankName: String

    static let common: [SettlementBankOption] = [
        SettlementBankOption(id: "kb", displayName: "KB국민", kakaoBankCode: "004", tossBankName: "KB국민"),
        SettlementBankOption(id: "shinhan", displayName: "신한", kakaoBankCode: "088", tossBankName: "신한"),
        SettlementBankOption(id: "woori", displayName: "우리", kakaoBankCode: "020", tossBankName: "우리"),
        SettlementBankOption(id: "nh", displayName: "NH농협", kakaoBankCode: "011", tossBankName: "NH농협"),
        SettlementBankOption(id: "hana", displayName: "하나", kakaoBankCode: "081", tossBankName: "하나"),
        SettlementBankOption(id: "kakao", displayName: "카카오뱅크", kakaoBankCode: "090", tossBankName: "카카오"),
        SettlementBankOption(id: "toss", displayName: "토스뱅크", kakaoBankCode: "092", tossBankName: "토스"),
        SettlementBankOption(id: "ibk", displayName: "IBK기업", kakaoBankCode: "003", tossBankName: "IBK기업"),
    ]
}

enum RemittanceDeepLinkBuilder {
    /// 카카오페이 계좌송금 — https://t1.daumcdn.net/kakaopay/static/guide/account-remittance-app-link/
    static func kakaoPayURL(
        bankCode: String,
        accountNumber: String,
        amount: Int
    ) -> URL? {
        let sanitizedAccount = accountNumber.filter { $0.isNumber }
        guard !bankCode.isEmpty, !sanitizedAccount.isEmpty, amount > 0 else { return nil }

        var components = URLComponents()
        components.scheme = "kakaopay"
        components.host = "money"
        components.path = "/to/bank"
        components.queryItems = [
            URLQueryItem(name: "bank_code", value: bankCode),
            URLQueryItem(name: "bank_account_number", value: sanitizedAccount),
            URLQueryItem(name: "amount", value: String(amount)),
        ]
        return components.url
    }

    /// 토스 송금 — supertoss://send?bank=&accountNo=&amount=
    static func tossURL(
        bankName: String,
        accountNumber: String,
        amount: Int
    ) -> URL? {
        let sanitizedAccount = accountNumber.filter { $0.isNumber }
        guard !bankName.isEmpty, !sanitizedAccount.isEmpty, amount > 0 else { return nil }

        var components = URLComponents()
        components.scheme = "supertoss"
        components.host = "send"
        components.queryItems = [
            URLQueryItem(name: "bank", value: bankName),
            URLQueryItem(name: "accountNo", value: sanitizedAccount),
            URLQueryItem(name: "amount", value: String(amount)),
        ]
        return components.url
    }

    static func fallbackAccountText(
        bankName: String,
        accountNumber: String,
        amount: Int,
        recipientLabel: String
    ) -> String {
        let formattedAmount = formatPrice(amount)
        return """
        [Universe Cart 정산 안내]
        \(recipientLabel)에게 \(formattedAmount) 송금해 주세요.

        은행: \(bankName)
        계좌: \(accountNumber)

        UC는 결제·송금을 처리하지 않습니다.
        """
    }

    static func openURL(_ url: URL, fallbackText: String) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        UIPasteboard.general.string = fallbackText
        return false
    }

    static func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}
