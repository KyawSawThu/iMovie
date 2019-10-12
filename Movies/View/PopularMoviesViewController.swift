//
//  PopularMoviesViewController.swift
//  Movies
//
//  Created by Jonathan Martins on 10/10/19.
//  Copyright © 2019 Jonathan Martins. All rights reserved.
//

import UIKit

// MARK: - PopularMoviesViewDelegate
protocol PopularMoviesViewDelegate:class{
    
    /// Displays the loading on the view
    func showLoading()
    
    /// Hides the loading on the view
    func hideLoading()
    
    /// Shows  a feedback message
    func showFeedback(message:String)
    
    /// Updates the list of movies
    func updateMoviesList()
    
    /// Shows or hides the "RemoveFilters" button
    func showRemoveFiltersButton(_ show:Bool)
}

// MARK: - PopularMoviesViewController
class PopularMoviesViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var buttonRemoveFilter:UIButton!
    
    // MARK: - Variables
    // Controls if the list is loading more items
    private var isLoadingMore = false

    // Controls the Scroll's last position
    private var lastOffset: CGFloat = 0.0

    // Indicates if it's the first time loading the app
    private var firstTime = true
    
    // MARK: - Constants
    /// The RefreshControl that indicates when the list is updating
    private let refreshControl:UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .appColor(.primaryColor)
        return refreshControl
    }()
    
    // The presente responsible for the logic of this ViewController
    private let presenter = PopularMoviesPresenter()
    
    /// StorageManager to inject our service
    private let storage = LocalStorageManager()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.bind(to: self, service: MovieService(), storage: storage)
        setupViews()
        presenter.getMovies()
    }
    
    // MARK: - Setup
    /// Sets up the collectionView
    private func setupViews(){
        self.title = "Popular Movies"
        
        collectionView.delegate   = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        collectionView.registerCell(from: MovieCell.self)
        collectionView.backgroundColor = .appColor(.secondaryColor)
        collectionView.contentOffset = CGPoint(x:0, y:-refreshControl.frame.size.height)
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        
        buttonRemoveFilter.addTarget(self, action: #selector(hideFilterButton), for: .touchUpInside)
        
        let search = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(openSearchController))
        let filter = UIBarButtonItem(image: UIImage(named: "icon_filter"), style: .plain, target: self, action: #selector(openFilterController))
        
        navigationItem.rightBarButtonItems = [search, filter]
    }
}

// MARK: - Actions
extension PopularMoviesViewController{
    
    /// Action to trigger the pull to refresh
    @objc private func refreshAction(){
        presenter.getMovies()
    }
    
    /// Opens the FilterController
    @objc private func openSearchController(){
        performSegue(to:.search)
    }
    
    /// Opens the FilterController
    @objc private func openFilterController(){
        performSegue(to:.filter)
    }
    
    /// Clears all filters and hides the "Remove Filter" button
    @objc private func hideFilterButton(){
        presenter.clearFilters()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PopularMoviesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.size.width/3.4, height: view.bounds.size.height/3)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 24
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
    }
}

// MARK: - UICollectionViewDelegate
extension PopularMoviesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.getCell(from: MovieCell.self, at: indexPath)
        let movie      = presenter.itemFor(index: indexPath.row)
        let isFavorite = storage.isMovieFavorite(movie)
        
        cell.setupCell(movie: movie, isFavorite: isFavorite)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenter.selectMovie(at: indexPath.row)
        performSegue(to:.movieDetail)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailMovieViewController{
            if let movie = presenter.selectedMovie{
                detailViewController.setup(with: movie)
            }
        }
        else if let navigation = segue.destination as? UINavigationController{
            if let filterViewController = navigation.topViewController as? FilterViewController{
                filterViewController.delegate = self
            }
        }
    }
}

// MARK: - ScrollViewDelegate
extension PopularMoviesViewController{
    
    // Load more items when the collectionView's scrolls reach
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationItem.searchController?.searchBar.endEditing(true)
        if scrollView == collectionView{
            
            let contentOffset = scrollView .contentOffset.y
            let maximumOffset = (scrollView.contentSize.height - scrollView.frame.size.height)
            
            // Checks if it is the end of the scroll
            if(contentOffset >= maximumOffset){
                if(!isLoadingMore){
                    isLoadingMore = true
                    presenter.currentPage+=1
                    presenter.getMovies(page: presenter.currentPage)
                    print("Loading more movies from page \(presenter.currentPage)...")
                }
            }
        }
    }
}

// MARK: - FilterDelegate
extension PopularMoviesViewController:FilterDelegate{
    
    func didSelectFilter(_ filter: Filter) {
        showRemoveFiltersButton(true)
        presenter.filter = filter
        presenter.getMovies()
    }
}

// MARK: - PopularMoviesViewDelegate
extension PopularMoviesViewController:PopularMoviesViewDelegate{
    
    func showRemoveFiltersButton(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.buttonRemoveFilter.isHidden = !show
        }
    }
    
    func updateMoviesList() {
        isLoadingMore = false
        collectionView.reloadData()
        collectionView.hideEmptyMessage()
    }
    
    func showLoading() {
        refreshControl.beginRefreshing()
    }
    
    func hideLoading() {
        refreshControl.endRefreshing()
    }
    
    func showFeedback(message: String) {
        collectionView.setEmptyView(title: "Ops!", message: message)
    }
}

