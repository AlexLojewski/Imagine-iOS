//
//  PostsOfFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.10.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

enum TableViewDisplayOptions {
    case small
    case normal
}

class PostsOfFactTableViewController: UITableViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var displayOptionButton: DesignableButton!
    
    var fact: Fact?
    var noPostsType: BlankCellType = .postsOfFacts
    var posts = [Post]()
    var needNavigationController = false
    var displayOption: TableViewDisplayOptions = .small
    
    let postHelper = PostHelper()
    let handyHelper = HandyHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.shadowImage = UIImage()
        headerImageView.layer.cornerRadius = 4
        if #available(iOS 13.0, *) {
            headerImageView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            headerImageView.layer.borderColor = UIColor.lightGray.cgColor
        }
        headerImageView.layer.borderWidth = 2
        
        //for small display option
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: "NibBlankCell")
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: "SearchPostCell")
        
        // For normal display
        tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibRepostCell")
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibPostCell")
        tableView.register(UINib(nibName: "LinkCell", bundle: nil), forCellReuseIdentifier: "NibLinkCell")
        tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: "NibThoughtCell")
        tableView.register(UINib(nibName: "YouTubeCell", bundle: nil), forCellReuseIdentifier: "NibYouTubeCell")

        getPosts()
        
        if needNavigationController {
            setDismissButton()
        }
        
        if let fact = fact {
            
            headerLabel.text = fact.title
            descriptionLabel.text = fact.description
            
            if let url = URL(string: fact.imageURL) {
                headerImageView.sd_setImage(with: url, completed: nil)
            } else {
                headerImageView.image = UIImage(named: "FactStamp")
            }
            
            if let user = Auth.auth().currentUser {
                if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                    print("Nicht bei Malte loggen")
                } else {
                    Analytics.logEvent("PostsOfFactsSearched", parameters: [
                        AnalyticsParameterTerm: fact.title
                    ])
                }
            } else {
                Analytics.logEvent("PostsOfFactsSearched", parameters: [
                    AnalyticsParameterTerm: fact.title
                ])
            }
        }
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Constants.imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    func getPosts() {
        
        if let fact = fact {
            self.view.activityStartAnimating()
            
            postHelper.getPostsForFact(factID: fact.documentID) { (posts) in
                self.posts = posts
                self.tableView.reloadData()
                self.view.activityStopAnimating()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            print("Nothing will happen")
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            performSegue(withIdentifier: "showPost", sender: post)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = noPostsType
                
                return cell
            }
        default:
            
            switch displayOption {
            case .normal:
                
                switch post.type {
                case .repost:
                    let identifier = "NibRepostCell"
                    
                    if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                        
                        repostCell.delegate = self
                        repostCell.post = post
                        
                        return repostCell
                    }
                case .picture:
                    let identifier = "NibPostCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .thought:
                    let identifier = "NibThoughtCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .link:
                    let identifier = "NibLinkCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LinkCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .youTubeVideo:
                    let identifier = "NibYouTubeCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? YouTubeCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                default:
                    let identifier = "NibThoughtCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                }
                
            case .small:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPostCell", for: indexPath) as? SearchPostCell {
                    
                    cell.post = post
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            return self.view.frame.height-150
        default:
            
            switch displayOption {
            case .normal:
                var extraHeightForReportView:CGFloat = 0
                
                var heightForRow:CGFloat = 150
                
                let post = posts[indexPath.row]
                let postType = post.type
                
                switch post.report {
                case .normal:
                    extraHeightForReportView = 0
                default:
                    extraHeightForReportView = 24
                }
                
                switch postType {
                case .thought:
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 110+labelHeight+extraHeightForReportView
                case .picture:
                    
                    // Label vergrößern
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    let imageHeight = post.imageHeight
                    let imageWidth = post.imageWidth
                    
                    let ratio = imageWidth / imageHeight
                    var newHeight = self.view.frame.width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    heightForRow = newHeight+105+extraHeightForReportView+labelHeight // 100 weil Höhe von StackView & Rest
                    
                    return heightForRow
                case .link:
                    
                    if post.title.count <= 60 {
                        heightForRow = 200
                    } else if post.title.count <= 80 {
                        heightForRow = 210
                    } else if post.title.count <= 120 {
                        heightForRow = 230
                    } else if post.title.count <= 140 {
                        heightForRow = 245
                    } else if post.title.count <= 160 {
                        heightForRow = 260
                    } else if post.title.count <= 180 {
                        heightForRow = 275
                    }else if post.title.count <= 200 {
                        heightForRow = 290
                    }
                case .repost:
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 390+extraHeightForReportView+labelHeight //525
                    
                case .youTubeVideo:
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 330+labelHeight
                default:
                    return 300
                }
                
                return heightForRow
            case .small:
                return 80
            }
        }
    }
    
    
    @IBAction func displayOptionButtonTapped(_ sender: Any) {
        switch displayOption {
        case .small:
            displayOption = .normal
            displayOptionButton.setImage(UIImage(named: "list-1"), for: .normal)
            
            tableView.reloadData()
        case .normal:
            displayOption = .small
            displayOptionButton.setImage(UIImage(named: "today_apps"), for: .normal)
            
            tableView.reloadData()
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.postOfFactText)
    }
    
    @IBAction func newPostTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "goToNewPost", sender: fact)
        }
    }
    
    //MARK:- Prepare For Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                    postVC.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    postVC.navigationController?.navigationBar.shadowImage = nil
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Fact {
                if let navCon = segue.destination as? UINavigationController {
                    if let factVC = navCon.topViewController as? FactParentContainerViewController {
                        factVC.fact = fact
                        factVC.needNavigationController = true
                    }
                }
            }
        }
        
        if segue.identifier == "goToNewPost" {
            if let fact = sender as? Fact {
                if let navCon = segue.destination as? UINavigationController {
                    if let newPostVC = navCon.topViewController as? NewPostViewController {
                        newPostVC.selectedFact(fact: fact, closeMenu: false)
                        newPostVC.comingFromPostsOfFact = true
                    }
                }
            }
        }
    }
    
    //MARK:- PostCell Delegate
    
}

extension PostsOfFactTableViewController: PostCellDelegate {
    
    func userTapped(post: Post) {
        //Todo: To User
    }
    
    // MARK: Cell Button Tapped
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func thanksTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .thanks, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func wowTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .wow, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func haTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .ha, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func niceTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .nice, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func linkTapped(post: Post) {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    func factTapped(fact: Fact) {
        //nothing has to happen
    }
    
}
