//
//  OrderCategoryViewController.swift
//  Starbucks
//
//  Created by seongha shin on 2022/05/09.
//

import RxAppState
import RxCocoa
import RxSwift
import SnapKit
import UIKit

class OrderCategoryViewController: UIViewController {
    
    let test = UIView()
    
    private let tableSectionHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CategoryTableViewCell.self, forCellReuseIdentifier: CategoryTableViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.contentInset.top = 0
        return tableView
    }()
    
    private let categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        return stackView
    }()
    
    private let categoryButtons: [UIButton] = {
        Category.GroupType.allCases.map {
            let button = UIButton()
            button.setTitle($0.name, for: .normal)
            button.setTitleColor(.black, for: .selected)
            button.setTitleColor(.systemGray, for: .normal)
            return button
        }
    }()
    
    private let categoryViewBar: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private var tableViewDataSource = OrderTableViewDataSource()
    private let viewModel: OrderViewModelProtocol
    private let disposeBag = DisposeBag()
    
    init(viewModel: OrderViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        bind()
        attribute()
        layout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        rx.viewDidLoad
            .bind(to: viewModel.action().loadCategory)
            .disposed(by: disposeBag)
        
        rx.viewWillAppear
            .withUnretained(self)
            .bind(onNext: { vc, _ in
                vc.navigationController?.navigationBar.prefersLargeTitles = true

                let appearance = UINavigationBarAppearance()
                appearance.backgroundColor = .white
                appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
                appearance.shadowColor = .clear

                vc.navigationController?.navigationBar.tintColor = .black
                //기본상태( 스크롤 있는 경우 아래로 이동했을 때 )
                vc.navigationController?.navigationBar.standardAppearance = appearance
                //가로화면으로 볼 때
                vc.navigationController?.navigationBar.compactAppearance = appearance
                //스크롤의 최 상단일 때
                vc.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            })
            .disposed(by: disposeBag)
        
        viewModel.state().updateList
            .bind(onNext: tableViewDataSource.update)
            .disposed(by: disposeBag)
        
        viewModel.state().reloadList
            .bind(onNext: tableView.reloadData)
            .disposed(by: disposeBag)
        
        viewModel.state().selectedCategory
            .bind(onNext: { selectIndex in
                self.categoryButtons.enumerated().forEach { index, button in
                    button.isSelected = index == selectIndex
                }
            })
            .disposed(by: disposeBag)
        
        categoryButtons.enumerated().forEach { index, button in
            button.rx.tap
                .map { _ in index }
                .bind(to: viewModel.action().tappedCategory)
                .disposed(by: disposeBag)
        }
        
        viewModel.state().selectedSubCategory
            .withUnretained(self)
            .bind(onNext: { model, subCategory in
                let viewModel = OrderListViewModel(subCategory: subCategory.groupId, title: subCategory.title)
                let orderListVC = OrderListViewController(viewModel: viewModel)
                model.navigationItem.backButtonTitle = ""
                model.navigationController?.pushViewController(orderListVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func attribute() {
        title = "Order"
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = tableViewDataSource
    }
    
    private func layout() {
        view.addSubview(tableView)
        
        tableSectionHeaderView.addSubview(categoryStackView)
        tableSectionHeaderView.addSubview(categoryViewBar)
        categoryButtons.forEach {
            categoryStackView.addArrangedSubview($0)
        }
        
        categoryStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.trailing.equalTo(categoryButtons[categoryButtons.count - 1])
            $0.leading.equalToSuperview().offset(20)
        }
        
        categoryViewBar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

extension OrderCategoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableSectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.action().tappedMenu.accept(indexPath.item)
    }
}
