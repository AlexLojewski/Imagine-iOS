//
//  RecentTopicsCollectionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol RecentTopicCellDelegate {
    func topicTapped(fact: Fact)
}

class RecentTopicsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var facts = [Fact]()
    let identifier = "SmallTopicCell"
    let placeHolderIdentifier = "PlaceHolderCell"
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var delegate: RecentTopicCellDelegate?
    
    override func awakeFromNib() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "SmallTopicCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        getFacts(initialFetch: true)
    }
    
    func getFacts(initialFetch: Bool) {
        
        let defaults = UserDefaults.standard
        let factStrings = defaults.stringArray(forKey: "recentTopics") ?? [String]()
        
        if initialFetch {
            for string in factStrings {
                loadFact(factID: string)
            }
        } else {
            if self.facts.count >= 10 {
                self.facts.removeLast()
            }
            
            self.facts = self.facts.filter{ $0.documentID != factStrings[0] }
            
            loadFact(factID: factStrings[0])
        }
    }
    
    func loadFact(factID: String) {
        let factRef = db.collection("Facts").document(factID)
        
        factRef.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snapshot = snap {
                    if let data = snapshot.data() {
                        if let fact = self.dataHelper.addFact(documentID: snapshot.documentID, data: data) {
                            
                            self.facts.insert(fact, at: 0)
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
}

extension RecentTopicsCollectionCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if facts.count != 0 {
            return facts.count
        } else {
            return 4
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if facts.count != 0 {
            let fact = facts[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? SmallTopicCell {
                
                cell.fact = fact
                
                return cell
            }
        } else {
            // Blank Cell
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: placeHolderIdentifier, for: indexPath) as? PlaceHolderCell {
                
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if facts.count != 0 {
            let fact = facts[indexPath.item]
            
            fact.getFollowStatus { (isFollowed) in
                if isFollowed {
                    fact.beingFollowed = true
                    self.delegate?.topicTapped(fact: fact)
                } else {
                    self.delegate?.topicTapped(fact: fact)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let newSize = CGSize(width: (collectionView.frame.size.height), height: (collectionView.frame.size.height))
        
        return newSize
    }
}


class SmallTopicCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellNameLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    
    override func awakeFromNib() {
            cellImageView.contentMode = .scaleAspectFill
            
            layer.cornerRadius = 4
            layer.masksToBounds = true
        }
        
        override func prepareForReuse() {
            cellImageView.image = nil
        }
    
    func setGradientView() {
        //Gradient
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
        let whiteColor = UIColor.white
        gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
        gradient.locations = [0.0, 0.7, 1]
        gradient.frame = gradientView.bounds
        
        gradientView.layer.mask = gradient
    }
        
        var fact: Fact? {
            didSet {
                if let fact = fact {
                    cellNameLabel.text = fact.title
                    
                    if let url = URL(string: fact.imageURL) {
                        cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                    } else {
                        cellImageView.image = UIImage(named: "FactStamp")
                    }
                    setGradientView()
                }
            }
        }
}
