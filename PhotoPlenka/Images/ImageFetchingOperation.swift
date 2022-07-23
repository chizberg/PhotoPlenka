//
//  ImageFetchingOperation.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 13.02.2022.
//

import UIKit

final class ImageFetchingOperation: Operation {
  typealias ImageCompletion = (Result<UIImage, NetworkError>) -> Void

  // этот closure возвращает загруженную картинку
  private let completionHandler: ImageCompletion?

  // этот closure останавливает все ещё не загрузившиеся операции по тому же url, и передаёт им тот же result
  private let stopOtherBlock: ImageCompletion?

  private let session: URLSession
  private var task: URLSessionTask?
  private let url: NSURL

  init(
    url: NSURL,
    session: URLSession = URLSession.shared,
    completionHandler: ImageCompletion?,
    stopOtherBlock: ImageCompletion?
  ) {
    self.url = url
    self.session = session
    self.completionHandler = completionHandler
    self.stopOtherBlock = stopOtherBlock
  }

  override func main() {
    task = session.dataTask(with: url as URL) { [weak self] data, _, error in
      guard let self = self else { return }
      guard let data = data, error == nil else {
        self.complete(result: .failure(.connectionFailure))
        return
      }
      guard let image = UIImage(data: data) else {
        self.complete(result: .failure(.parsingError))
        return
      }
      self.complete(result: .success(image))
    }
    task?.resume()
  }

  private enum State: String {
    case ready = "isReady"
    case executing = "isExecuting"
    case finished = "isFinished"
  }

  private var state = State.ready {
    willSet {
      willChangeValue(forKey: newValue.rawValue)
      willChangeValue(forKey: state.rawValue)
    }
    didSet {
      didChangeValue(forKey: oldValue.rawValue)
      didChangeValue(forKey: state.rawValue)
    }
  }

  override var isReady: Bool {
    super.isReady && state == .ready
  }

  override var isExecuting: Bool {
    state == .executing
  }

  override var isFinished: Bool {
    state == .finished
  }

  override func start() {
    guard !isCancelled else {
      finish()
      return
    }

    if !isExecuting { state = .executing }

    main()
  }

  func finish() {
    if isExecuting { state = .finished }
  }

  // используется, если результат был получен в ЭТОЙ операции
  // вызывает блок stopOtherBlock, который завершает остальные операции по этому url
  private func complete(result: Result<UIImage, NetworkError>) {
    if !isCancelled && !isFinished {
      DispatchQueue.main.async { [weak self] in
        self?.completionHandler?(result)
      }
    }
    stopOtherBlock?(result)
    finish()
  }

  // используется, если результат был получен в ДРУГОЙ операции по тому же URL
  // просто передаём результат дальше
  func passiveComplete(result: Result<UIImage, NetworkError>) {
    assert(Thread.isMainThread)
    if !isCancelled, !isFinished {
      completionHandler?(result)
    }
    finish()
  }

  override func cancel() {
    task?.cancel()
    super.cancel()
  }
}
