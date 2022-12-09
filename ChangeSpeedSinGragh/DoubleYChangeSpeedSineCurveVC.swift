//
//  DoubleYChangeSpeedSineCurveVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/7.
//

import UIKit
//MARK: 双Y坐标变速曲线（Y轴将分为>1和<1的上下两部分，上下部分的单位量不同）
class DoubleYChangeSpeedSineCurveVC: UIViewController {

    var sineView = DoubleYChangeSpeedSineCurveView()
    
    var addBtn:UIButton = UIButton(type: .system)
    var deleteBtn:UIButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        sineView.frame = CGRect(x: 20, y: 200, width: KScreenW-40, height: 200)
        sineView.backgroundColor = .cyan
        sineView.currentPointBlock = {[weak self] p in
            guard let arr = self?.sineView.pointArr else {return}
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
                self?.deleteBtn.backgroundColor = .lightGray
            }else{
                self?.deleteBtn.isEnabled = true
                self?.deleteBtn.backgroundColor = .orange
            }
        }
        
        view.addSubview(sineView)
        
        addBtn.frame = CGRect(x: (KScreenW-68)/2, y: KScreenH-KSafeBottom-26, width: 68, height: 26)
        addBtn.backgroundColor = .orange
        addBtn.layer.cornerRadius = 2
        addBtn.setTitle("+ 添加点", for: .normal)
        addBtn.setTitleColor(.black, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(addBtn)
        addBtn.addTarget(self, action: #selector(addBtnClicked), for: .touchUpInside)
        addBtn.isHidden = true
        
        deleteBtn.frame = CGRect(x: (KScreenW-68)/2, y: KScreenH-KSafeBottom-26, width: 68, height: 26)
        deleteBtn.backgroundColor = .lightGray
        deleteBtn.layer.cornerRadius = 2
        deleteBtn.setTitle("- 删除点", for: .normal)
        deleteBtn.setTitleColor(.black, for: .normal)
        deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        view.addSubview(deleteBtn)
        deleteBtn.addTarget(self, action: #selector(deleteBtnClicked), for: .touchUpInside)
        deleteBtn.isHidden = false
        deleteBtn.isEnabled = false
        
    }

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
        
    }
    
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
    }
}
