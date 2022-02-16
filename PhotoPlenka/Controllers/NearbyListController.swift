//
//  NearbyListController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 14.02.2022.
//

import MapKit
import UIKit

final class NearbyListController: UIViewController {
    private enum Constants {
        static var sideInset: CGFloat = 16
        static var controllerCornerRadius: CGFloat = 29
        static var listCornerRadius: CGFloat = 13
        static var cellID = String(describing: PreviewCell.self)
        static var listTitle = "Интересное рядом"
        static var countLimit: Int = 10
    }

    // views
    private let yearSelect = YearSelector()
    private let nearbyList: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = Constants.listCornerRadius
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        return tableView
    }()

    private let backgroundBlur =
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))

    // data
    private var visibleAnnotations = [MKAnnotation]()

    init(mapController: YearSelectorDelegate) {
        super.init(nibName: nil, bundle: nil)
        yearSelect.delegate = mapController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundBlur)
        view.addSubview(yearSelect)
        nearbyList.dataSource = self
        nearbyList.register(PreviewCell.self, forCellReuseIdentifier: Constants.cellID)
        view.addSubview(nearbyList)
        applyConstraints()
    }

    override func viewDidLayoutSubviews() {
        view.layer.cornerRadius = Constants.controllerCornerRadius
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.clipsToBounds = true
        backgroundBlur.frame = view.bounds
    }

    private func applyConstraints() {
        yearSelect.translatesAutoresizingMaskIntoConstraints = false
        nearbyList.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            yearSelect.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.sideInset),
            yearSelect.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.sideInset
            ),
            yearSelect.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.sideInset
            ),
            yearSelect.heightAnchor.constraint(equalToConstant: 50),
        ])

        NSLayoutConstraint.activate([
            nearbyList.topAnchor.constraint(
                equalTo: yearSelect.bottomAnchor,
                constant: Constants.sideInset
            ),
            nearbyList.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.sideInset
            ),
            nearbyList.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.sideInset
            ),
            nearbyList.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension NearbyListController: MapObserver {
    func annotationsDidChange(annotations _: [MKAnnotation], visible: [MKAnnotation]) {
        guard visible.count > Constants.countLimit else {
            visibleAnnotations = visible
            nearbyList.reloadData()
            return
        }
        visibleAnnotations = Array(visible[..<Constants.countLimit])
        nearbyList.reloadData()
    }
}

extension NearbyListController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        visibleAnnotations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
        guard let previewCell = cell as? PreviewCell else { return cell }
        if let photo = visibleAnnotations[indexPath.row] as? Photo {
            previewCell.fillIn(photo)
        }
        if let cluster = visibleAnnotations[indexPath.row] as? Cluster {
            previewCell.fillIn(cluster.photo)
        }
        return cell
    }

    func tableView(_: UITableView, titleForHeaderInSection _: Int) -> String? {
        Constants.listTitle
    }

    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
