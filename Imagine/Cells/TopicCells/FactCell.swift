//
//  FactCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class FactCell:UICollectionViewCell {
    
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var factDescriptionLabel: UILabel!
    @IBOutlet weak var followButton: DesignableButton!
    
    let db = Firestore.firestore()
    
    override func awakeFromNib() {
        factCellImageView.contentMode = .scaleAspectFill
        
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
        let whiteColor = UIColor.white
        gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
        gradient.locations = [0.0, 0.7, 1]
        gradient.frame = gradientView.bounds
        
        gradientView.layer.mask = gradient
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        factCellImageView.image = nil
        followButton.setImage(UIImage(named: "AddPost"), for: .normal)
    }
    
    var fact: Fact? {
        didSet {
            if let fact = fact {
                factCellLabel.text = fact.title
                factDescriptionLabel.text = fact.description
                
                if fact.beingFollowed {
                    followButton.setImage(UIImage(named: "greenTik"), for: .normal)
                }
                
                if let url = URL(string: fact.imageURL) {
                    factCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                } else {
                    factCellImageView.image = UIImage(named: "FactStamp")
                }
            }
        }
    }
    
    var factID: String? {
        didSet {
            let ref = db.collection("Facts").document(factID!)
                        
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let data = snap.data() {
                            if let fact = DataHelper().addFact(documentID: snap.documentID, data: data) {
                                
                                self.fact = fact
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if let fact = fact {
                if !fact.beingFollowed {
                    let parentVC = FactParentContainerViewController()
                    parentVC.followTopic(fact: fact)
                    
                    followButton.setImage(UIImage(named: "greenTik"), for: .normal)
                }
            }
        }
    }
}
