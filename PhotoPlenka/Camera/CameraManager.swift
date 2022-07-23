//
//  Camera Manager.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import AVKit

final class CameraManager {
  private var output = AVCapturePhotoOutput()

  func authorize(
    success: @escaping () -> Void,
    failure: @escaping () -> Void
  ) {
    let access = AVCaptureDevice.authorizationStatus(for: .video)
    switch access {
    case .authorized:
      success()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
        switch granted {
        case true: success()
        case false: failure()
        }
      })
    case .restricted:
      failure()
    case .denied:
      failure()
    @unknown default:
      failure()
    }
  }

  func makePreview(success: @escaping (CameraPreview) -> Void, failure: @escaping () -> Void) {
    authorize(success: { [weak self] in
      guard let self = self else { return }
      let preview = CameraPreview()
      preview.session = self.makeSessionWithAccess()
      success(preview)
    }, failure: {
      failure()
    })
  }

  func makeSessionWithAccess() -> AVCaptureSession? {
    guard let device = AVCaptureDevice.default(for: .video) else { return nil }
    guard let input = try? AVCaptureDeviceInput(device: device) else { return nil }
    let captureSession = AVCaptureSession()
    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }
    if captureSession.canAddOutput(output) {
      captureSession.addOutput(output)
    }
    return captureSession
  }

  func takePhoto(delegate: AVCapturePhotoCaptureDelegate) {
    let photoSettings = AVCapturePhotoSettings()
    if let previewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
      photoSettings
        .previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewType]
      output.capturePhoto(with: photoSettings, delegate: delegate)
    }
  }
}
