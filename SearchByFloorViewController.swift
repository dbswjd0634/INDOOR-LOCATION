//
//  SearchByFloorViewController.swift
//  AR
//  Copyright © 2019 M-33. All rights reserved.
//

import UIKit

var myIndex = 0
var myname = ""
var mydeveloper = ""
var myadvisor = ""
var mytool = ""
var mymotivation = ""
var mysummary = ""

class SearchByFloorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, HomeModelProtocol {
    
    var feedItems: NSArray = NSArray()
    //var selectedLocation : LocationModel = LocationModel()
    @IBOutlet weak var tableView: UITableView!
    
    
    func itemsDownloaded(items: NSArray) {
        feedItems = items
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return(list.count)
        return feedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        // Get the location to be shown
        let item: LocationModel = feedItems[indexPath.row] as! LocationModel
        // Get references to labels of cell\
        
        

        myCell.textLabel!.text = item.name
        
        return myCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let im: LocationModel = feedItems[indexPath.row] as! LocationModel
        myIndex = indexPath.row
        myname = im.name ?? "aaa"
        mydeveloper = im.developer ?? "aaa"
        myadvisor = im.advisor ?? "aaa"
        mytool = im.tool ?? "aaa"
        mymotivation = im.motivation ?? "aaa"
        mysummary = im.summary ?? "aaa"
        
        performSegue(withIdentifier: "segue", sender: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
           
        self.tableView.delegate = self
        self.tableView.dataSource = self
           
        let homeModel = HomeModel()
        homeModel.delegate = self
        homeModel.downloadItems()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

}
