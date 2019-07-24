//
//  FeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage

class FeedTableViewController: BaseFeedTableViewController, UISearchControllerDelegate {
    

    let db = Firestore.firestore()
    lazy var postHelper = PostHelper()      // Lazy or it calls Firestore before AppDelegate.swift
    
    let searchController = UISearchController(searchResultsController: SearchTableViewController())
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    private var invitationCount = 0
    
    let smallNumberForImagineBlogButton: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 20, y: 0, width: 12, height: 12))
        label.backgroundColor = .red
        label.clipsToBounds = true
        label.layer.cornerRadius = 6
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        label.text = String(1)
        
        return label
    }()
    
    let smallNumberForInvitationRequest: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 25, y: 0, width: 14, height: 14))
        label.backgroundColor = .red
        label.clipsToBounds = true
        label.layer.cornerRadius = 7
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchTableVC = SearchTableViewController()
        searchTableVC.tableView.delegate = self
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Durchsuche Imagine"
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.scopeButtonTitles = ["Posts", "User", "Events"]
        searchController.searchBar.delegate = self

        if #available(iOS 11.0, *) {
            // For iOS 11 and later, place the search bar in the navigation bar.
            self.navigationItem.searchController = searchController
        } else {
            // For iOS 10 and earlier, place the search controller's search bar in the table view's header.
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
        
        // Initiliaze ScreenEdgePanRecognizer
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self,
                                                                action: #selector(BarButtonItemTapped))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        // Others
        loadBarButtonItem()
        
        getPosts(getMore: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
//        // Restore the searchController's active state.
//        if restoredState.wasActive {
//            searchController.isActive = restoredState.wasActive
//            restoredState.wasActive = false
//
//            if restoredState.wasFirstResponder {
//                searchController.searchBar.becomeFirstResponder()
//                restoredState.wasFirstResponder = false
//            }
//        } Aus dem apple tutorial
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkForInvitations()
        
        handyHelper.getChats { (chatList) in
            self.handyHelper.getCountOfUnreadMessages(chatList: chatList, unreadMessages: { (count) in
                if let items = self.tabBarController?.tabBar.items {
                    let tabItem = items[1]
                    if count != 0 {
                        tabItem.badgeValue = String(count)
                    }
                }
            })
        }
    }
    
    lazy var sideMenu: SideMenu = {
        let sideMenu = SideMenu()
        sideMenu.FeedTableView = self
        return sideMenu
    }()
    
    lazy var newsMenu: NewsOverviewMenu = {
        let nM = NewsOverviewMenu()
        nM.feedTableVC = self
        return nM
    }()
    
    func checkForInvitations() {
        if let user = Auth.auth().currentUser {
            let friendsRef = db.collection("Users").document(user.uid).collection("friends").whereField("accepted", isEqualTo: false)
            
            friendsRef.getDocuments { (snap, err) in
                if let err = err {
                    print("We have an error: \(err.localizedDescription)")
                } else {
                    self.invitationCount = snap!.documents.count
                    
                    if self.invitationCount != 0 {
                        self.smallNumberForInvitationRequest.text = String(self.invitationCount)
                        self.smallNumberForInvitationRequest.isHidden = false
                    } else {
                        self.smallNumberForInvitationRequest.isHidden = true
                    }
                }
            }
        }
    }
    
    @objc override func getPosts(getMore:Bool) {
        /*
         If "getMore" is true, you want to get more Posts, or the initial batch of 20 Posts, if not you want to refresh the current feed
         */
        
        postHelper.getPosts(getMore: getMore) { (posts) in
            
                
                print("Jetzt haben wir \(posts.count) posts")
                self.posts = posts
                self.tableView.reloadData()
                
                self.postHelper.getEvent(completion: { (post) in
                    self.posts.insert(post, at: posts.count-12)
                    self.tableView.reloadData()
                })
                
                // remove ActivityIndicator incl. backgroundView
                self.actInd.stopAnimating()
                self.container.isHidden = true
                
                self.refreshControl?.endRefreshing()
            }
    }
    
    // MARK: - TableViewStuff
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var post = Post()
        
        // Check to see which table view cell was selected.
        if tableView === self.tableView {
            
            post = posts[indexPath.row]
        } else {
            if let searchVC = self.searchController.searchResultsController as? SearchTableViewController {
                print("Immerhin hier")

                if let postResults = searchVC.postResults {
                    print("Hier vielleicht")
                    post = postResults[indexPath.row]
                }
            }
        }
        performSegue(withIdentifier: "showPost", sender: post)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 &&
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 3 {
            print("Ende fast erreicht!")
            
            self.getPosts(getMore: true)
            // Wenn ich wirklich beim letzten bin habe ich noch keine Lösung
        }
    }
 
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    print("Der Post wird übergeben in prepare: \(chosenPost.documentID)")
                    postVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "meldenSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
                    
                }
            }
        }
        if segue.identifier == "goToLink" {
            if let chosenPost = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = chosenPost
                    
                }
            }
        }
    }
    
    func goToUser(user: User) {
        searchController.isActive = false
    }
    
    func goToPost(post:Post) {
        searchController.isActive = false
        searchController.searchResultsController?.dismiss(animated: true, completion: {
            self.performSegue(withIdentifier: "showPost", sender: post)
        })
    }
    
    
    @objc func imagineSignTapped() {
        
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        self.newsMenu.showView(navBarHeight: navigationBarHeight)
        self.smallNumberForImagineBlogButton.isHidden = true
    }
    
    // MARK: - NavigationBarItem
    
    func loadBarButtonItem() {
        DispatchQueue.main.async {
            
            let searchButton = DesignableButton(type: .custom)
            searchButton.setImage(UIImage(named: "search"), for: .normal)
            searchButton.addTarget(self, action: #selector(self.searchBarTapped), for: .touchUpInside)
            searchButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            searchButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
            
            let imagineButton = DesignableButton(type: .custom)
            imagineButton.setImage(UIImage(named: "peace-sign"), for: .normal)
            imagineButton.addTarget(self, action: #selector(self.imagineSignTapped), for: .touchUpInside)
            imagineButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imagineButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
            
            imagineButton.addSubview(self.smallNumberForImagineBlogButton)
            
            let searchBarButton = UIBarButtonItem(customView: searchButton)
            let imagineBarButton = UIBarButtonItem(customView: imagineButton)
            self.navigationItem.rightBarButtonItems = [searchBarButton, imagineBarButton]
            
            
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalToConstant: 35).isActive = true
            view.widthAnchor.constraint(equalToConstant: 35).isActive = true

            //create new Button for the profilePictureButton
            let button = DesignableButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            button.addTarget(self, action: #selector(self.BarButtonItemTapped), for: .touchUpInside)
            button.layer.masksToBounds = true
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.borderWidth =  0.1
            button.layer.borderColor = UIColor.black.cgColor
            
            
            // Wenn jemand eingeloggt ist:
            if let user = Auth.auth().currentUser {
                if let url = user.photoURL{
                    do {
                        let data = try Data(contentsOf: url)
                        
                        if let image = UIImage(data: data) {
                            
                            
                            //set image for button
                            button.setImage(image, for: .normal)
                            button.imageView?.contentMode = .scaleAspectFill
                            button.widthAnchor.constraint(equalToConstant: 35).isActive = true
                            button.heightAnchor.constraint(equalToConstant: 35).isActive = true
                            button.layer.cornerRadius = button.frame.width/2
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                } else {    // Wenn noch kein Bild ausgewählt wurde!
                    //set image for button
                    button.setImage(UIImage(named: "default-user"), for: .normal)
                    button.widthAnchor.constraint(equalToConstant: 35).isActive = true
                    button.heightAnchor.constraint(equalToConstant: 35).isActive = true
                    button.layer.cornerRadius = button.frame.width/2
                }
                
                view.addSubview(button)
                view.addSubview(self.smallNumberForInvitationRequest)
                self.smallNumberForInvitationRequest.isHidden = true
                
            } else {    // Wenn niemand eingeloggt
                
                button.widthAnchor.constraint(equalToConstant: 50).isActive = true
                button.heightAnchor.constraint(equalToConstant: 25).isActive = true
                button.layer.cornerRadius = 5
                
                button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                button.setTitle("Log-In", for: .normal)
                button.backgroundColor = UIColor(red:0.68, green:0.77, blue:0.90, alpha:1.0)
            }
            
            let barButton = UIBarButtonItem(customView: view)
            self.navigationItem.leftBarButtonItem = barButton
            
            self.checkForInvitations()
        }
    }
    
    func sideMenuButtonTapped(whichButton: SideMenuButton) {
        
        switch whichButton {
        case .toUser:
            //If not logged in...
            if Auth.auth().currentUser == nil {
                performSegue(withIdentifier: "toLogInSegue", sender: nil)
            } else {
                performSegue(withIdentifier: "toUserSegue", sender: nil)
            }
        case .toFriends:
            performSegue(withIdentifier: "toFriendsSegue", sender: nil)
        case .toSavedPosts:
            performSegue(withIdentifier: "toSavedPosts", sender: nil)
        default:
            print("nothing happens")
        }
        
    }
    
    @objc func searchBarTapped() {
        // Show search bar
        self.searchController.isActive = true   // Not perfekt but works
//        navigationItem.hidesSearchBarWhenScrolling = false
//        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    @objc func BarButtonItemTapped() {
        sideMenu.showSettings()
        sideMenu.checkInvitations(invites: self.invitationCount)
    }
    
}


extension FeedTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let post = posts[indexPath.row]

            if let _ = imageCache.object(forKey: post.imageURL as NSString) {
                print("Wurde schon gecached")
            } else {
                if let url = URL(string: post.imageURL) {
                    print("Prefetchen neues Bild: \(post.title)")
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: url)

                        DispatchQueue.main.async {
                            if let data = data {
                                if let image = UIImage(data: data) {
                                    self.imageCache.setObject(image, forKey: post.imageURL as NSString)
                            }
                        }
                    }
                }
            }
            }
        }
    }
}



