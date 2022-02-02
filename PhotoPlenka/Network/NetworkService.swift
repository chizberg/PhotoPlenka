//
//  NetworkService.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

protocol NetworkServiceProtocol {
    typealias CompletionType =
        (Result<(photos: [NetworkPhoto], clusters: [NetworkCluster]), NetworkError>) -> Void
    func loadByBounds(
        z: Int,
        region: MKCoordinateRegion,
        _ completion: @escaping CompletionType
    )
}

final class NetworkService: NetworkServiceProtocol {
    func loadByBounds(
        z: Int,
        region: MKCoordinateRegion,
        _ completion: @escaping CompletionType
    ) {
        let request = Request.byBounds(z: z, region: region)
        loadByBounds(request) { (result: Result<
            (photos: [NetworkPhoto], clusters: [NetworkCluster]),
            NetworkError
        >) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private func loadByBounds(
        _ request: Request,
        _ completion: @escaping CompletionType
    ) {
        switch request {
        case .byBounds:
            guard let url = request.url else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let self = self else { return }
                guard let data = data, error == nil else {
                    completion(.failure(.connectionFailure))
                    return
                }
                do {
                    let json = try JSONSerialization
                        .jsonObject(with: data, options: []) as! [String: Any]
                    let result = json["result"] as! [String: Any]
                    let photos = self.parsePhotos(from: result["photos"] as? [[String: Any]])
                    let clusters = self.parseClusters(from: result["clusters"] as? [[String: Any]])
                    guard let photos = photos,
                          let clusters = clusters else { throw NetworkError.parsingError }
                    completion(.success((photos, clusters)))
                } catch {
                    completion(.failure(.parsingError))
                }
            }.resume()
        }
    }

    // TODO: сделать парсинг в теории покрасивее (может, через Codable). Прямо сейчас сделал так, потому что поле dir есть не во всех объектах респонса (то есть вообще поля нет, а не его значения)
    private func parsePhotos(from json: [[String: Any]]?) -> [NetworkPhoto]? {
        guard let json = json else { return nil }
        let photos: [NetworkPhoto] = json.compactMap { parsePhoto(from: $0) }
        return photos
    }

    private func parsePhoto(from json: [String: Any]) -> NetworkPhoto? {
        guard let cid = json["cid"] as? Int else { return nil }
        guard let file = json["file"] as? String else { return nil }
        guard let title = json["title"] as? String else { return nil }
        let dir: String? = json["dir"] as? String
        guard let geo = json["geo"] as? [Double] else { return nil }
        guard let year = json["year"] as? Int else { return nil }
        guard let year2 = json["year2"] as? Int else { return nil }
        return NetworkPhoto(
            cid: cid,
            file: file,
            title: title,
            dir: dir,
            geo: geo,
            year: year,
            year2: year2
        )
    }

    private func parseClusters(from json: [[String: Any]]?) -> [NetworkCluster]? {
        guard let json = json else { return nil }
        return json.compactMap { (clusterJSON: [String: Any]) -> NetworkCluster? in
            guard let photoJSON = clusterJSON["p"] as? [String: Any] else { return nil }
            guard let photo = parsePhoto(from: photoJSON) else { return nil }
            guard let location = clusterJSON["geo"] as? [Double] else { return nil }
            guard let count = clusterJSON["c"] as? Int else { return nil }
            return NetworkCluster(p: photo, geo: location, c: count)
        }
    }
}
