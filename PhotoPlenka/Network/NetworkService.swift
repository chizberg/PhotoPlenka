//
//  NetworkService.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 02.02.2022.
//

import MapKit

protocol NetworkServiceProtocol {
  typealias PhotosAndClustersCompletion =
    (Result<(photos: [NetworkPhoto], clusters: [NetworkCluster]), NetworkError>) -> Void
  typealias DetailedPhotoCompletion = (Result<NetworkDetailedPhoto, NetworkError>) -> Void
  typealias DataCompletion = (Result<Data, NetworkError>) -> Void

  func loadByBounds(
    z: Int,
    region: MKCoordinateRegion,
    yearRange: ClosedRange<Int>,
    _ completion: @escaping PhotosAndClustersCompletion
  )
  func loadDetails(
    cid: Int,
    _ completion: @escaping DetailedPhotoCompletion
  )
}

final class NetworkService: NetworkServiceProtocol {
  // MARK: public functions

  func loadByBounds(
    z: Int,
    region: MKCoordinateRegion,
    yearRange: ClosedRange<Int>,
    _ completion: @escaping PhotosAndClustersCompletion
  ) {
    let request = Request.byBounds(z: z, region: region, yearRange: yearRange)
    photosAndClusters(request.url) { result in
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }

  func loadDetails(cid: Int, _ completion: @escaping DetailedPhotoCompletion) {
    let request = Request.photoDetails(cid: cid)
    detailedPhoto(request.url) { result in
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }

  // MARK: private requests by url

  private func photosAndClusters(
    _ url: URL?,
    _ completion: @escaping PhotosAndClustersCompletion
  ) {
    loadData(url) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case let .success(data):
        do {
          let json = try JSONSerialization
            .jsonObject(with: data, options: []) as! [String: Any]
          let result = json["result"] as! [String: Any]
          let photos = self.parsePhotos(from: result["photos"] as? [[String: Any]])
          let clusters = self.parseClusters(from: result["clusters"] as? [[String: Any]])
          completion(.success((photos, clusters)))
        } catch {
          completion(.failure(.parsingError))
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  private func detailedPhoto(
    _ url: URL?,
    _ completion: @escaping DetailedPhotoCompletion
  ) {
    loadData(url) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case let .success(data):
        do {
          let json = try JSONSerialization
            .jsonObject(with: data, options: []) as! [String: Any]
          let result = json["result"] as! [String: Any]
          guard let detailedPhoto = self
            .parseDetailedPhoto(from: result["photo"] as? [String: Any])
          else { throw NetworkError.parsingError }
          completion(.success(detailedPhoto))
        } catch {
          completion(.failure(.parsingError))
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  // MARK: - load data by url

  private func loadData(
    _ url: URL?,
    _ completion: @escaping DataCompletion
  ) {
    guard let url = url else { return }
    URLSession.shared.dataTask(with: url) { data, _, error in
      guard let data = data, error == nil else {
        completion(.failure(.connectionFailure))
        return
      }
      completion(.success(data))
    }.resume()
  }

  // TODO: сделать парсинг в теории покрасивее (может, через Codable). Прямо сейчас сделал так, потому что поле dir есть не во всех объектах респонса (то есть вообще поля нет, а не его значения)
  private func parsePhotos(from json: [[String: Any]]?) -> [NetworkPhoto] {
    guard let json = json else { return [] }
    let photos: [NetworkPhoto] = json.compactMap { parsePhoto(from: $0) }
    return photos
  }

  private func parsePhoto(from json: [String: Any]) -> NetworkPhoto? {
    guard let cid = json["cid"] as? Int else { return nil }
    guard let file = json["file"] as? String else { return nil }
    guard let title = json["title"] as? String else { return nil }
    guard let geo = json["geo"] as? [Double] else { return nil }
    guard let year = json["year"] as? Int else { return nil }
    guard let year2 = json["year2"] as? Int else { return nil }
    let dir: String? = json["dir"] as? String
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

  private func parseClusters(from json: [[String: Any]]?) -> [NetworkCluster] {
    guard let json = json else { return [] }
    return json.compactMap { (clusterJSON: [String: Any]) -> NetworkCluster? in
      guard let photoJSON = clusterJSON["p"] as? [String: Any] else { return nil }
      guard let photo = parsePhoto(from: photoJSON) else { return nil }
      guard let location = clusterJSON["geo"] as? [Double] else { return nil }
      guard let count = clusterJSON["c"] as? Int else { return nil }
      return NetworkCluster(p: photo, geo: location, c: count)
    }
  }

  private func parseDetailedPhoto(from json: [String: Any]?) -> NetworkDetailedPhoto? {
    guard let json = json else { return nil }
    guard let cid = json["cid"] as? Int else { return nil }
    guard let file = json["file"] as? String else { return nil }
    guard let title = json["title"] as? String else { return nil }
    guard let geo = json["geo"] as? [Double] else { return nil }
    guard let year = json["year"] as? Int else { return nil }
    guard let year2 = json["year2"] as? Int else { return nil }
    let dir: String? = json["dir"] as? String

    let source = json["source"] as? String
    let address = json["address"] as? String
    let author = json["author"] as? String
    let desc: String? = json["desc"] as? String

    guard let user = json["user"] as? [String: Any] else { return nil }
    guard let username = user["disp"] as? String else { return nil }
    return NetworkDetailedPhoto(
      cid: cid,
      file: file,
      title: title,
      dir: dir,
      geo: geo,
      year: year,
      year2: year2,
      desc: desc,
      source: source,
      address: address,
      author: author,
      username: username
    )
  }
}
