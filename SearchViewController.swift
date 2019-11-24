//
//  SearchViewController.swift
//  AR
//
//  Copyright © 2019 M-33. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    
    @IBOutlet weak var location_table: UITableView!
    @IBOutlet weak var searchbar: UISearchBar!
    
    
    
    var filteredData: [String]!
    var location_name_array=[String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


