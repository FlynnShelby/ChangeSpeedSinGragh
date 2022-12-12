//
//  CustomChangeSpeedCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/12.
//

import UIKit
//MARK: 双Y坐标变速曲线（Y轴将分为>1和<1的上下两部分，上下部分的单位量不同）
class CustomChangeSpeedCurveView: UIView {

    //标准速度 1倍
    var normSpeed = 1.0
    //最小速度 0.1倍
    var minSpeed: CGFloat = 0.1
    //最大速度 10倍
    var maxSpeed: CGFloat = 10.0
    //总时长（秒）
    var maxTime: CGFloat = 35.0
    
    
    //x轴描点步长（pt）
    private let step: CGFloat = 1.0
    //x轴每个点（pt）所对应的时间t
    var x_t: CGFloat {
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
    
    //操作记录
    var pointOperationRecord: [[CGPoint]] = []
    //当前使用的操作记录下标
    var currentRecordIndex = 0
    
    //控制点视图组
    var ctrlPVArr: [UIView] = []
    
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
    //点数量是否发生了变化
    var isCountChange = false
    //是否是 重置、撤销、恢复 (注：该属性须在pointArr赋值之前设置)
    var isSpecialOperation = false
    //时码线
    lazy var timeLine:UIView = {
        let line = UIView()
        line.backgroundColor = .white
        addSubview(line)
        return line
    }()
    //当前播放时间（时码线位置）
    var currentTime = 0.0
    //播放/暂停
    var play: Bool = false {
        didSet {
            if play {
                beginAnimation()
            }else{
                workItem.cancel()
            }
        }
    }
    //每次动画移动的距离pt
    var marginXForAnimate = 1.0
    //开始播放时刻
    private var playDate = Date()
    //误差时间（毫秒）
    private var offsetTime = 0.0
    //动画回调
    private var workItem:DispatchWorkItem = DispatchWorkItem {}
    
    //当前位置（t，v）
    var currentPoint:CGPoint = CGPoint(x: 0, y: 1) {
        didSet {
            currentTime = currentPoint.x
            checkCurrentPoint()
            currentPointBlock?(currentPoint)
        }
    }
    
    //控制点调整时显示速度
    lazy var speedLab:UILabel = {
        let lab = UILabel()
        lab.textColor = .white
        lab.textAlignment = .center
        lab.font = UIFont.systemFont(ofSize: 12)
        lab.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        lab.center = CGPoint(x: center.x, y: bounds.height/2/maxSpeed-10)
        lab.isHidden = true
        addSubview(lab)
        return lab
    }()
    
    //位置变化回调
    var currentPointBlock:((_ p:CGPoint) ->Void)?
    
    //平移操作回调
    var panGestureEndBlock:((_ curveView:CustomChangeSpeedCurveView)->Void)?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if timeLine.frame == .zero {
            //时码线
            timeLine.frame = CGRect(x: 0, y: rect.height/2/maxSpeed, width: 1.5, height: rect.height*(maxSpeed-1)/maxSpeed)
        }
        print("draw")
        //加坐标轴
        addCoordinateAxis(originPoint: CGPoint(x: 0.0, y: rect.height/2))
        //生成多段sine参数数组
        funcParamsArr = createSineFuncParamsArr()
        guard funcParamsArr.count > 0 else {
            print("峰值点不能少于两个")
            return
        }
        
        let path = UIBezierPath()
        path.lineWidth = 1.5
        UIColor(red: 1, green: 209/255, blue: 90/255, alpha: 1).setStroke()
        for i in 0...funcParamsArr.count-1 {
          
            let funcParams = funcParamsArr[i]
            
            
            //x:视图坐标系x轴的值
            var x: CGFloat = 0
            path.move(to: CGPoint(x: funcParams.start.x, y: funcParams.solveSineFunctionWithX(x)))
            while x < funcParams.T * funcParams.num {
                x += step
                path.addLine(to: CGPoint(x: funcParams.start.x+x, y: funcParams.solveSineFunctionWithX(x)))
            }
            
             
            if isCountChange {
                
                //调整控制点的位置
                if i == 0 {
                    ctrlPVArr.first?.center = funcParams.start
                    ctrlPVArr[i+1].center = funcParams.end
                }else{
                    ctrlPVArr[i+1].center = funcParams.end
                }
                
                if i == funcParamsArr.count - 1 {
                    isCountChange = false
                }
                
                //首次进入页面时获取不到变速后的总时间，因此曲线绘制完成时调用一次回调
                if pointOperationRecord.count == 1 {
                    currentPointBlock?(currentPoint)
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
        labO.textColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        labO.center = CGPoint(x: originPoint.x+30+5, y: originPoint.y)
        addSubview(labO)
        sendSubviewToBack(labO)
        
//        let labX = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
//        labX.font = UIFont.systemFont(ofSize: 10)
//        labX.textAlignment = .right
//        labX.text = "\(maxTime)s"
//        labX.center = CGPoint(x: bounds.width-30-5, y: originPoint.y+10)
//        addSubview(labX)
        
        let labY = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labY.font = UIFont.systemFont(ofSize: 10)
        labY.text = "\(maxSpeed)x"
        labY.textColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        labY.center = CGPoint(x: originPoint.x+30+5, y: (bounds.height/2)/maxSpeed+10)
        addSubview(labY)
        sendSubviewToBack(labY)
        
        let labYmin = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
        labYmin.font = UIFont.systemFont(ofSize: 10)
        labYmin.text = "0.1x"
        labYmin.textColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        labYmin.center = CGPoint(x: originPoint.x+30+5, y: bounds.height-(bounds.height/2)/maxSpeed-10)
        addSubview(labYmin)
        sendSubviewToBack(labYmin)
        
        
        let line = UIBezierPath()
        line.lineWidth = 1.0
        UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1).setStroke()
        //标准速基线y=1.0x
        line.move(to: CGPoint(x: 20, y: bounds.height/2))
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
        UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1).setStroke()
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


//添加控制点视图
    func addControlPointView(){
        //非特殊操作 且 控制点数量无变化，则跳过
        if ctrlPVArr.count == pointArr.count && !isSpecialOperation{
            return
        }
        for view in ctrlPVArr {
            view.removeFromSuperview()
        }
        ctrlPVArr.removeAll()
        
        isCountChange = true
        isSpecialOperation = false
        
        if pointArr.count > 0 {
            setTimeLineTo(point: pointArr.first!)
        }
        
        for index in 0...pointArr.count-1 {
          
            let cpv = UIButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            cpv.layer.cornerRadius = 8
            cpv.layer.borderColor = UIColor.white.cgColor
            cpv.layer.borderWidth = 2
            cpv.backgroundColor = index == 0 ? .white : .black
            addSubview(cpv)
            
            cpv.tag = 1000 + index
            cpv.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureChange(_ :))))
            cpv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureChange(_ :))))
            ctrlPVArr.append(cpv)
        }
        
        
    }
    
    //控制点平移
    @objc func panGestureChange(_ pan:UIPanGestureRecognizer){
        
        play = false
        let index = pan.view!.tag - 1000
        
        var p = CGPoint(x: 0, y: 0)
        switch pan.state {
        case .began:
              
            setTimeLineTo(point: pointArr[index])
            
            speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
            speedLab.isHidden = false
            
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
                
                setTimeLineTo(point: pointArr[index])
                setNeedsDisplay()
            }else if index == pointArr.count - 1 {
                var center = pan.view!.center
                center.y = p.y
                pan.view?.center = center
                let point = CGPoint(x: center.x*x_t, y: DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(center.y, o: CGPoint(x: 0, y: bounds.height/2)))
                pointArr[index].x = point.x
                pointArr[index].y = point.y
                
                
                setTimeLineTo(point: pointArr[index])
                setNeedsDisplay()
            }else{
                let pLast = funcParamsArr[index-1].start
                let pNext = funcParamsArr[index].end
                
                
                if p.x > pLast.x+5 && p.x < pNext.x-5 {
                    pan.view?.center = p
                    
                    let point = CGPoint(x: p.x*x_t, y: DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(p.y, o: CGPoint(x: 0, y: bounds.height/2)))
                    pointArr[index].x = point.x
                    pointArr[index].y = point.y
                     
                    setTimeLineTo(point: pointArr[index])
                    setNeedsDisplay()
                }
            }
            
            speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
            speedLab.isHidden = false
           
            break
        case .ended:
            print("finallyTime=\(getFinallyTime())")
            playDate = Date()
            play = true
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2){
                [weak self] in
                self?.speedLab.isHidden = true
            }
            
            //记录操作
            pointOperationRecord.append(pointArr)
            currentRecordIndex += 1
            panGestureEndBlock?(self)
            break
        default :
            break
        }
        
        
    }
    
    //控制点单击
    @objc func tapGestureChange(_ tap:UITapGestureRecognizer){
        play = false
        let index = tap.view!.tag - 1000
         
        setTimeLineTo(point: pointArr[index])
        
        speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
        speedLab.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2){
            [weak self] in
            self?.speedLab.isHidden = true
        }
    }
     
    //设置时码线到某个点（t，v）
    @objc func setTimeLineTo(point:CGPoint){
        currentPoint = point
        
        var rec1 = timeLine.frame
        let x = bounds.width*(point.x/maxTime)
        rec1.origin.x = x - rec1.width/2
        timeLine.frame = rec1
    }
    
    //检测当前位置是否是某个控制点
    @objc func checkCurrentPoint(){
        
        for index in 0...pointArr.count-1 {
            let p = pointArr[index]
            if abs(p.x - currentPoint.x) < 5*x_t {
                if index < ctrlPVArr.count {
                    ctrlPVArr[index].backgroundColor = .white
                }
            }else{
                if index < ctrlPVArr.count {
                    ctrlPVArr[index].backgroundColor = .black
                }
            }
        }
         
    }
    
     //开始动画/播放
    @objc func beginAnimation(){
        let nowDate = Date()
        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyyMMdd HH:mm:ss.SSS"
        
        print("1  t=\(currentTime) date=\(dateFormate.string(from: Date()))")
        if !play {
            //预防动画过程中点击了控制点，导致时码线停留在动画结束位置
            setTimeLineTo(point: currentPoint)
            return
        }
        if currentTime >= maxTime{
            play = false
            print("endPlay time = \(Date().timeIntervalSince(playDate))")
            return
        }
        
        //间隔距离pt
        let margin = marginXForAnimate > 0 ? marginXForAnimate : 2.0
        
        let x = currentTime/x_t + margin
        let v = getValueWithTime(currentTime)
        currentPoint = CGPoint(x: x*x_t, y: v)
        var rec = timeLine.frame
        rec.origin.x = min(x, bounds.width)
        let duration = x_t/v
        
        //误差时间（DispatchQueue每轮代码运行耗时）
        offsetTime += Date().timeIntervalSince(nowDate)
        print("duration = \(duration)s offsetTime = \(offsetTime*1000.0)ms")

        print("2  t=\(currentTime) date=\(dateFormate.string(from: Date()))")
        let nowD = Date()
        let offT = offsetTime
        self.offsetTime = 0.0
        
        workItem = DispatchWorkItem {
            [weak self,rec,nowD] in
            guard let this = self else {return}
            this.timeLine.frame = rec
            print("3  t=\(this.currentTime) date=\(dateFormate.string(from: Date()))")
            this.offsetTime = Date().timeIntervalSince(nowD)-(duration-offT)
            this.beginAnimation()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+duration-offT, execute:workItem)
        
    }
    
    //锁定某时间对应的函数模型
    @objc func findSineModel(x:TimeInterval)->DoubleYMonotonicSinGraghModel{
        for model in funcParamsArr {
            if model.p0.x <= x && x <= model.p1.x {
                return model
            }
        }
        return DoubleYMonotonicSinGraghModel()
    }
    
    //某时刻的速度
    func getValueWithTime(_ t:TimeInterval)->CGFloat{
         
        let model = findSineModel(x: t)
        let y = model.solveSineFunctionWithX((t-model.p0.x)/x_t)
        let v = DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(y, o: CGPoint(x: 0, y: bounds.height/2))
        
        return v
    }
    
    //变速后的总时间
    func getFinallyTime() -> TimeInterval {
        var t = 0.0
        var fTime = 0.0
        
        while t < maxTime {
            let interval = 0.1
            
            t += interval
            t = min(t, maxTime)
            
            let model = findSineModel(x: t)
            
            var x = t/x_t
                x = min(x, bounds.width-1)
            let y = model.solveSineFunctionWithX(x-model.start.x)
            let v = DoubleYMonotonicSinGraghModel.getValueWithPointYAtView(y, o: CGPoint(x: 0, y: bounds.height/2))
            
            fTime += interval/v
        }
        
        return fTime
    }

}
