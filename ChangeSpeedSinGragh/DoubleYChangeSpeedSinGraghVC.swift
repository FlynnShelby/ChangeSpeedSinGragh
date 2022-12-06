//
//  DoubleYChangeSpeedSinGraghVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/6.
//

import UIKit
//MARK: 双Y坐标变速曲线（Y轴将分为>1和<1的上下两部分，上下部分的单位量不同）
class DoubleYChangeSpeedSinGraghVC: UIViewController {

    var sineView = DoubleYChangeSpeedSinGraghView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        sineView.frame = CGRect(x: 20, y: 200, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .cyan
        
        view.addSubview(sineView)
        
        
    }
   


}
