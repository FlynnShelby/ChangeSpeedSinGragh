//
//  DoubelYChangeSpeedCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/2.
//

import UIKit

class DoubelYChangeSpeedCurveView: UIView {

    //标准速度 1倍
    var normSpeed = 1.0
    //最大速度 10倍
    var maxSpeed: CGFloat = 10.0
    //总时长（秒）
    var maxTime: CGFloat = 35.0
    
    
    //x轴描点步长（pt）
    private let step: CGFloat = 1.0
    //x轴每个点（pt）所对应的时间t
    private var x_t: CGFloat {
        get {
             
            if bounds.width > 0 {
                let unit_t = maxTime / bounds.width
                return unit_t
            }
            return 0.1
        }
    }
    
    //峰值点
    var pointArr: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var funcParamsArr:[DoubelYMonotonicSineMode] = []
    
    private func createSineFuncParamsArr()->[DoubelYMonotonicSineMode]{
        var arr:[DoubelYMonotonicSineMode] = []
        if pointArr.count > 1 {
            
            //从第二个点开始创建model
            for i in 1...pointArr.count-1{
                let start = pointArr[i-1]
                let end = pointArr[i]
                
                let model = DoubelYMonotonicSineMode(p0: start, p1: end)
                
                arr.append(model)
            }
        }
        
        return arr
    }


    override func draw(_ rect: CGRect) {
        super.draw(rect)
        //加坐标轴
        addCoordinateAxis(originPoint: CGPoint(x: 0.0, y: rect.height/2))
        //生成多段sine参数数组
        funcParamsArr = createSineFuncParamsArr()
        guard funcParamsArr.count > 0 else {
            print("峰值点不能少于两个")
            return
        }
        
        let path = UIBezierPath()
        path.lineWidth = 2.0
        UIColor.orange.setStroke()
        for i in 0...funcParamsArr.count-1 {
          
            let funcParams = funcParamsArr[i]
            
            //T：视图坐标系中一周期的宽度
            let T = funcParams.T / x_t
            let num = funcParams.num
            
            //x:视图坐标系x轴的值
            var x: CGFloat = 0
            path.move(to: CGPoint(x: funcParams.start.x/x_t, y: funcParams.getPointYAtView(x*x_t, CGPoint(x: 0, y: rect.height/2))))
            while x < T * num {
                x += step
                path.addLine(to: CGPoint(x: funcParams.start.x/x_t+x, y: funcParams.getPointYAtView(x*x_t, CGPoint(x: 0, y: rect.height/2))))
            }
            
        }
        
        path.stroke()
        
    }
    
    //添加坐标轴
    func addCoordinateAxis(originPoint:CGPoint) {

        
        let labO = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labO.font = UIFont.systemFont(ofSize: 10)
        labO.text = "1x"
        labO.center = CGPoint(x: originPoint.x+30+5, y: originPoint.y-10)
        addSubview(labO)
        
        let labX = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labX.font = UIFont.systemFont(ofSize: 10)
        labX.textAlignment = .right
        labX.text = "\(maxTime)s"
        labX.center = CGPoint(x: bounds.width-30-5, y: originPoint.y+10)
        addSubview(labX)
        
        let labY = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labY.font = UIFont.systemFont(ofSize: 10)
        labY.text = "\(maxSpeed)x"
        labY.center = CGPoint(x: originPoint.x+30+5, y: (bounds.height/2)/maxSpeed+10)
        addSubview(labY)
        
        let labYmin = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labYmin.font = UIFont.systemFont(ofSize: 10)
        labYmin.text = "0.1x"
        labYmin.center = CGPoint(x: originPoint.x+30+5, y: bounds.height-(bounds.height/2)/maxSpeed-10)
        addSubview(labYmin)
        
        
        let line = UIBezierPath()
        line.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        //标准速基线y=1.0x
        line.move(to: CGPoint(x: 0, y: bounds.height/2))
        line.addLine(to: CGPoint(x: bounds.width, y: bounds.height/2))
        //边框
        line.move(to: CGPoint(x: 0, y: (bounds.height/2)/maxSpeed))
        line.addLine(to: CGPoint(x: bounds.width-0.5, y: (bounds.height/2)/maxSpeed))
        line.addLine(to: CGPoint(x: bounds.width-0.5, y: bounds.height-(bounds.height/2)/maxSpeed))
        line.addLine(to: CGPoint(x: 0.5, y: bounds.height-(bounds.height/2)/maxSpeed))
        line.addLine(to: CGPoint(x: 0.5, y: (bounds.height/2)/maxSpeed))
        line.stroke()
        
        //虚线
        let lineDash = UIBezierPath()
        lineDash.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        //5.5
        let ym0 = bounds.height/2-(bounds.height/2*(maxSpeed-1)/maxSpeed)/2
        lineDash.move(to: CGPoint(x: 0, y:ym0))
        lineDash.addLine(to: CGPoint(x: bounds.width, y: ym0))
        //0.65
        let ym1 = bounds.height/2 + (bounds.height/2*(maxSpeed-1)/maxSpeed)/2
        lineDash.move(to: CGPoint(x: 0, y:ym1))
        lineDash.addLine(to: CGPoint(x: bounds.width, y: ym1))
        
        lineDash.setLineDash([10,10], count: 2, phase: 0)
        lineDash.stroke()
        
    }

}
