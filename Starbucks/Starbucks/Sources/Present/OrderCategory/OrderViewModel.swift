//
//  OrderViewModel.swift
//  Starbucks
//
//  Created by 김상혁 on 2022/05/09.
//

import Foundation
import RxRelay
import RxSwift

protocol OrderViewModelAction {
    var loadCategory: PublishRelay<Void> { get }
    var tappedCategory: BehaviorRelay<Int> { get }
    var tappedMenu: PublishRelay<Int> { get }
}

protocol OrderViewModelState {
    var updateList: PublishRelay<[Category.Group]> { get }
    var reloadList: PublishRelay<Void> { get }
    var selectedCategory: PublishRelay<Int> { get }
    var selectedSubCategory: PublishRelay<Category.Group> { get }
}

protocol OrderViewModelBinding {
    func action() -> OrderViewModelAction
    func state() -> OrderViewModelState
}

typealias OrderViewModelProtocol = OrderViewModelBinding

class OrderViewModel: OrderViewModelAction, OrderViewModelState, OrderViewModelBinding {
    
    enum Contants {
        static let firstCategory = Category.GroupType.beverage
    }
    
    func action() -> OrderViewModelAction { self }
    
    let loadCategory = PublishRelay<Void>()
    let tappedCategory = BehaviorRelay<Int>(value: Contants.firstCategory.index)
    let tappedMenu = PublishRelay<Int>()
    
    func state() -> OrderViewModelState { self }
    
    let updateList = PublishRelay<[Category.Group]>()
    let reloadList = PublishRelay<Void>()
    let selectedCategory = PublishRelay<Int>()
    let selectedSubCategory = PublishRelay<Category.Group>()
    
    @Inject(\.starbucksRepository) private var starbucksRepository: StarbucksRepository
    
    private let disposeBag = DisposeBag()
    private var categoryMenu: [[Category.Group]] = [[]]
    
    init() {
        
        let requestCategory = action().loadCategory
            .withUnretained(self)
            .flatMapLatest { model, _ in
                model.starbucksRepository.requestCategory()
            }
            .share()
        
        requestCategory
            .compactMap { result in result.value }
            .map { groups in
                groups.reduce(into: [[Category.Group]].init(repeating: [], count: 3)) { category, group in
                    category[group.category.index].append(group)
                }
            }
            .withUnretained(self)
            .do { model, groups in
                let index = model.tappedCategory.value
                model.categoryMenu = groups
                model.updateList.accept(groups[index])
                model.selectedCategory.accept(index)
            }
            .map { _ in }
            .bind(to: reloadList)
            .disposed(by: disposeBag)
        
        Observable
            .merge(
                requestCategory.compactMap { $0.error }
            )
            .bind(onNext: {
                //TODO: error 처리
            })
            .disposed(by: disposeBag)
        
        tappedCategory
            .withUnretained(self)
            .map { model, index in model.categoryMenu[index] }
            .withUnretained(self)
            .do { model, groups in model.updateList.accept(groups) }
            .map { _ in }
            .bind(to: reloadList)
            .disposed(by: disposeBag)
        
        tappedMenu
            .withUnretained(self)
            .map { model, index in
                model.categoryMenu[model.tappedCategory.value][index]
            }
            .bind(to: selectedSubCategory)
            .disposed(by: disposeBag)
    }
}
