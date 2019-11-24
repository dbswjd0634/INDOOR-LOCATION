//
//  SecondViewController.swift
//  AR
//  Copyright © 2019 M-33. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func btnBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
 
    
    @IBAction func btnSearchByFloor(_ sender: UIButton) {
            let nextPage = self.storyboard?.instantiateViewController(identifier: "SearchByFloor")
            
            self.present(nextPage!, animated: true, completion: nil)
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
