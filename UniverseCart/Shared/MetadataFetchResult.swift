import Foundation

enum MetadataFetchIssue: Equatable {
    case network
    case blocked(statusCode: Int?)
    case parseFailed
    case partialMissingTitle
    case partialMissingPrice
    case partialMissingImage

    var userMessage: String {
        switch self {
        case .network:
            return "네트워크 연결을 확인한 뒤 다시 시도해 주세요."
        case .blocked(let code):
            if let code {
                return "쇼핑몰에서 정보를 가져오지 못했어요 (응답 \(code)). 제목·가격을 직접 입력해 주세요."
            }
            return "쇼핑몰에서 정보를 가져오지 못했어요. 제목·가격을 직접 입력해 주세요."
        case .parseFailed:
            return "페이지를 읽지 못했어요. 제목·가격을 직접 입력해 주세요."
        case .partialMissingTitle:
            return "제목을 자동으로 가져오지 못했어요. 아래 내용을 확인해 주세요."
        case .partialMissingPrice:
            return "가격을 자동으로 가져오지 못했어요. 가격을 직접 입력해 주세요."
        case .partialMissingImage:
            return "이미지를 자동으로 가져오지 못했어요. 나머지 정보로 담을 수 있어요."
        }
    }
}

struct MetadataFetchResult {
    let metadata: OGMetadata
    let primaryIssue: MetadataFetchIssue?
    let partialIssues: [MetadataFetchIssue]

    var isHardFailure: Bool {
        primaryIssue != nil
    }

    /// 화면 상단/폼에 보여 줄 한 줄 요약
    var displayMessage: String? {
        if let primaryIssue {
            return primaryIssue.userMessage
        }

        let partialMessages = partialIssues.map(\.userMessage)
        guard !partialMessages.isEmpty else { return nil }

        if partialMessages.count == 1 {
            return partialMessages[0]
        }
        return partialMessages.joined(separator: " ")
    }
}
