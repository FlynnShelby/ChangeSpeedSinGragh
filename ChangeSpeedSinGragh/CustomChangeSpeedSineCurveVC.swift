//
//  CustomChangeSpeedSineCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/15.
//

import UIKit

class CustomChangeSpeedSineCurveVC: UIViewController {
    
    var customSineView:CustomSineCurveView = CustomSineCurveView()
    
    var totalTime = 10.0
    var pointArr:[CGPoint] = []
    
        
    override func viewDidLoad() {
        super.viewDidLoad()

        customSineView = CustomSineCurveView(frame: CGRect(x: 0, y: KScreenH-KSafeBottom-318, width: KScreenW, height: 318+KSafeBottom))
        
        view.addSubview(customSineView)
        
        customSineView.totalTime = totalTime
        customSineView.originPointArr = pointArr
        customSineView.titleLab.text = "蒙太奇"
    }
    
}
