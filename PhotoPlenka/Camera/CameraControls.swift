//
//  CameraControls.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 08.04.2022.
//

import UIKit

final class CameraControls: UIView {
    private enum Constants {
        static let rotationDuration: TimeInterval = 0.2
    }
    private let factory: CameraViewFactory
    weak var delegate: CameraControlsDelegate? = nil

    private lazy var buttonStack = factory.makeButtonsStack()
    private lazy var backButton = factory.makeBackButton()
    private(set) lazy var takeButton = factory.makeCameraButton()
    private(set) lazy var modeButton = factory.makeModeButton()

    private lazy var backContainer = factory.contain(button: backButton)
    private lazy var modeContainer = factory.contain(button: modeButton)

    init(factory: CameraViewFactory){
        self.factory = factory
        super.init(frame: .zero)
        addSubviews()
        applyConstraints()
        modeButton.addTarget(self, action: #selector(switchMode), for: .touchUpInside)
        takeButton.addTarget(self, action: #selector(triggerShot), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(triggerBack), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews(){
        buttonStack.addArrangedSubview(backContainer)
        buttonStack.addArrangedSubview(takeButton)
        buttonStack.addArrangedSubview(modeContainer)
        addSubview(buttonStack)
    }

    private func applyConstraints(){
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonStack.topAnchor.constraint(equalTo: topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc func switchMode(){
        delegate?.didChangeState()
    }

    @objc func triggerShot(){
        delegate?.didTriggerShot()
    }

    @objc func triggerBack(){
        delegate?.didTriggerBack()
    }
}

extension CameraControls: CameraUnit {
    func set(state: CompareState) {
        modeButton.setImage(state.icon, for: .normal)
        takeButton.set(state: state.takeButtonState)
    }

    func rotate(_ orientation: UIDeviceOrientation) {
        guard let transform = orientation.rotationTransform else { return }
        UIView.animate(withDuration: Constants.rotationDuration){
            self.backContainer.transform = transform
            self.modeContainer.transform = transform
        }
    }
}

extension UIDeviceOrientation {
    var rotationTransform: CGAffineTransform? {
        switch self {
        case .landscapeLeft: return CGAffineTransform(rotationAngle: .pi/2)
        case .landscapeRight: return CGAffineTransform(rotationAngle: -.pi/2)
        case .portraitUpsideDown: return CGAffineTransform(rotationAngle: .pi)
        case .portrait: return .identity
        default: return nil
        }
    }
}
