//
//  ChangeSpeedCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/2.
//

import UIKit

class ChangeSpeedCurveVC: UIViewController {

    var sineView = ChangeSpeedCurveView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        sineView.frame = CGRect(x: 20, y: 200, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .cyan
        
        view.addSubview(sineView)
    }
}
