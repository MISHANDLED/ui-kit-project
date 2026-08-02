//
//  BaseTableViewCell.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 02/08/26.
//

import UIKit

class BaseTableViewCell<CellView: BaseView>: UITableViewCell {

    let cellView: CellView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        cellView = CellView(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CellView.ViewModel) {
        cellView.bind(to: viewModel)
    }

    private func setupCellView() {
        contentView.addSubview(cellView)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cellView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
