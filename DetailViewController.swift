//
//  DetailViewController.swift
//  AR
//
//  Created by M-33 on 19/11/2019.
//  Copyright © 2019 M-33. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var developerLabel: UILabel!
    @IBOutlet weak var advisorLabel: UILabel!
    @IBOutlet weak var toolLabel: UILabel!
    @IBOutlet weak var motivationLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBAction func btnBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        nameLabel.text = myname
        developerLabel.text = mydeveloper
        advisorLabel.text = myadvisor
        toolLabel.text = mytool
        motivationLabel.text = mymotivation
        summaryLabel.text = mysummary
        
    }

}
