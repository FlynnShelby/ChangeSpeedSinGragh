//
//  MultipleSineCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/28.
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


class MultipleSineCurveView: UIView {
    
    var pointArr: [CGPoint] = [] {
        didSet {
            if pointArr.count > 1 {
                funcParamsArr.removeAll()
                //从第二个点开始创建model
                for i in 1...pointArr.count-1{
                    let start = pointArr[i-1]
                    let end = pointArr[i]
                    
                    let model = SineParamsModel()
                    //振幅=y差值的绝对值除以2
                    model.amplitude = abs(end.y-start.y)/2
                    model.tras = abs(end.x-start.x)*2
                    if start.y < end.y {//上升
                        model.offsetX = -model.tras/4
                        model.offsetY = start.y + model.amplitude
                    }else{//下降
                        model.offsetX = model.tras/4
                        model.offsetY = end.y + model.amplitude
                    }
                    
                    model.num = 0.5
                    model.startPoint = start
                    model.endPoint = end
                    
                    funcParamsArr.append(model)
                }
            }
        }
    }
    
    private var funcParamsArr:[SineParamsModel] = []  { didSet { setNeedsDisplay() } }
     
    private func solveSineFuncGetPointY(_ x: CGFloat,_ funcParams:SineParamsModel) -> CGFloat {
        //Y轴偏移量
        let D = funcParams.offsetY
        //振幅
        let A = funcParams.amplitude
        //周期
        let T = funcParams.tras
        //x轴缩放倍率
        let w =  2*CGFloat.pi/T
        //x轴偏移量
        let p = w*funcParams.offsetX
        
        //正弦函数y值
        let y = A*sin(w*x+p)+D
         
        //视图中的坐标y值(以 (0,bounds.height) 为坐标原点)
        let pt_y = bounds.height-y
        
        return pt_y
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        //加坐标轴
        addCoordinateAxis(originPoint: CGPoint(x: 0.0, y: rect.height))
        
        
        let path = UIBezierPath()
        path.lineWidth = 2.0
        UIColor.orange.setStroke()
        for i in 0...funcParamsArr.count-1 {
          
            let funcParams = funcParamsArr[i]
            
            let step: CGFloat = 1.0
            let T = funcParams.tras
            let num = funcParams.num
         
            var x: CGFloat = 0
            path.move(to: CGPoint(x: funcParams.startPoint.x+x, y: solveSineFuncGetPointY(x,funcParams)))
            while x < T * num {
                x += step
                path.addLine(to: CGPoint(x: funcParams.startPoint.x+x, y: solveSineFuncGetPointY(x,funcParams)))
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
        labX.text = "\(bounds.width)"
        labX.center = CGPoint(x: bounds.width-30-5, y: originPoint.y+10)
        addSubview(labX)
        
        let labY = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labY.font = UIFont.systemFont(ofSize: 10)
        labY.text = "\(bounds.height)"
        labY.center = CGPoint(x: originPoint.x+30+5, y: 10)
        addSubview(labY)
    }
}
