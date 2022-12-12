//
//  CustomChangeSpeedCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/12.
//

import UIKit
//MARK: 双Y坐标变速曲线（Y轴将分为>1和<1的上下两部分，上下部分的单位量不同）
class CustomChangeSpeedCurveVC: UIViewController {

    var sineView = CustomChangeSpeedCurveView()
    
    //总时长（秒）
    var maxTime: CGFloat = 35.0 {
        didSet {
            sineView.maxTime = maxTime
        }
    }
    //峰值点(t,v)
    var pointArr: [CGPoint] = []{
        didSet {
            sineView.pointArr = pointArr
            sineView.pointOperationRecord.append(pointArr)
            sineView.currentRecordIndex = 0
            
            
        }
    }
    
    var resetBtn:UIButton = UIButton(type: .custom)
    var titleLab:UILabel = UILabel()
    var confirmBtn:UIButton = UIButton(type: .custom)
    
    var addBtn:UIButton = UIButton(type: .system)
    var deleteBtn:UIButton = UIButton(type: .system)
    
    var totalTimeLab:UILabel = UILabel()
    var arrowIcon:UIImageView = UIImageView()
    var finalTimeLab:UILabel = UILabel()
    
    //智能补充
    var smartFillFrameBtn:UIButton = UIButton(type: .custom)
    
