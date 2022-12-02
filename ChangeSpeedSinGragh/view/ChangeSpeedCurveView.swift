//
//  ChangeSpeedCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/30.
//

import UIKit
/*
    y = A*sin(w*x + p) + D
    T = 2*Pi/w
 
    p:x左右偏移量，左+右-，偏移1/w*p
    w:x轴缩放1/w倍，即周期缩放1/w倍
    A: y的阈值【-A，A】
    D:y上下偏移量
    x：变量
    y：函数值
 */

class ChangeSpeedCurveView: UIView {
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
    
    //y轴描点步长（pt）
    private let step_y:CGFloat = 1.0
    //y轴每个点（pt）所对应的速度
    private var y_v:CGFloat {
        get {
            if bounds.height > 0 {
                let unit_v = maxSpeed / bounds.height
                return unit_v
            }
            return 0.05
        }
    }
    
    //峰值点
    var pointArr: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var funcParamsArr:[MonotonicSineModel] = []
    
    private func createSineFuncParamsArr()->[MonotonicSineModel]{
        var arr:[MonotonicSineModel] = []
        if pointArr.count > 1 {
            
            //从第二个点开始创建model
            for i in 1...pointArr.count-1{
                let start = pointArr[i-1]
                let end = pointArr[i]
                
                let model = MonotonicSineModel(start: start, end: end)
                
                arr.append(model)
            }
        }
        
        return arr
    }
    
    //返回视图中对应点的Y值（高度）
    private func solveSineFuncGetPointY(_ x: CGFloat,_ funcParams:MonotonicSineModel) -> CGFloat {
        //正弦函数y值
        let y = funcParams.solveSineFunctionWithX(x)
        
        //(数学sin)函数值y对应(视图坐标y)的长度
        let y_h = y/y_v
        
        //视图中的坐标y值(以 (0,bounds.height) 为坐标原点)
        let pt_y = bounds.height-y_h
        
        return pt_y
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        //加坐标轴
        addCoordinateAxis(originPoint: CGPoint(x: 0.0, y: rect.height))
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
            path.move(to: CGPoint(x: funcParams.start.x/x_t, y: solveSineFuncGetPointY(x*x_t, funcParams)))
            while x < T * num {
                x += step
                path.addLine(to: CGPoint(x: funcParams.start.x/x_t+x, y: solveSineFuncGetPointY(x*x_t, funcParams)))
            }
            
        }
        
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
        
        let labO = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labO.font = UIFont.systemFont(ofSize: 10)
        labO.text = "0"
        labO.center = CGPoint(x: originPoint.x+30+5, y: originPoint.y+10)
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
        labY.center = CGPoint(x: originPoint.x+30+5, y: 10)
        addSubview(labY)
        
        //0.1倍速基线
        //y=0.1x
        let line_0_1 = UIBezierPath()
        line_0_1.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        line_0_1.move(to: CGPoint(x: 0, y:bounds.height-0.1/y_v))
        line_0_1.addLine(to: CGPoint(x: bounds.width, y: bounds.height-0.1/y_v))
        line_0_1.setLineDash([10,10], count: 2, phase: 0)
        line_0_1.stroke()
        
        //标准速基线
        //y=1.0x
        let line_1_0 = UIBezierPath()
        line_1_0.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        line_1_0.move(to: CGPoint(x: 0, y: bounds.height-1.0/y_v))
        line_1_0.addLine(to: CGPoint(x: bounds.width, y: bounds.height-1.0/y_v))
        line_1_0.setLineDash([10,10], count: 2, phase: 0)
        line_1_0.stroke()
        
    }
}

