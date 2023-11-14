//
//  CustomSineCurveView.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/15.
//

import UIKit

var UScreenWidth = UIScreen.main.bounds.width
var UScreenHeight = UIScreen.main.bounds.height

enum TimeLineState: Int {
    case isTap = 0      //(曲线无变动)时码线移动到高亮控制点
    case isPanBegan = 1 //控制点平移开始，时码线移动到高亮控制点
    case isPaning = 2   //控制点平移中，时码线跟随移动
    case isPanEnd = 3   //控制点平移结束
    case isPlay = 4     //(曲线无变动，时码线移动中)播放中
    case isPlayEnd = 5  //(曲线无变动)当前视频片段播放结束
    case isAdd = 6      //添加操作，时码线添加时的位置
    case isDelete = 7   // 删除操作，时码线重置到起始位置
    case isReset = 8    //重置操作，时码线重置到起始位置
    case isPanOnlyLine = 9  //仅时码线平移
}

//MARK: 定制变速曲线
class CustomSineCurveView: UIView {
    //变速曲线名称
    var curveName = "" {
        didSet {
            self.titleLab.text = curveName
            curveModel.curveName = curveName
        }
    }
    
    //峰值点/控制点(t,v) (t:时间百分值（0～100），v:t对应的速度值（0.1～10）)
    //初始控制点数组
    var originPointArr: [CGPoint] = []{
        didSet {
            pointArr.removeAll()
            pointArr.append(contentsOf: originPointArr)
            pointOperationRecord.append(pointArr)
            currentRecordIndex = 0
            isCountChange = true
            curveModel.originPointArr = originPointArr
            //            if pointArr.count > 0 {
            //                currentPoint = pointArr.first
            //            }
        }
    }
    //当前控制点数组
    var pointArr: [CGPoint] = []{
        didSet {
            guard pointArr.count > 1 else{return}
            curveModel.pointArr = pointArr
            sineView.funcParamsArr = curveModel.sineModelArr
            
            addControlPointView()
            setNeedsDisplay()
        }
    }
    
    var sineView = CustomSineCurveCanvas()
    
    var gestureView = UIView()
    
    //变速曲线模型
    var curveModel = CustomSineCurveModel()
    
    //x轴每个点（pt）所对应的时间t (t:时间百分值)
    var w_t: CGFloat {
        get {
            if sineView.wR.y > 0 {
                let unit_t = maxTime / sineView.wR.y
                return unit_t
            }
            return 0.1
        }
    }
    
    //总时长（秒）
    var totalTime: CGFloat = 35.0 {
        didSet {
            curveModel.totalTime = totalTime
            totalTimeLab.text = String(format: "时长%.1fs", totalTime)
        }
    }
    
    //最大时间百分值
    let maxTime = 100.0
    
    
    //操作记录
    var pointOperationRecord: [[CGPoint]] = []
    //当前使用的操作记录下标
    var currentRecordIndex = 0
    
    //控制点视图组
    var ctrlPVArr: [UIView] = []
    
