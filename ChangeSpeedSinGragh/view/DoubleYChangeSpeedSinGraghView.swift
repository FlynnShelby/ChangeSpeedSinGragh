//
//  DoubleYChangeSpeedSinGraghView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/6.
//

import UIKit

class DoubleYChangeSpeedSinGraghView: UIView {

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
            
            //添加控制点
            addControlPointView()
            //刷新曲线
            setNeedsDisplay()
        }
    }
    
    //控制点视图组
    var ctrlPVArr: [UIView] = []
    //手势起点
    var panStart = CGPoint(x: 0, y: 0)
    
    var funcParamsArr:[DoubleYMonotonicSinGraghModel] = []
    
    private func createSineFuncParamsArr()->[DoubleYMonotonicSinGraghModel]{
        var arr:[DoubleYMonotonicSinGraghModel] = []
        if pointArr.count > 1 {
            
            //从第二个点开始创建model
            for i in 1...pointArr.count-1{
                let start = pointArr[i-1]
                let end = pointArr[i]
                
                let model = DoubleYMonotonicSinGraghModel(p0: start, p1: end,step_t: x_t,o: CGPoint(x: 0, y: bounds.height/2))
                
                arr.append(model)
            }
        }
        
        return arr
    }
    
    var isRedraw = false
    
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
            
            
            //x:视图坐标系x轴的值
            var x: CGFloat = 0
            path.move(to: CGPoint(x: funcParams.start.x, y: funcParams.solveSineFunctionWithX(x)))
            while x < funcParams.T * funcParams.num {
                x += step
                path.addLine(to: CGPoint(x: funcParams.start.x+x, y: funcParams.solveSineFunctionWithX(x)))
            }
            
             
            if !isRedraw {
                
                //调整控制点的位置
                if i == 0 {
                    ctrlPVArr.first?.center = funcParams.start
                    ctrlPVArr[i+1].center = funcParams.end
                }else{
                    ctrlPVArr[i+1].center = funcParams.end
                }
                
                if i == funcParamsArr.count - 1 {
                    isRedraw = true
                }
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
        //0.55
        let ym1 = bounds.height/2 + (bounds.height/2*(maxSpeed-1)/maxSpeed)/2
        lineDash.move(to: CGPoint(x: 0, y:ym1))
        lineDash.addLine(to: CGPoint(x: bounds.width, y: ym1))
        
        lineDash.setLineDash([10,10], count: 2, phase: 0)
        lineDash.stroke()
        
    }



    func addControlPointView(){
        if ctrlPVArr.count == pointArr.count {
            return
        }
        for view in ctrlPVArr {
            view.removeFromSuperview()
        }
        ctrlPVArr.removeAll()
        
        for index in 0...pointArr.count-1 {
          
            let cpv = UIButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            cpv.layer.cornerRadius = 8
            cpv.layer.borderColor = UIColor.white.cgColor
            cpv.layer.borderWidth = 2
            cpv.backgroundColor = .black
            addSubview(cpv)
            
            cpv.tag = 1000 + index
            cpv.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureChange(_ :))))
            ctrlPVArr.append(cpv)
        }
    }
    
    @objc func panGestureChange(_ pan:UIPanGestureRecognizer){
        
        let index = pan.view!.tag - 1000
         
        
        var p = CGPoint(x: 0, y: 0)
        switch pan.state {
        case .began:
            panStart = pan.location(in: self)
//            if index == 0 {
//                panStart.x = funcParamsArr.first?.start.x ?? 0
//            }
//            if index == pointArr.count-1 {
//                panStart.x = funcParamsArr.last?.end.x ?? bounds.width
//            }
//            print("origin=\(panStart)")
            break
        case .changed:
            p = pan.location(in: self)
            
            if p.y < bounds.height/2/maxSpeed
                || p.y > bounds.height - bounds.height/2/maxSpeed {
                break
            }
//            print("p=\(p)")
            if index == 0 {
                var center = pan.view!.center
                center.y = p.y
                pan.view?.center = center
                let point = CGPoint(x: center.x*x_t, y: DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(center.y, o: CGPoint(x: 0, y: bounds.height/2)))
                pointArr[index].x = point.x
                pointArr[index].y = point.y
                setNeedsDisplay()
            }else if index == pointArr.count - 1 {
                var center = pan.view!.center
                center.y = p.y
                pan.view?.center = center
                let point = CGPoint(x: center.x*x_t, y: DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(center.y, o: CGPoint(x: 0, y: bounds.height/2)))
                pointArr[index].x = point.x
                pointArr[index].y = point.y
                setNeedsDisplay()
            }else{
                let pLast = funcParamsArr[index-1].start
                let pNext = funcParamsArr[index].end
                
                
                if p.x > pLast.x+5 && p.x < pNext.x-5 {
                    pan.view?.center = p
                    
                    let point = CGPoint(x: p.x*x_t, y: DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(p.y, o: CGPoint(x: 0, y: bounds.height/2)))
                    pointArr[index].x = point.x
                    pointArr[index].y = point.y
                    setNeedsDisplay()
                }
            }
            break
        default :
            break
        }
        
        
    }
}
