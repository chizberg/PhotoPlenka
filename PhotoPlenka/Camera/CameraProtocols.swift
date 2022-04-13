//
//  CameraProtocols.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

//протокол, используемый для View на экране сравнения (камеры)
//на момент написания ими являются CompareContent и CameraControls
protocol CameraUnit {
    func set(state: CompareState)
    func rotate(_ orientation: UIDeviceOrientation)
}

protocol CameraControlsDelegate: AnyObject {
    func didTriggerShot()
    func didChangeState()
    func didTriggerBack()
}
