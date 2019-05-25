//
//  MeldenViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit


class MeldenViewController: UIViewController {

    var post = Post()
    var reportCategory = ""
    var repost = "repost"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func dismissPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func reportOptionsScreenTapped(_ sender: DesignableButton) {
        switch sender.tag {
        case 0: reportCategory = "Optisch markieren"
            break
        case 1: reportCategory = "Schlechte Absicht"
            break
        case 2: reportCategory = "Lüge/Täuschung"
            break
        case 3: reportCategory = "Inhalt"
            break
        default:
            reportCategory = ""
        }
        
        performSegue(withIdentifier: "reportOptionSegue", sender: post)
    }
    
    @IBAction func repostPressed(_ sender: Any) {
        performSegue(withIdentifier: "toRepostSegue", sender: post)
    }
    
    @IBAction func translatePressed(_ sender: Any) {
        repost = "translation"
        performSegue(withIdentifier: "toRepostSegue", sender: post)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let nextVC = segue.destination as? MeldeOptionViewController {
            nextVC.reportCategory = self.reportCategory
            
            if let chosenPost = sender as? Post {
                    nextVC.post = chosenPost
            }
        }
        if let repostVC = segue.destination as? RepostViewController {
            if let chosenPost = sender as? Post {
                repostVC.post = chosenPost
                repostVC.repost = self.repost
            }
        }
    }
}