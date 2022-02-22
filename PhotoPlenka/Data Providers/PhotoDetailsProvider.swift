//
//  PhotoDetailsProvider.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 22.02.2022.
//

import Foundation

protocol PhotoDetailsProviderProtocol {
    typealias CompletionType = (Result<DetailedPhoto, NetworkError>) -> Void
    func loadDetails(cid: Int, _ completion: @escaping CompletionType)
}

final class PhotoDetailsProvider: PhotoDetailsProviderProtocol {
    private let networkService: NetworkServiceProtocol

    init(
        networkService: NetworkServiceProtocol
    ) {
        self.networkService = networkService
    }

    func loadDetails(cid: Int, _ completion: @escaping CompletionType) {
        networkService.loadDetails(cid: cid) { result in
            assert(Thread.isMainThread)
            switch result {
            case let .success(networkDetailedPhoto):
                let detailedPhoto = DetailedPhoto(from: networkDetailedPhoto)
                completion(.success(detailedPhoto))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
