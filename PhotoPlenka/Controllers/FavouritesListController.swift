//
//  FavouritesListController.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 12.04.2022.
//

import UIKit

final class FavouritesListController: UIViewController {
    private enum Constants {
        static let sideInset: CGFloat = 16
        static let buttonSize: CGSize = .init(width: 40, height: 40)
        static let controllerCornerRadius: CGFloat = 29
        static let maskedCorners: CACornerMask = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        static let cellID = String(describing: PreviewCell.self)
        static let listTitle = "Избранное"
        static let countLimit: Int = 10
    }

    //data
    private var favourites: [Photo]

    //views
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = nil
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.clipsToBounds = false
        return tableView
    }()
    // I don't like the way this bar looks
    // I should probably make my own one
    private lazy var navBar: UINavigationBar = {
        let bar = UINavigationBar(frame: .zero)
        bar.isTranslucent = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        let topItem = UINavigationItem(title: Constants.listTitle)
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeButtonTapped))
        topItem.rightBarButtonItem = cancelItem
        bar.setItems([topItem], animated: true)
        return bar
    }()

    init(){
        self.favourites = FavouritesProvider.shared.favourites ?? []
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PreviewCell.self, forCellReuseIdentifier: Constants.cellID)
        tableView.multicastingDelegate.addDelegate(self)
        tableView.dataSource = self
        view.layer.cornerRadius = Constants.controllerCornerRadius
        view.layer.maskedCorners = Constants.maskedCorners
        view.clipsToBounds = true
        view.backgroundColor = nil
        view.addSubview(tableView)
        view.addSubview(navBar)
        view.insertSubview(backgroundView, at: 0)
        applyConstraints()
    }

    override func viewDidLayoutSubviews() {
        backgroundView.frame = view.bounds
    }

    func reloadData(){
        favourites = FavouritesProvider.shared.favourites ?? []
        tableView.reloadData()
    }

    private func applyConstraints(){
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.sideInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.sideInset),
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func closeButtonTapped(){
        self.dismiss(animated: true)
    }
}

extension FavouritesListController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favourites.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
        guard let previewCell = cell as? PreviewCell else { return cell }
        previewCell.fillIn(favourites[indexPath.row])
        return previewCell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photo = favourites[indexPath.row]
        let detailsController = PhotoDetailsController(cid: photo.cid, detailsProvider: PhotoDetailsProvider.init(networkService: NetworkService()))
        present(detailsController, animated: true)
    }
}