    //撤消
    lazy var revocationBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "revocation"), for: .normal)
        btn.frame = CGRect(x: 20, y: view.frame.minY-34, width: 30, height: 30)
        view.superview?.addSubview(btn)
        btn.addTarget(self, action: #selector(revocationBtnClicked), for: .touchUpInside)
        return btn
    }()
    //恢复
    lazy var recoverBtn:UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "recover"), for: .normal)
        btn.frame = CGRect(x: 64, y: view.frame.minY-34, width: 30, height: 30)
        view.superview?.addSubview(btn)
        btn.addTarget(self, action: #selector(recoverBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1)

        
        //变速曲线图
        sineView.frame = CGRect(x: 20, y: 69, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .clear
        sineView.currentPointBlock = {[weak self] p in
            guard let this = self,let arr = self?.sineView.pointArr else {return}
            var b = false
            for point in arr {
                if abs(point.x - p.x) < 5*(self?.sineView.x_t)! {
                    b = true
                }
            }
            self?.addBtn.isHidden = b
            self?.deleteBtn.isHidden = !b
            
            if abs(arr.first!.x - p.x) < 5*(self?.sineView.x_t)!
                || abs(arr.last!.x - p.x) < 5*(self?.sineView.x_t)! {
                self?.deleteBtn.isEnabled = false
                self?.deleteBtn.backgroundColor = UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1)
            }else{
                self?.deleteBtn.isEnabled = true
                self?.deleteBtn.backgroundColor = .white
            }
            
            self?.finalTimeLab.text = String(format: "%.1fs", self!.sineView.getFinallyTime())
            
            if this.isAllPointYGreaterThan1() {
                this.smartFillFrameBtn.isSelected = false
                this.smartFillFrameBtn.isEnabled = false
            }else{
                this.smartFillFrameBtn.isEnabled = true
            }
        }
        
        sineView.panGestureEndBlock = { [weak self] curveView in
            self?.refreshRevocationAndRecoverBtnEnableState()
        }
        view.addSubview(sineView)
        
        //重置
        resetBtn.setImage(UIImage(named: "curveReset"), for: .normal)
        resetBtn.setTitle("重置", for: .normal)
        resetBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        resetBtn.setTitleColor(.white, for: .normal)
        resetBtn.frame = CGRect(x: 0, y: 0, width: 60, height: 44)
        resetBtn.center = CGPoint(x: 16+30, y: sineView.frame.minY-25-22)
        view.addSubview(resetBtn)
        resetBtn.addTarget(self, action: #selector(resetBtnClicked), for: .touchUpInside)
       
        //标题
        titleLab.textColor = .white
        titleLab.font = UIFont.systemFont(ofSize: 16)
        titleLab.text = "变速曲线"
        titleLab.textAlignment = .center
        titleLab.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
        titleLab.center = CGPoint(x: view.center.x, y: sineView.frame.minY-25-22)
        view.addSubview(titleLab)
        
        //确认
        confirmBtn.setImage(UIImage(named: "curveConfirm"), for: .normal)
        confirmBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        confirmBtn.center = CGPoint(x: KScreenW-(13+22), y: sineView.frame.minY-25-22)
        view.addSubview(confirmBtn)
        confirmBtn.addTarget(self, action: #selector(confirmBtnClicked), for: .touchUpInside)
        
        //添加控制点按钮
        addBtn.frame = CGRect(x: (KScreenW-68)/2, y: sineView.frame.maxY+16, width: 68, height: 26)
        addBtn.backgroundColor = .white
        addBtn.layer.cornerRadius = 2
        addBtn.setTitle("+ 添加点", for: .normal)
        addBtn.setTitleColor(.black, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(addBtn)
        addBtn.addTarget(self, action: #selector(addBtnClicked), for: .touchUpInside)
        addBtn.isHidden = true
        
        //删除控制点按钮
        deleteBtn.frame = CGRect(x: (KScreenW-68)/2, y: sineView.frame.maxY+16, width: 68, height: 26)
        deleteBtn.backgroundColor = UIColor(red: 82/255, green: 82/255, blue: 82/255, alpha: 1)
        deleteBtn.layer.cornerRadius = 2
        deleteBtn.setTitle("- 删除点", for: .normal)
        deleteBtn.setTitleColor(.black, for: .normal)
        deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(deleteBtn)
        deleteBtn.addTarget(self, action: #selector(deleteBtnClicked), for: .touchUpInside)
        deleteBtn.isHidden = false
        deleteBtn.isEnabled = false
        
        //时长
        totalTimeLab.textColor = UIColor(red: 139/255, green: 139/255, blue: 139/255, alpha: 1)
        totalTimeLab.font = UIFont.systemFont(ofSize: 12)
        totalTimeLab.text = String(format: "时长%.1fs", sineView.maxSpeed)
        totalTimeLab.frame = CGRect(x: 0, y: 0, width: 60, height: 18)
        totalTimeLab.center = CGPoint(x: 54, y: deleteBtn.center.y)
        view.addSubview(totalTimeLab)
        
        arrowIcon.image = UIImage(named: "timeArrow")
        arrowIcon.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
        arrowIcon.center = CGPoint(x: totalTimeLab.frame.maxX+4+2.5, y: deleteBtn.center.y)
        view.addSubview(arrowIcon)
        
        finalTimeLab.textColor = .white
        finalTimeLab.font = UIFont.systemFont(ofSize: 12)
        finalTimeLab.text = String(format: "%.1fs", sineView.getFinallyTime())
        finalTimeLab.frame = CGRect(x: 0, y: 0, width: 60, height: 18)
        finalTimeLab.center = CGPoint(x: arrowIcon.frame.maxX+4+30, y: deleteBtn.center.y)
        view.addSubview(finalTimeLab)
        
        //智能补帧
        smartFillFrameBtn.setImage(UIImage(named: "curveSmart_normal"), for: .normal)
        smartFillFrameBtn.setImage(UIImage(named: "curveSmart_selected"), for: .selected)
        smartFillFrameBtn.setTitle(" 智能补帧", for: .normal)
        smartFillFrameBtn.setTitleColor(.white, for: .normal)
        smartFillFrameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        smartFillFrameBtn.frame = CGRect(x: 0, y: 0, width: 76, height: 18)
        smartFillFrameBtn.center = CGPoint(x: KScreenW-24-38, y: deleteBtn.center.y)
        view.addSubview(smartFillFrameBtn)
        smartFillFrameBtn.addTarget(self, action: #selector(smartFillFrameBtnClicked), for: .touchUpInside)
         
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshRevocationAndRecoverBtnEnableState()
    }
    
//MARK: 添加
    @objc func addBtnClicked(){
        print("newP=\(String(describing: sineView.currentPoint))")
        sineView.play = false
        
        let p = sineView.currentPoint
        guard sineView.pointArr.count > 1 else {return}
        for i in 1...sineView.pointArr.count-1 {
            let a = sineView.pointArr[i-1]
            let b = sineView.pointArr[i]
            if a.x < p.x && p.x < b.x {
                sineView.pointArr.insert(p, at: i)
                sineView.currentPoint = p
            }
        }
        
        //记录操作
        sineView.pointOperationRecord.append(sineView.pointArr)
        sineView.currentRecordIndex += 1
    }
//MARK: 删除
    @objc func deleteBtnClicked(){
        print("newP=\(String(describing: sineView.currentPoint))")
        let p = sineView.currentPoint
        for index in 0...sineView.pointArr.count-1 {
            let point = sineView.pointArr[index]
            if abs(point.x - p.x) < 5*(self.sineView.x_t) {
                sineView.pointArr.remove(at: index)
                return
            }
        }
        
        //记录操作
        sineView.pointOperationRecord.append(sineView.pointArr)
        sineView.currentRecordIndex += 1
    }
    
//MARK: 智能补帧
    @objc func smartFillFrameBtnClicked(_ sender:UIButton){
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            sineView.marginXForAnimate = 1.0
        }else{
            sineView.marginXForAnimate = 2.0
        }
    }
    
    //是否所有控制点的速度都>1
    func isAllPointYGreaterThan1() -> Bool {
        let arr = sineView.pointArr.filter {$0.y <= 1}
        return arr.count == 0
    }
    
//MARK: 撤消一步操作
    @objc func revocationBtnClicked(_ sender:UIButton){
        if sineView.pointOperationRecord.count > 1
            && sineView.currentRecordIndex-1 >= 0 {
            sineView.isSpecialOperation = true
            sineView.play = false
            sineView.currentRecordIndex -= 1
            sineView.pointArr = sineView.pointOperationRecord[sineView.currentRecordIndex]
        }
        refreshRevocationAndRecoverBtnEnableState()
    }
    
//MARK: 恢复一步操作
    @objc func recoverBtnClicked(_ sender:UIButton){
        if sineView.pointOperationRecord.count > 1
            && sineView.currentRecordIndex+1 < sineView.pointOperationRecord.count {
            sineView.isSpecialOperation = true
            sineView.play = false
            sineView.currentRecordIndex += 1
            sineView.pointArr = sineView.pointOperationRecord[sineView.currentRecordIndex]
        }
        refreshRevocationAndRecoverBtnEnableState()
    }
    //刷新 撤消按钮 和 恢复按钮 的可用状态
    func refreshRevocationAndRecoverBtnEnableState(){
        revocationBtn.isEnabled = sineView.currentRecordIndex != 0
        recoverBtn.isEnabled = sineView.currentRecordIndex != sineView.pointOperationRecord.count-1
    }
    
//MARK: 重置
    @objc func resetBtnClicked(){
        sineView.play = false
        sineView.isSpecialOperation = true
        sineView.pointArr = pointArr
        //清空记录
        sineView.pointOperationRecord.removeAll()
        //记录操作
        sineView.pointOperationRecord.append(sineView.pointArr)
        sineView.currentRecordIndex = 0
        
        refreshRevocationAndRecoverBtnEnableState()
    }
//MARK: 确定
    @objc func confirmBtnClicked(){
        print("\(sineView.pointArr)")
    }
    
    
}
