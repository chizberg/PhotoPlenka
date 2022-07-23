//
//  PhotoPreview.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import AVKit
import UIKit

final class CameraPreview: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  /// Convenience wrapper to get layer as its statically known type.
  var videoPreviewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }

  var session: AVCaptureSession? {
    get { videoPreviewLayer.session }
    set {
      videoPreviewLayer.session = newValue
      videoPreviewLayer.videoGravity = .resizeAspectFill
      newValue?.startRunning()
    }
  }
}
