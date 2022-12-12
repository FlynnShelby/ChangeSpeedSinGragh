//
//  DoubleYChangeSpeedSineCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/7.
//

import UIKit

class DoubleYChangeSpeedSineCurveView: UIView {
 
    //标准速度 1倍
    var normSpeed = 1.0
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
//                beginAnimate()
                beginAnimation()
            }
        }
    }
    //开始播放时刻
    private var playDate = Date()
    //误差时间（毫秒）
    private var offsetTime = 0.0
    //当前位置（t，v）
    var currentPoint:CGPoint = CGPoint(x: 0, y: 1) {
        didSet {
            currentTime = currentPoint.x
            checkCurrentPoint()
            currentPointBlock?(currentPoint)
        }
    }
    //位置变化回调
    var currentPointBlock:((_ p:CGPoint) ->Void)?
    
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


//添加控制点视图
    func addControlPointView(){
        if ctrlPVArr.count == pointArr.count {
            return
        }
        for view in ctrlPVArr {
            view.removeFromSuperview()
        }
        ctrlPVArr.removeAll()
        
        isCountChange = true
        
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
        
        if pointArr.count > 0 {
            setTimeLineTo(point: pointArr.first!)
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
             
            break
        case .ended:
            print("finallyTime=\(getFinallyTime())")
            playDate = Date()
               play = true
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
                ctrlPVArr[index].backgroundColor = .white
            }else{
                ctrlPVArr[index].backgroundColor = .black
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
        let margin = 1.0
        
        let x = currentTime/x_t + margin
        let v = getValueWithTime(currentTime)
        currentPoint = CGPoint(x: x*x_t, y: v)
        var rec = timeLine.frame
        rec.origin.x += margin
        let duration = x_t/v
        
        //误差时间（DispatchQueue每轮代码运行耗时）
        offsetTime += Date().timeIntervalSince(nowDate)
        print("duration = \(duration)s offsetTime = \(offsetTime*1000.0)ms")

        print("2  t=\(currentTime) date=\(dateFormate.string(from: Date()))")
        let nowD = Date()
        let offT = offsetTime
        self.offsetTime = 0.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+duration-offT){
            [weak self,rec,nowD] in
            guard self != nil else {return}
            self?.timeLine.frame = rec
            print("3  t=\(self!.currentTime) date=\(dateFormate.string(from: Date()))")
            self?.offsetTime = Date().timeIntervalSince(nowD)-(duration-offT)
            self?.beginAnimation()
        }
        
        
    }
    @objc func beginAnimate(){
        let nowDate = Date()
        let dateFormate = DateFormatter()
            dateFormate.dateFormat = "yyyyMMdd HH:mm:ss.SSS"
        
        print("1  t=\(currentTime) date=\(dateFormate.string(from: Date()))")
        if !play { return }
        if currentTime >= maxTime{
            play = false
            print("endPlay time = \(Date().timeIntervalSince(playDate))")
            return
        }
        
        //间隔时间s
        let interval = 0.5

        currentTime += interval
        currentTime = min(currentTime, maxTime)


        var x = currentTime/x_t
            x = min(x, bounds.width-1)
        let v = getValueWithTime(currentTime)

        currentPoint = CGPoint(x: currentTime, y: v)

        var rec = timeLine.frame
        let distance = Int(x-rec.origin.x)
        rec.origin.x = x

        print("2  t=\(currentTime) date=\(dateFormate.string(from: Date()))")

        let duration = interval/v
        //误差时间（DispatchQueue每轮代码运行耗时2.5毫秒左右）
        offsetTime += Date().timeIntervalSince(nowDate)
        offsetTime = max(offsetTime, 0.0025)
        print("duration = \(duration)s offsetTime = \(offsetTime*1000.0)ms")

        //中间段动画
//        if distance > 0 {
//            DispatchQueue.global().async { [weak self] in
//                guard let this = self else {return}
//                for _ in 1...distance {
//                    if !this.play {  return }
//                    let maginT = (duration-this.offsetTime)/CGFloat(distance)
//                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+maginT){
//                        [weak self] in
//                        var rect0 = self?.timeLine.frame
//                        rect0?.origin.x += 1
//                        DispatchQueue.main.async {
//                            self?.timeLine.frame = rect0!
//                        }
//                    }
//                }
//            }
//        }
        
        //移动到目标位置
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration - offsetTime){
            [weak self,rec] in
            self?.offsetTime = 0.0
            let nowD = Date()
            print("3  t=\(self!.currentTime) date=\(dateFormate.string(from: Date()))")
            self?.timeLine.frame = rec
            print("4  t=\(self!.currentTime) date=\(dateFormate.string(from: Date()))")
            self?.offsetTime += Date().timeIntervalSince(nowD)
            self?.beginAnimate()
        }
        
        
//        //误差时间（UIView.animate每轮代码运行耗时17毫秒左右）
//        offsetTime += Date().timeIntervalSince(nowDate)
//        offsetTime = max(offsetTime, 0.017)
//        print("duration = \(duration)s offsetTime = \(offsetTime*1000.0)ms")
//        UIView.animate(withDuration: duration-offsetTime) {
//            [weak self,rec] in
//            print("3  t=\(self!.currentTime) date=\(dateFormate.string(from: Date()))")
//            self?.timeLine.frame = rec
//
//        }completion: { [weak self] Bool in
//            self?.offsetTime = 0.0
//            self?.beginAnimate()
//        }
     
        
//        UIView.animate(withDuration: duration-offsetTime, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1) {
//            [weak self,rec] in
//            print("3  t=\(self!.currentTime) date=\(dateFormate.string(from: Date()))")
//            self?.timeLine.frame = rec
//        }completion: { [weak self] Bool in
//            self?.offsetTime = 0.0
//            self?.beginAnimate()
//        }
        
         
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

