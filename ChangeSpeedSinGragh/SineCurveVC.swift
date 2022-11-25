//
//  SineCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/24.
//

import UIKit

class SineCurveVC: UIViewController {

    var sineView = SineCurveView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        sineView.frame = CGRect(x: 20, y: 200, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .cyan
        
        view.addSubview(sineView)
    }
    
 

}