extension FeedTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.selectedScopeButtonIndex
        
        if searchBar.text! != "" {
            searchTheDatabase(searchText: searchBar.text!, searchScope: scope)
        } else {
            // Clear the searchTableView
            if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                resultsController.postResults = nil
                resultsController.userResults = nil
                resultsController.tableView.reloadData()
            }
        }
        
        
    }
    
    func searchTheDatabase(searchText: String, searchScope: Int) {
        var postResults = [Post]()
        var userResults = [User]()
        
        switch searchScope {
        case 0: // Search Posts
            let titleRef = db.collection("Posts").whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)z").limit(to: 10)
            
            titleRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        let post = Post()
                        let docData = document.data()
                        
                        if let title = docData["title"] as? String, let type = docData["type"] as? String {
                            let imageURL = docData["imageURL"] as? String
                            let imageHeight = docData["imageHeight"] as? Double
                            let imageWidth = docData["imageWidth"] as? Double
                            post.title = title
                            post.documentID = document.documentID
                            post.imageURL = imageURL ?? ""
                            if let postType = self.handyHelper.setPostType(fetchedString: type) {
                                post.type = postType
                            }
                            post.imageWidth = CGFloat(imageWidth ?? 0)
                            post.imageHeight = CGFloat(imageHeight ?? 0)
                            
                            postResults.append(post)
                            
                            
                            }
                        }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.postResults = nil
                        resultsController.postResults = postResults
                        resultsController.userResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            
        case 1: // Search Users
            let fullNameRef = db.collection("Users").whereField("full_name", isGreaterThan: searchText).whereField("full_name", isLessThan: "\(searchText)z").limit(to: 2)
            
            fullNameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        let userIsAlreadyFetched = userResults.contains { $0.userUID == document.documentID }
                        if userIsAlreadyFetched {   // Check if we got the user in on of the other queries
                            continue
                        }
                        
                        let user = User()
                        let docData = document.data()
                        
                        if let name = docData["name"] as? String, let surname = docData["surname"] as? String, let imageURL = docData["profilePictureURL"] as? String {
                            user.name = name
                            user.surname = surname
                            user.userUID = document.documentID
                            user.imageURL = imageURL
                            
                            userResults.append(user)
                            
                        }
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            let nameRef = db.collection("Users").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)z").limit(to: 2)
            
            nameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        let userIsAlreadyFetched = userResults.contains { $0.userUID == document.documentID }
                        if userIsAlreadyFetched { // Check if we got the user in on of the other queries
                            continue
                        }
                        
                        let user = User()
                        let docData = document.data()
                        
                        if let name = docData["name"] as? String, let surname = docData["surname"] as? String, let imageURL = docData["profilePictureURL"] as? String {
                            user.name = name
                            user.surname = surname
                            user.userUID = document.documentID
                            user.imageURL = imageURL
                            
                            userResults.append(user)
                            
                        }
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            let surnameRef = db.collection("Users").whereField("surname", isGreaterThan: searchText).whereField("surname", isLessThan: "\(searchText)z").limit(to: 2)
            
            surnameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        let userIsAlreadyFetched = userResults.contains { $0.userUID == document.documentID }
                        if userIsAlreadyFetched { // Check if we got the user in on of the other queries
                            continue
                        }
                        
                        let user = User()
                        let docData = document.data()
                        
                        if let name = docData["name"] as? String, let surname = docData["surname"] as? String, let imageURL = docData["profilePictureURL"] as? String {
                            user.name = name
                            user.surname = surname
                            user.userUID = document.documentID
                            user.imageURL = imageURL
                            
                            userResults.append(user)
                            
                        }
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
        case 2: // Search Topics
            print("Looking for Topics")
        default:
            return
        }
        
        
    }
    
    
}

extension FeedTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if let text = searchBar.text {
            searchTheDatabase(searchText: text, searchScope: selectedScope)
        }
    }
}