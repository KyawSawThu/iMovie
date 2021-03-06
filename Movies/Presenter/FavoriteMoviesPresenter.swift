//
//  FavoriteMoviesPresenter.swift
//  Movies
//
//  Created by Jonathan Martins on 09/10/19.
//  Copyright © 2019 Jonathan Martins. All rights reserved.
//

import Foundation

// MARK: - FavoriteMoviesPresenterDelegate
protocol FavoriteMoviesPresenterDelegate:class{

    /// The list of movies to be displayed
    var movies:[Movie] { get set}
    
    /// Binds the view to this presenter
    func bind(to view:FavoriteMoviesViewDelegate, storage:LocalStorageManagerDelegate)

    /// Removes a given movie from the favorute list
    func unfavorite(_ movie:Movie)
    
    /// Filters the the favorite movies by a given term
    func filterMoviesBy(_ term:String)
    
    /// Loads the user's favorite list
    func loadFavoriteList()
}

// MARK: - FavoriteMoviesPresenter
class FavoriteMoviesPresenter{
    
    // MARK: - Variables
    var movies:[Movie] = []
    
    /// The list of favorite movies
    private var favorites:[Movie] = []{
        didSet{
            movies = favorites
        }
    }
    
    /// The number of items in the datasource
    var numberOfItems: Int {
        return movies.count
    }
    
    /// The movie selected by the user
    var selectedMovie:Movie?
    
    /// Sets selected a movie in the datasource
    func selectMovie(at index: Int) {
        selectedMovie = movies[index]
    }
    
    /// Reference to the ViewController's view
    private weak var view:FavoriteMoviesViewDelegate!
    
    /// Manager for the local storage
    private var storage:LocalStorageManagerDelegate!
    
    /// Check the state of the list of the movies and return a specific feedback message
    private func checkFavoriteMoviesDataSourceState(){
        if favorites.isEmpty{
            view.showFeedback(message: "Your favorite list is empty.")
        }
        else if movies.isEmpty{
            view.showFeedback(message: "There are no movies with the filters or search term you typed.")
        }
    }
}

// MARK: - FavoriteMoviesPresenterDelegate
extension FavoriteMoviesPresenter:FavoriteMoviesPresenterDelegate{
 
    func bind(to view: FavoriteMoviesViewDelegate, storage:LocalStorageManagerDelegate) {
        self.view    = view
        self.storage = storage
    }
    
    func loadFavoriteList(){
        favorites = storage.loadFavorites()
        view.updateFavoriteList()
        checkFavoriteMoviesDataSourceState()
    }
    
    func filterMoviesBy(_ term: String) {
        movies = favorites.filter({$0.title!.range(of: term, options: [.diacriticInsensitive, .caseInsensitive]) != nil })
        view.updateFavoriteList()
        checkFavoriteMoviesDataSourceState()
    }
    
    func unfavorite(_ movie: Movie) {
        if storage.isMovieFavorite(movie){
            storage.removeFromFavorite(movie)
            loadFavoriteList()
        }
    }
}
