//
//  PhotoSource.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 22.02.2022.
//

import Foundation

fileprivate enum Constants {
    static let hrefStart = "<a href=\""
    static let hrefStop = "\""
}

// в источнике могут находиться как ссылки, так и обычный текст (в том числе одновременно)
// пока что просто достаю ссылку из строки
// также можно будет доставать AttributedText
struct PhotoSource {
    private let value: String

    init(from value: String) {
        self.value = value
    }
}

extension PhotoSource {
    private func extractUrlString(from str: String) -> String? {
        var content = str
        guard !content.isEmpty else { return nil }
        guard let startRange = content.range(of: Constants.hrefStart) else { return nil }
        let startIndex = startRange.upperBound
        content = String(content.suffix(from: startIndex))
        guard let stopRange = content.range(of: Constants.hrefStop) else { return nil }
        let stopIndex = stopRange.lowerBound
        let urlString = String(content.prefix(upTo: stopIndex))
        return urlString
    }

    var url: URL? {
        guard let urlString = extractUrlString(from: value) else { return nil }
        return URL(string: urlString)
    }
}
