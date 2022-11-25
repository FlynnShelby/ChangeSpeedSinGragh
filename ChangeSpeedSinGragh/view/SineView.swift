//
//  SineView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/24.
//

import UIKit

class SineView: UIView {
    // 曲线周期数
    var num = 1
    
    // 曲线总波长与视图的宽度比
    //等同 所需宽度与画布宽度比
    var graphWidth: CGFloat = 0.8
    
    // 曲线与视图的高度比
    //等同 所需振幅与画布高度比
    var amplitude: CGFloat = 0.3
    
    override func draw(_ rect: CGRect) {
        let width = rect.width
        let height = rect.height
        
        //画笔起点（原点）
        let origin = CGPoint(x: width * (1 - graphWidth) / 2, y: height * 0.50)
        
        //加坐标轴
        addCoordinateAxis(originPoint: origin)
        
        let path = UIBezierPath()
        path.lineWidth = 2.0
        path.move(to: origin)
        
        //曲线起点X值（角度）
        let startX = 0.0
        //曲线终点X值（角度）
        let endX = 360.0 * CGFloat(num)
        // 间隔（角度）
        let margin = 1.0
        for angle in stride(from: startX, through: endX, by: margin) {
            let x = origin.x + CGFloat(angle/360.0) * width * graphWidth / CGFloat(num)
            let y = origin.y - CGFloat(sin(angle/180.0 * Double.pi)) * height * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        UIColor.orange.setStroke()
        
        path.stroke()
    }
    
    
    //添加坐标轴
    func addCoordinateAxis(originPoint:CGPoint) {
        let xLine = UIView()
        xLine.backgroundColor = .gray
        xLine.frame = CGRect(x: 0, y: originPoint.y, width: bounds.width, height: 1)
        addSubview(xLine)
        
        let yLine = UIView()
        yLine.backgroundColor = .gray
        yLine.frame = CGRect(x: originPoint.x, y: 0, width: 1, height: bounds.height)
        addSubview(yLine)
    }
}