    //点数量是否发生了变化
    var isCountChange = false
    //是否是 重置、撤销、恢复 (注：该属性须在pointArr赋值之前设置)
    var isSpecialOperation = false
    //时码线
    lazy var timeLine:UIView = {
        let line = UIView()
        line.backgroundColor = .white
        gestureView.addSubview(line)
        return line
    }()
    var timeLineState:TimeLineState = .isTap
    //当前播放时间（时码线位置）
    var currentTime = 0.0
    //播放/暂停
    var play: Bool = false {
        didSet {
            if play {
                playDate = Date()
                timeLineState = .isPlay
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
    
    //(时码线)当前位置（t，v）
    var currentPoint:CGPoint = CGPoint(x: 0, y: 1) {
        didSet {
            self.currentPoint = CGPoint(x: currentPoint.x.double.roundTo(places: 1), y: currentPoint.y.double.roundTo(places: 1))
            
            currentTime = currentPoint.x
            checkCurrentPoint()
            //更新按钮状态（添加、删除、智能补帧等）
            updateBtnState()
            
//            //变速后总时间s
//            finalTimeLab.text = String(format: "%.1fs", curveModel.getFinallyTime())
            
            currentPointBlock?(currentPoint,curveModel,timeLineState)
        }
    }
    
    //控制点调整时显示速度
    lazy var speedLab:UILabel = {
        let lab = UILabel()
        lab.textColor = .white
        lab.textAlignment = .center
        lab.font = UIFont.systemFont(ofSize: 12)
        lab.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        lab.center = CGPoint(x: center.x, y: gestureView.frame.minY)
        lab.isHidden = true
        addSubview(lab)
        return lab
    }()
    
    
    var resetBtn:UIButton = UIButton(type: .custom)
    var titleLab:UILabel = UILabel()
    var confirmBtn:UIButton = UIButton(type: .custom)
    
    var addBtn:UIButton = UIButton(type: .custom)
    var deleteBtn:UIButton = UIButton(type: .custom)
    
    var totalTimeLab:UILabel = UILabel()
    var arrowIcon:UIImageView = UIImageView()
    var finalTimeLab:UILabel = UILabel()
    
    //智能补充
    var smartFillFrameBtn:UIButton = UIButton(type: .custom)
    
    //撤消
    lazy var revocationBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named:"revocation"), for: .normal)
        btn.frame = CGRect(x: 20, y: frame.minY-34, width: 30, height: 30)
        self.superview?.addSubview(btn)
        btn.addTarget(self, action: #selector(revocationBtnClicked), for: .touchUpInside)
        
        btn.isHidden = true //该功能不需要
        return btn
    }()
    //恢复
    lazy var recoverBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named:"recover"), for: .normal)
        btn.frame = CGRect(x: 64, y: frame.minY-34, width: 30, height: 30)
        self.superview?.addSubview(btn)
        btn.addTarget(self, action: #selector(recoverBtnClicked), for: .touchUpInside)
        
        btn.isHidden = true //该功能不需要
        return btn
    }()
    
    //MARK: 回调传值
    //（时码线）位置变化回调
    var currentPointBlock:((_ p:CGPoint,_ curveModel:CustomSineCurveModel,_ timeLineState:TimeLineState) ->Void)?
    
    //切换智能补帧回调
    var changeSmartFillFrameBlock:((_ curveModel:CustomSineCurveModel) ->Void)?
    
    
    //确定回调
    var confirmBlock:((_ curveModel:CustomSineCurveModel)->Void)?
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        
        //控制点手势图
        gestureView.frame = CGRect(x: 0, y: 49, width: UScreenWidth, height: 200)
        addSubview(gestureView)
        let onlyLinePan = UIPanGestureRecognizer(target: self, action: #selector(onlyTimeLinePanChange(_ :)))
        gestureView.addGestureRecognizer(onlyLinePan)
        
        timeLine.frame = CGRect(x: 24, y: 10, width: 1.5, height: 180)
        
        //变速曲线图
        sineView.frame = CGRect(x: 24, y: 10, width: UScreenWidth-48, height: 180)
        sineView.whO = CGPointMake(0.0, sineView.bounds.height/2)
        sineView.wR = CGPointMake(0.0, sineView.bounds.width)
        sineView.hR = CGPointMake(0.0, sineView.bounds.height)
        sineView.backgroundColor = .clear
        
        gestureView.addSubview(sineView)
        
        //重置
        resetBtn.setImage(UIImage(named: "curveReset"), for: .normal)
        resetBtn.setTitle("重置", for: .normal)
        resetBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        resetBtn.setTitleColor(.white, for: .normal)
        resetBtn.frame = CGRect(x: 16, y: 0, width: 60, height: 44)
        addSubview(resetBtn)
        resetBtn.addTarget(self, action: #selector(resetBtnClicked), for: .touchUpInside)
        
        //标题
        titleLab.textColor = .white
        titleLab.font = UIFont.systemFont(ofSize: 16)
        titleLab.text = "变速曲线"
        titleLab.textAlignment = .center
        titleLab.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
        titleLab.center = CGPoint(x: center.x, y: resetBtn.center.y)
        addSubview(titleLab)
        
        //确认
        confirmBtn.setImage(UIImage(named:"curveConfirm"), for: .normal)
        confirmBtn.frame = CGRect(x: UScreenWidth-(13+22), y: 0, width: 44, height: 44)
        addSubview(confirmBtn)
        confirmBtn.addTarget(self, action: #selector(confirmBtnClicked), for: .touchUpInside)
        
        //添加控制点按钮
        addBtn.frame = CGRect(x: (UScreenWidth-68)/2, y: gestureView.frame.maxY+6, width: 68, height: 26)
        addBtn.backgroundColor = .white
        addBtn.layer.cornerRadius = 2
        addBtn.setTitle("+ 添加点", for: .normal)
        addBtn.setTitleColor(.black, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        addSubview(addBtn)
        addBtn.addTarget(self, action: #selector(addBtnClicked(_ :)), for: .touchUpInside)
        addBtn.isHidden = true
        
        //删除控制点按钮
        deleteBtn.frame = CGRect(x: (UScreenWidth-68)/2, y: gestureView.frame.maxY+6, width: 68, height: 26)
        deleteBtn.backgroundColor = UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1)
        deleteBtn.layer.cornerRadius = 2
        deleteBtn.setTitle("- 删除点", for: .normal)
        deleteBtn.setTitleColor(.black, for: .normal)
        deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        addSubview(deleteBtn)
        deleteBtn.addTarget(self, action: #selector(deleteBtnClicked(_ :)), for: .touchUpInside)
        deleteBtn.isHidden = false
        
        //时长
        totalTimeLab.textColor = UIColor(red: 139/255, green: 139/255, blue: 139/255, alpha: 1)
        totalTimeLab.font = UIFont.systemFont(ofSize: 12)
        totalTimeLab.text = String(format: "时长%.1fs", totalTime)
        totalTimeLab.frame = CGRect(x: 0, y: 0, width: 60, height: 18)
        totalTimeLab.center = CGPoint(x: 54, y: deleteBtn.center.y)
        addSubview(totalTimeLab)
        
        arrowIcon.image = UIImage(named:"timeArrow")
        arrowIcon.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
        arrowIcon.center = CGPoint(x: totalTimeLab.frame.maxX+4+2.5, y: deleteBtn.center.y)
        addSubview(arrowIcon)
        
        finalTimeLab.textColor = .white
        finalTimeLab.font = UIFont.systemFont(ofSize: 12)
        finalTimeLab.text = String(format: "%.1fs", curveModel.getFinallyTime())
        finalTimeLab.frame = CGRect(x: 0, y: 0, width: 60, height: 18)
        finalTimeLab.center = CGPoint(x: arrowIcon.frame.maxX+4+30, y: deleteBtn.center.y)
        addSubview(finalTimeLab)
        
        //智能补帧
        smartFillFrameBtn.setImage(UIImage(named:"curveSmart_normal"), for: .normal)
        smartFillFrameBtn.setImage(UIImage(named:"curveSmart_selected"), for: .selected)
        smartFillFrameBtn.setTitle(" 智能补帧", for: .normal)
        smartFillFrameBtn.setTitleColor(.white, for: .normal)
        smartFillFrameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        smartFillFrameBtn.frame = CGRect(x: 0, y: 0, width: 76, height: 18)
        smartFillFrameBtn.center = CGPoint(x: UScreenWidth-24-38, y: deleteBtn.center.y)
        addSubview(smartFillFrameBtn)
        smartFillFrameBtn.addTarget(self, action: #selector(smartFillFrameBtnClicked), for: .touchUpInside)
    
        
        //创建sine函数模型所需
        curveModel.whO = sineView.whO
        curveModel.wR = sineView.wR
        curveModel.hR = sineView.hR
        
    }
    
    func updateBtnState() {
        
        var isCtrlP = false
        for point in pointArr {
            if abs(point.x - currentPoint.x) < 5*w_t {
                isCtrlP = true
                break
            }
        }
        addBtn.isHidden = isCtrlP
        deleteBtn.isHidden = !isCtrlP
        
        if isCtrlP {
            sendSubviewToBack(addBtn)
            if abs(pointArr.first!.x - currentPoint.x) < 5*w_t
                || abs(pointArr.last!.x - currentPoint.x) < 5*w_t {
                //首尾两个控制点不可删除
                deleteBtn.isEnabled = false
                deleteBtn.backgroundColor = UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1)
            }else{
                deleteBtn.isEnabled = true
                deleteBtn.backgroundColor = .white
            }
        }else{
            bringSubviewToFront(addBtn)
            deleteBtn.isEnabled = false
        }
        
        //智能补帧按钮是否可用
        if isAllPointYGreaterThan1() {
            //所有控制点速度v>1时，禁用智能补帧
            smartFillFrameBtn.isSelected = false
            smartFillFrameBtn.isEnabled = false
            
            if curveModel.isSmartFillFrame {
                curveModel.isSmartFillFrame = false
                self.changeSmartFillFrameBlock?(curveModel)
            }
        }else{
            smartFillFrameBtn.isEnabled = true
            smartFillFrameBtn.isSelected = curveModel.isSmartFillFrame
        }
    }
    
    override func layoutSubviews(){
        super.layoutSubviews()
        refreshRevocationAndRecoverBtnEnableState()
        
    }
    
    override func draw(_ rect:CGRect){
        super.draw(rect)
        print("draw111111")
        if isCountChange {
            
            for i in 0..<sineView.funcParamsArr.count {
                let funcParams = sineView.funcParamsArr[i]
                //调整控制点的位置
                if i == 0 {
                    ctrlPVArr.first?.center = CGPointMake(sineView.frame.minX+funcParams.whP0.x, sineView.frame.minY+funcParams.whP0.y)
                    ctrlPVArr[i+1].center = CGPointMake(sineView.frame.minX+funcParams.whP1.x, sineView.frame.minY+funcParams.whP1.y)
                }else{
                    ctrlPVArr[i+1].center = CGPointMake(sineView.frame.minX+funcParams.whP1.x, sineView.frame.minY+funcParams.whP1.y)
                }
                
                if i == sineView.funcParamsArr.count - 1 {
                    isCountChange = false
                }
            }
        }
        
    }
    
    
    
    //MARK: 添加
    @objc func addBtnClicked(_ sender:UIButton){
        print("addPoint=\(String(describing:currentPoint))")
        play = false
        timeLineState = .isAdd
        
        let p = currentPoint
        guard pointArr.count > 1 else {return}
        for i in 1..<pointArr.count {
            let a = pointArr[i-1]
            let b = pointArr[i]
            if a.x < p.x && p.x < b.x {
                pointArr.insert(p, at: i)
                setTimeLineTo(point: p)
                break
            }
        }
        
        //记录操作
        pointOperationRecord.append(pointArr)
        currentRecordIndex += 1
        
    }
    //MARK: 删除
    @objc func deleteBtnClicked(_ sender:UIButton){
        print("deletePoint=\(String(describing: currentPoint))")
        
        play = false
        timeLineState = .isDelete
        
        let p = currentPoint
        for index in 0..<pointArr.count {
            let point = pointArr[index]
            if abs(point.x - p.x) < 5*(self.w_t) {
                
                pointArr.remove(at: index)
                break
            }
        }
        
        //记录操作
        pointOperationRecord.append(pointArr)
        currentRecordIndex += 1
        
        setTimeLineTo(point: currentPoint)
    }
    
    //MARK: 智能补帧
    @objc func smartFillFrameBtnClicked(_ sender:UIButton){
//        if let key = UIApplication.shared.keyWindow{
//            key.showHUD(title: "功能暂未开发")
//            return
//        }
        sender.isSelected = !sender.isSelected
        curveModel.isSmartFillFrame = sender.isSelected
        if sender.isSelected {
            marginXForAnimate = 1.0
        }else{
            marginXForAnimate = 2.0
        }
        
        changeSmartFillFrameBlock?(curveModel)
    }
    
    //是否所有控制点的速度都>1
    func isAllPointYGreaterThan1() -> Bool {
        let arr = pointArr.filter {$0.y > 1}
        return arr.count == pointArr.count
    }
    
    //MARK: 撤消一步操作
    @objc func revocationBtnClicked(_ sender:UIButton){
        if pointOperationRecord.count > 1
            && currentRecordIndex-1 >= 0 {
            isSpecialOperation = true
            play = false
            currentRecordIndex -= 1
            pointArr = pointOperationRecord[currentRecordIndex]
        }
        refreshRevocationAndRecoverBtnEnableState()
    }
    
    //MARK: 恢复一步操作
    @objc func recoverBtnClicked(_ sender:UIButton){
        if pointOperationRecord.count > 1
            && currentRecordIndex+1 < pointOperationRecord.count {
            isSpecialOperation = true
            play = false
            currentRecordIndex += 1
            pointArr = pointOperationRecord[currentRecordIndex]
        }
        refreshRevocationAndRecoverBtnEnableState()
    }
    //刷新 撤消按钮 和 恢复按钮 的可用状态
    func refreshRevocationAndRecoverBtnEnableState(){
        revocationBtn.isEnabled = currentRecordIndex != 0
        recoverBtn.isEnabled = currentRecordIndex != pointOperationRecord.count-1
    }
    
    //MARK: 重置
    @objc func resetBtnClicked(){
        play = false
        
        isSpecialOperation = true
        pointArr = originPointArr
        //清空记录
        pointOperationRecord.removeAll()
        //记录操作
        pointOperationRecord.append(pointArr)
        currentRecordIndex = 0
        
        refreshRevocationAndRecoverBtnEnableState()
        
        timeLineState = .isReset
        guard let  p = pointArr.first else { return }
        setTimeLineTo(point: p)
    }
    //MARK: 确定
    @objc func confirmBtnClicked(){
        print("\(pointArr)")
        play = false
        confirmBlock?(curveModel)
        
        self.removeFromSuperview()
        revocationBtn.removeFromSuperview()
        recoverBtn.removeFromSuperview()
    }
    
    
    //MARK: 控制点手势操作、时码线等
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
        timeLineState = .isTap
        
        if pointArr.count > 0 {
            setTimeLineTo(point: pointArr.first!)
        }
        
        for index in 0..<pointArr.count {
            
            let cpv = UIButton(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            cpv.layer.cornerRadius = 8
            cpv.layer.borderColor = UIColor.white.cgColor
            cpv.layer.borderWidth = 2
            cpv.backgroundColor = index == 0 ? .white : .black
            gestureView.addSubview(cpv)
            
            cpv.tag = 1000 + index
            cpv.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureChange(_ :))))
            cpv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureChange(_ :))))
            ctrlPVArr.append(cpv)
        }
        
        
    }
    
    var centerOffset:CGPoint = CGPoint(x: 0, y: 0)
    //控制点平移
    @objc func panGestureChange(_ pan:UIPanGestureRecognizer){
        
        play = false
        
        let index = pan.view!.tag - 1000
        
        var p = CGPoint(x: 0, y: 0)
        switch pan.state {
        case .began:
            timeLineState = .isPanBegan
            setTimeLineTo(point: pointArr[index])
            
            speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
            speedLab.isHidden = false
            
            p = pan.location(in: gestureView)
            let cpvCenter = ctrlPVArr[index].center
            centerOffset = CGPoint(x: cpvCenter.x - p.x, y: cpvCenter.y - p.y)
            print("sineCurve-- centerOffset = \(centerOffset.x),\(centerOffset.y)")
            break
        case .changed:
            timeLineState = .isPaning
            p = pan.location(in: gestureView)
            print("sineCurve-- p=\(p)")
            print("sineCurve-- centerOffset = \(centerOffset.x),\(centerOffset.y)")
            var cpvCenter = CGPoint(x: p.x+centerOffset.x, y: p.y+centerOffset.y)
            
            print("sineCurve-- center--inframe=\(sineView.frame)")
            
            if cpvCenter.x < sineView.frame.minX
                || cpvCenter.x > sineView.frame.maxX
                || cpvCenter.y < sineView.frame.minY
                || cpvCenter.y > sineView.frame.maxY
            {
//                break
                cpvCenter.x = max(sineView.frame.minX, cpvCenter.x)
                cpvCenter.x = min(cpvCenter.x,sineView.frame.maxX)
                cpvCenter.y = max(sineView.frame.minY, cpvCenter.y)
                cpvCenter.y = min(cpvCenter.y,sineView.frame.maxY)
            }
            
            print("sineCurve-- cpvCenter===\(cpvCenter)")
            
            var center = pan.view!.center
            let h = cpvCenter.y - sineView.frame.minY
            var t = 0.0
            if index == 0 {
                center.y = cpvCenter.y
                pan.view?.center = center
                
                t = sineView.tR.x   //t=0.0
                
            }else if index == pointArr.count - 1 {
                
                center.y = cpvCenter.y
                pan.view?.center = center
                
                t = sineView.tR.y //t=100.0
               
            }else{
                let pLast = sineView.funcParamsArr[index-1].whP0
                let pNext = sineView.funcParamsArr[index].whP1
                
                
                let w = cpvCenter.x - sineView.frame.minX
                if w > pLast.x+8 && w < pNext.x-8 {
                    pan.view?.center = cpvCenter
                    
                    t = MonotonicSineCurveModel.getTWithW(w,wRangeMax:sineView.wR.y)
                    
                }else{
                    //两点(中心)之间x轴方向间距小于8，则跳过
                    //避免控制点越位和过于重叠
                    break
                }
                
            }
            
            let v = MonotonicSineCurveModel.getVWithH(h, whO: sineView.whO, H: sineView.hR.y, vtO: sineView.vtO, vR: sineView.vR)
            let point = CGPoint(x: t.roundTo(places: 2), y: v.double.roundTo(places: 2))
            pointArr[index] = point
            
            setTimeLineTo(point: pointArr[index])
            
            speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
            speedLab.isHidden = false
            
            break
        case .ended:
            print("sineCurve-- finallyTime=\(curveModel.getFinallyTime())")
             
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2){
                [weak self] in
                self?.speedLab.isHidden = true
            }
            
            //记录操作
            pointOperationRecord.append(pointArr)
            currentRecordIndex += 1
            
            refreshRevocationAndRecoverBtnEnableState()
            
            timeLineState = .isPanEnd
            setTimeLineTo(point: pointArr.first!)
            play = true
            break
        default :
            break
        }
        
        
    }
    
    //控制点单击
    @objc func tapGestureChange(_ tap:UITapGestureRecognizer){
        play = false
        timeLineState = .isTap
        let index = tap.view!.tag - 1000
        
        setTimeLineTo(point: pointArr[index])
        
        speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
        speedLab.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2){
            [weak self] in
            self?.speedLab.isHidden = true
        }
         
    }
    
    //仅时码线平移
    @objc func onlyTimeLinePanChange(_ pan:UIPanGestureRecognizer){
        play = false
        
        var p = CGPoint(x: 0, y: 0)
        
        switch pan.state {
        case .began,
            .changed,
            .ended:
            
            p = pan.location(in: gestureView)
            
            if p.x < sineView.frame.minX
                || p.x > sineView.frame.maxX
                || p.y < sineView.frame.minY
                || p.y > sineView.frame.maxY
            {
                p.x = max(sineView.frame.minX, p.x)
                p.x = min(p.x,sineView.frame.maxX)
                p.y = max(sineView.frame.minY, p.y)
                p.y = min(p.y,sineView.frame.maxY)
            }
            
            let w = p.x - sineView.frame.minX
            let t = MonotonicSineCurveModel.getTWithW(w,wRangeMax:sineView.wR.y)
            
            let res = curveModel.findSineModel(x: t)
            guard let success = res["success"] as? Bool,
                  success,
                 let sinModel = res["model"] as? MonotonicSineCurveModel
            else { return }
            
            timeLineState = .isPanOnlyLine
           
            let v = sinModel.solveSineFuncGetVWithT(t-sinModel.vtP0.x)
            
            setTimeLineTo(point: CGPointMake(t, v))
            
            speedLab.text = String(format: "速度：%.1fx", currentPoint.y)
            speedLab.isHidden = false
            break
        
        default :
            break
        }
        
    }
    
    //设置时码线到某个点（t，v）
    @objc func setTimeLineTo(point:CGPoint){
        currentPoint = point
        
        var rec1 = timeLine.frame
        let x = sineView.wR.y*(point.x/maxTime)
        rec1.origin.x = sineView.frame.minX + x
        timeLine.frame = rec1
    }
    
    //检测当前位置是否是某个控制点
    @objc func checkCurrentPoint(){
        
        for index in 0..<pointArr.count {
            let p = pointArr[index]
            if abs(p.x - currentPoint.x) < 5*w_t {//误差区间5个点pt
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
            timeLineState = .isPlayEnd
            setTimeLineTo(point: pointArr.first!)
            return
        }
        
        //间隔距离pt
//        //间隔 1/sineView.tR.y 即1%时长对应的距离
//        marginXForAnimate = sineView.wR.y/sineView.tR.y
        let margin = marginXForAnimate > 0 ? marginXForAnimate : 2.0
        
        let w = currentTime/w_t + margin
        let v = curveModel.getValueWithTime(currentTime)
        currentPoint = CGPoint(x: w*w_t, y: v)
        var rec = timeLine.frame
        rec.origin.x = min(sineView.frame.minX+w, sineView.frame.maxX)
        
        //曲线速度微调，暂时采纳
        let v1 = CustomSineCurveModel.calculateNewSpeedValue(Float(v))

        let duration = (margin*w_t/sineView.tR.y*totalTime)/Double(v1)
//        let duration = (margin*w_t/sineView.tR.y*totalTime)/v
        
        //误差时间（DispatchQueue每轮代码运行耗时）
        offsetTime += Date().timeIntervalSince(nowDate)
        print("duration = \(duration)s offsetTime = \(offsetTime*1000.0)ms")
        
        print("2  t=\(currentTime) date=\(dateFormate.string(from: Date()))")
        let nowD = Date()
        let offT = offsetTime
        self.offsetTime = 0.0
        
        workItem.cancel()
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
    
    //    //锁定某时间对应的函数模型
    //    @objc func findSineModel(x:CGFloat)->MonotonicSineCurveModel{
    //        for model in sineView.funcParamsArr {
    //            if model.vtP0.x <= x && x <= model.vtP1.x {
    //                return model
    //            }
    //        }
    //        return MonotonicSineCurveModel(vtP0: CGPointMake(0.0, 1.0), vtP1: CGPointMake(100, 1.0))
    //    }
    //
    //    //某时刻的速度
    //    func getValueWithTime(_ t:CGFloat)->CGFloat{
    //
    //        let model = findSineModel(x: t)
    //        let v = model.solveSineFuncGetVWithT(t-model.vtP0.x)
    //
    //        return v
    //    }
    //
    //    //变速后的总时间
    //    func getFinallyTime() -> TimeInterval {
    //        var t = 0.0
    //        var timePercent = 0.0
    //
    //        while t < maxTime {
    //            let interval = 1.0
    //
    //            t += interval
    //            t = min(t, maxTime)
    //
    //            let model = findSineModel(x: t)
    //
    //            let v = model.solveSineFuncGetVWithT(t-model.vtP0.x)
    //
    //            timePercent += interval/v
    //        }
    //
    //        let finalTime = totalTime * (timePercent / maxTime)
    //        return finalTime
    //    }
    
}

//MARK: 变速曲线画布
//双Y坐标变速曲线（Y轴将分为>1和<1的上下两部分，上下部分的单位量不同）
class CustomSineCurveCanvas:UIView {
    
    //标速原点
    let vtO: CGPoint = CGPointMake(0.0, 1.0)
    //（竖轴）速度v阈值
    let vR:CGPoint = CGPointMake(0.1, 10.0)
    //（横轴）时间t阈值（百分值），t值可视为时间百分比
    let tR:CGPoint = CGPointMake(0.0, 100.0)
    
    //（视图显示的）标速原点
    var whO:CGPoint = CGPointMake(0.0, 90.0)
    //（视图）宽度w阈值
    var wR:CGPoint = CGPointMake(0.0, 350.0)
    //（视图）高度h阈值
    var hR:CGPoint = CGPointMake(0.0, 180.0) {
        didSet {
            self.H = (hR.y - hR.x)
        }
    }
    //画布高度
    private var H:CGFloat = 180.0
    
    
    //标准速度 1倍
    var normSpeed = 1.0
    //最小速度 0.1倍
    var minSpeed: CGFloat = 0.1
    //最大速度 10倍
    var maxSpeed: CGFloat = 10.0
    //总时长百分值（0～100）%
    let maxTime: CGFloat = 100
    
    
    //x轴描点步长（pt）
    private let step: CGFloat = 1.0
    
    
    var funcParamsArr:[MonotonicSineCurveModel] = [] {
        didSet {
            //刷新曲线
            setNeedsDisplay()
        }
    }
    
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        whO = CGPointMake(0.0, rect.height/2)
        wR = CGPointMake(0.0, rect.width)
        hR = CGPointMake(0.0, rect.height)
        
        
        print("draw")
        //加坐标轴
        addCoordinateAxis(originPoint: whO)
        
        guard funcParamsArr.count > 0 else {
            print("控制点不能少于两个")
            return
        }
        
        let path = UIBezierPath()
        path.lineWidth = 1.5
        UIColor(red: 1, green: 209/255, blue: 90/255, alpha: 1).setStroke()
        for i in 0..<funcParamsArr.count {
            
            let funcParams:MonotonicSineCurveModel = funcParamsArr[i]
            
            
            //w:视图坐标系x轴的值
            var w: CGFloat = 0
            path.move(to: CGPoint(x: funcParams.whP0.x, y: funcParams.solveSineFuncGetHWithW(w)))
            while w < (funcParams.whP1.x - funcParams.whP0.x) {
                w += step
                path.addLine(to: CGPoint(x: funcParams.whP0.x+w, y: funcParams.solveSineFuncGetHWithW(w)))
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
        labYmin.center = CGPoint(x: originPoint.x+30+5, y: bounds.height-10)
        addSubview(labYmin)
        sendSubviewToBack(labYmin)
        
        
        let line = UIBezierPath()
        line.lineWidth = 1.0
        UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1).setStroke()
        //标准速基线y=1.0x
        line.move(to: CGPoint(x: 20, y: bounds.height/2))
        line.addLine(to: CGPoint(x: bounds.width, y: bounds.height/2))
        //边框
        line.move(to: CGPoint(x: 0, y: 0))
        line.addLine(to: CGPoint(x: bounds.width-0.5, y: 0))
        line.addLine(to: CGPoint(x: bounds.width-0.5, y: bounds.height))
        line.addLine(to: CGPoint(x: 0.5, y: bounds.height))
        line.addLine(to: CGPoint(x: 0.5, y: 0))
        line.stroke()
        
        //虚线
        let lineDash = UIBezierPath()
        lineDash.lineWidth = 1.0
        UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1).setStroke()
        //5.5
        let ym0 = bounds.height/4
        lineDash.move(to: CGPoint(x: 0, y:ym0))
        lineDash.addLine(to: CGPoint(x: bounds.width, y: ym0))
        //0.55
        let ym1 = bounds.height*3/4
        lineDash.move(to: CGPoint(x: 0, y:ym1))
        lineDash.addLine(to: CGPoint(x: bounds.width, y: ym1))
        
        lineDash.setLineDash([10,10], count: 2, phase: 0)
        lineDash.stroke()
        
    }
    
}
