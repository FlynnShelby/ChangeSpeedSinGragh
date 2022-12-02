//
//  SineParamsModel.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/30.
//

import UIKit

class SineParamsModel: NSObject {
    //振幅
    var amplitude: CGFloat = 50.0
    //周期
    var tras: CGFloat = 200.0
    //x偏移量，<0右移，>0左移
    var offsetX: CGFloat = 0.0
    //y偏移量，>0上移,<0下移
    var offsetY: CGFloat = 0.0
    //周期数
    var num: CGFloat = 0.5
    
    //起点
    var startPoint: CGPoint = CGPoint(x: 0, y: 100)
    
    //终点
    var endPoint: CGPoint = CGPoint(x: 300, y: 100)
}
