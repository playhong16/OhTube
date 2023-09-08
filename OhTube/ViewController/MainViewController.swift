//
//  MainViewController.swift
//  OhTube
//
//  Created by t2023-m0056 on 2023/09/04.
//
// 해야 할 일
// 1. 페이지 네이션 구현



import UIKit

final class MainViewController: UIViewController {
  
    var youtubeArray: [Video] = []

    var searchResultArray: [Video] = []
    
    var category: [String] = ["전체","예능","스포츠","음악","게임","영화","재미"]
    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "검색어를 입력해주세요"
        searchController.searchBar.setValue("취소", forKey: "cancelButtonText")
        searchController.searchBar.tintColor = .black
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .none
        return searchController
    }()
    
    var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    let categoryCollectionHorizontal = UICollectionViewFlowLayout()
    
    lazy var categoryCollectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collection.showsHorizontalScrollIndicator = false
        categoryCollectionHorizontal.scrollDirection = .horizontal
        collection.collectionViewLayout = categoryCollectionHorizontal
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewSetting()
        naviBarSetting()
        searchBarSetting()
        collectionMakeUI()
        networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.all)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryCollectionView.reloadData()
    }
    
    private func naviBarSetting() {
        self.title = "Video Search"
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .none
        self.navigationItem.hidesSearchBarWhenScrolling = false
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func searchBarSetting() {
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func collectionViewSetting() {
        collectionView.dataSource = self
        collectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate = self
        collectionView.tag = 1
        categoryCollectionView.tag = 2
    }
    
    private func collectionMakeUI() {
        view.addSubview(categoryCollectionView)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 40),
            
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: self.categoryCollectionView.bottomAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }
    func networkingMakeUI(categoryId: String) {
        NetworkManager.shared.fetchVideo(category: categoryId) { result in
            switch result {
            case .success(let tubedata):
                
                print("데이터 잘 받음")
                self.youtubeArray = tubedata
                
                dump(self.youtubeArray)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("데이터 받아오기 에러 ")
                print(error.localizedDescription)
            }
        }
    }
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

extension MainViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView.tag == 1 {
            return isFiltering() ? searchResultArray.count : youtubeArray.count
        } else {
            return category.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView.tag == 2 { //2: 카테고리 컬렉션
            
            categoryCollectionView.register(MainViewCategoryCollectionViewCell.self, forCellWithReuseIdentifier: "MainViewCategoryCollectionViewCell")
            
            let categoryCell = self.categoryCollectionView.dequeueReusableCell(withReuseIdentifier: Cell.mainViewCategoryIdentifier, for: indexPath) as! MainViewCategoryCollectionViewCell
            
            categoryCell.categoryLabel.text = category[indexPath.row]
            return categoryCell
            
        } else if collectionView.tag == 1 { // 1: 유튜브 컬렉션
            
            collectionView.register(MainCollectionViewCell.self, forCellWithReuseIdentifier: Cell.mainViewIdentifier)
            
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: Cell.mainViewIdentifier, for: indexPath) as! MainCollectionViewCell
            
            if isFiltering() { //검색 시
                let url = URL(string: searchResultArray[indexPath.row].thumbNail)
                cell.videoThumbnailImage.load(url: url!)
                cell.channelImage.load(url: url!)
                cell.videoTitleLabel.text = searchResultArray[indexPath.row].title
                cell.channelNameLabel.text = searchResultArray[indexPath.row].channelId
                cell.videoViewCountLabel.text = "\(searchResultArray[indexPath.row].formatViewCount) 조회"
                cell.videoDateLabel.text = searchResultArray[indexPath.row].uploadDateString
                return cell
                
            } else if !isFiltering() {
                let url = URL(string: youtubeArray[indexPath.row].thumbNail)
                cell.videoThumbnailImage.load(url: url!)
                cell.channelImage.load(url: url!)
                cell.videoTitleLabel.text = youtubeArray[indexPath.row].title
                cell.channelNameLabel.text = youtubeArray[indexPath.row].channelId
                cell.videoViewCountLabel.text = "\(youtubeArray[indexPath.row].formatViewCount) 조회"
                cell.videoDateLabel.text = youtubeArray[indexPath.row].uploadDateString
                return cell
            }

        }
        return UICollectionViewCell()
    }
}


extension MainViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 1 {
            if isFiltering() {
                let collectionViewWidth = collectionView.bounds.width
                let collectionViewHeight = collectionView.bounds.height
                return CGSize(width: collectionViewWidth, height: (collectionViewHeight + 40)/2)
            } else {
                let collectionViewWidth = collectionView.bounds.width
                let collectionViewHeight = collectionView.bounds.height
                return CGSize(width: collectionViewWidth, height: (collectionViewHeight + 40)/2)
            }
        } else if collectionView.tag == 2 {
            let category = category[indexPath.item]
            let label = UILabel()
            label.text = category
            label.sizeToFit()
            let labelSize = label.frame.size
            return CGSize(width: labelSize.width + 20, height: labelSize.height + 10) // Add some padding
        }
        return CGSize(width: 0, height: 0)
    }
}

extension MainViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView.tag == 1 {
            let selectedData = youtubeArray[indexPath.item]
            let detailViewController = DetailViewController()
            detailViewController.selectedVideo = selectedData
            self.navigationController?.pushViewController(detailViewController, animated: true)
            
        } else if collectionView.tag == 2 {
            let selectedCategory = category[indexPath.item]
            switch selectedCategory {
            case "전체":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.all)
            case "예능":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.entertainment)
            case "스포츠":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.sport)
            case "음악":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.music)
            case "게임":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.gaming)
            case "영화":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.filmAndAnimation)
            case "재미":
                networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.comedy)
            default:
                break
            }
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let contentOffsetY = scrollView.contentOffset.y
//        
//        // collectionView의
//        // content size(화면에 보이지 않는 모든 collectionView영역을 포함하는 size)
//        let collectionViewContentSizeY = self.collectionView.contentSize.height
//        
//        // pagination을 하고 싶은 y 좌표는 collectionView의 content size의 0.5 지점
//        let paginationY = collectionViewContentSizeY * 0.
//        
//        // contentOffsetY가
//        // 전체 CollectionView의 contentSizeY의 반을 넘어가면
//        // if 문 내부 코드 실행!!
//        if contentOffsetY > collectionViewContentSizeY - paginationY {
//            // 서버에서 다음 페이지 GET
//            networkingMakeUI(categoryId: YouTubeApiVideoCategoryId.all)
//        }
    }
}

extension MainViewController: UISearchBarDelegate, UISearchResultsUpdating {
    

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {// 검색창이 비었으면 다보여줌
            searchResultArray = youtubeArray
        } else {// 검색결과값
            searchResultArray = youtubeArray.filter { $0.title.lowercased().contains(searchText)}
        }
        self.collectionView.reloadData()
    }
    
    //검색창 클릭 시 키보드 올리기
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(true, animated: true)
    }
    // 캔슬 버튼
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    // 캔슬버튼 보이게 하기
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
}


extension UIImageView { 
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
