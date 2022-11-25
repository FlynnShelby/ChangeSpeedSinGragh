//
//  ViewController.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/24.
//

import UIKit

class ViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let  nvc = UINavigationController(rootViewController: HomeVC())
        nvc.title = "Sign曲线"
        addChild(nvc)
    }


}

