//
//  DatePicker.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 07/04/26.
//

import UIKit

protocol DatePickerViewDataSource: BaseViewModel {}

final class DatePickerViewModel: DatePickerViewDataSource {}

final class DatePickerView<VM: DatePickerViewDataSource>: UIView {
    
    private let button: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Pick Date & Time", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .dateAndTime
        dp.preferredDatePickerStyle = .wheels
        dp.translatesAutoresizingMaskIntoConstraints = false
        dp.isHidden = true
        return dp
    }()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .white
        
        addSubview(button)
        addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            datePicker.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 16),
            datePicker.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    @objc private func didTapButton() {
        datePicker.isHidden.toggle()
    }
}

extension DatePickerView: BaseView {
    typealias ViewModel = VM
    
    func bind(to viewModel: VM) {}
}
