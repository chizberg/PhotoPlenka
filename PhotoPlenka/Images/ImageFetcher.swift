//
//  ImageFetcher.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.02.2022.
//

import UIKit

protocol ImageFetcherProtocol {
  typealias ImageCompletion = (Result<UIImage, NetworkError>) -> Void

  // делаю одиночку, чтобы не передавать в разные части приложения instance
  static var shared: ImageFetcherProtocol { get }

  // эту функцию мы в основном используем, потому что мы можем получить картинку более высокого качества
  // например, если у нас уже есть high quality, а запрашивается medium - можем вернуть high
  func fetchHighestQuality(
    filePath: String,
    quality: ImageQuality,
    completion: @escaping ImageCompletion
  )

  // эту функцию мы используем, когда нужна картинка по конкретному url, без хитростей с качеством
  func fetch(url: NSURL, completion: @escaping ImageCompletion)

  // это нужно юзать в didReceiveMemoryWarning()
  func clear()

  func cancel(by: NSURL)
  func cancelAll()
}

final class ImageFetcher: ImageFetcherProtocol {
  static let shared: ImageFetcherProtocol = ImageFetcher()

  // тут мы храним картинки
  private let cachedImages = NSCache<NSURL, UIImage>()

  // тут мы храним все операции по конкретным url
  private var pendingRequests = [NSURL: [ImageFetchingOperation]]()

  private init() {}

  // эта функция сначала ищет картинки качества выше, если такие есть - то возвращает качество выше
  func fetchHighestQuality(
    filePath: String,
    quality: ImageQuality,
    completion: @escaping ImageCompletion
  ) {
    if let image = cachedHigherQuality(filePath: filePath, quality: quality) {
      DispatchQueue.main.async {
        completion(.success(image))
      }
      return
    }
    guard let url = makeURL(filePath: filePath, quality: quality) else { return }

    fetch(url: url, completion: completion)
  }

  // загрузка картинки по конкретному url
  func fetch(url: NSURL, completion: @escaping ImageCompletion) {
    // если уже есть картинка по этому url - мы её вернём
    if let image = image(url: url) {
      DispatchQueue.main.async {
        completion(.success(image))
      }
      return
    }

    // если картинки в кэше нет - загружаем её
    let operation = ImageFetchingOperation(
      url: url,
      completionHandler: completion,
      stopOtherBlock: { [weak self] result in
        guard let self = self else { return }

        // как только у нас какая-либо операция загрузит результат, она передаёт его во все операции с тем же url и завершает их, а потом удаляет из словаря
        // чтобы не было ситуации, когда операция удаляется быстрее, чем передаёт результат, использую DispatchGroup
        guard let ops = self.pendingRequests[url] else { return }
        let group = DispatchGroup()
        for op in ops {
          group.enter()
          DispatchQueue.main.async {
            op.passiveComplete(result: result)
            group.leave()
          }
        }
        group.wait()
        if case let .success(photo) = result {
          self.cachedImages.setObject(photo, forKey: url)
        }
        self.pendingRequests[url] = nil
      }
    )

    pendingRequests[url, default: []].append(operation)
    operation.start()
  }

  func cancel(by url: NSURL) {
    guard let ops = pendingRequests[url] else { return }
    for op in ops {
      op.cancel()
    }
    pendingRequests[url] = nil
  }

  func cancelAll() {
    for url in pendingRequests.keys {
      cancel(by: url)
    }
  }

  func clear() {
    cancelAll()
    cachedImages.removeAllObjects()
  }

  // поиск картинки качества выше
  private func cachedHigherQuality(filePath: String, quality: ImageQuality) -> UIImage? {
    // проходимся по качеству от максимального до текущего
    // priority может быть от 1 до 3 для preview и high соответствено
    // priority = rawValue, если что
    for tempPriority in (quality.priority..<ImageQuality.maxPriority).reversed() {
      if let url = makeURL(filePath: filePath, quality: .init(rawValue: tempPriority)) {
        // если есть картинка - возвращаем её
        if let image = image(url: url) { return image }
      }
    }
    return nil
  }

  private func makeURL(filePath: String, quality: ImageQuality?) -> NSURL? {
    guard let quality = quality else { return nil }
    return NSURL(string: "https://pastvu.com/_p/\(quality.linkLetter)/\(filePath)")
  }

  private func image(url: NSURL) -> UIImage? {
    cachedImages.object(forKey: url)
  }
}
