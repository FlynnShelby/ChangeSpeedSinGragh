//
//  ChangeSpeedSineCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/28.
//

import UIKit

class ChangeSpeedSineCurveVC: UIViewController {
    
    var sineView = ChangeSpeedSineCurveView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        sineView.frame = CGRect(x: 20, y: 200, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .cyan
        
        view.addSubview(sineView)
    }
    

  
}
