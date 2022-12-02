//
//  MonotonicSineModel.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/2.
//

//单调sine函数模型
import UIKit

/*
    y = a*sin(w*x + p) + d
    T = 2*Pi/w
    w = 2*Pi/T
 
    p:x左右偏移量，左+右-，偏移1/w*p
    w:x轴缩放1/w倍，即周期缩放1/w倍
    a: y的阈值【-a，a】
    d:y上下偏移量
    x：变量
    y：函数值
 */
class MonotonicSineModel: NSObject {
    //起点(峰点/谷点)
    var start: CGPoint = CGPoint(x: 0, y: 0)
    //终点（谷点/峰点）
    var end: CGPoint = CGPoint(x: 10, y: 10)
    
    init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }
    
    
    //振幅
    var a: CGFloat {
        get {
            abs(end.y-start.y)/2
        }
    }
    //周期T
    var T: CGFloat {
        get {
            abs(end.x-start.x)*2
        }
    }
    //波长缩放倍率
    var w:CGFloat {
        get {
            return 2*CGFloat.pi/T
        }
    }
    
    //x偏移量，<0右移，>0左移
    //注：变速曲线只取两点之间单调上升或下降的部分，因此需偏移1/4个周期
    var offsetX: CGFloat {
        get {
            if start.y < end.y {//上升
                return -T/4
            }else{//下降
                return T/4
            }
        }
    }
    
    //参数p
    var p:CGFloat {
        get {
            return w*offsetX
        }
    }
    
    //y偏移量，>0上移,<0下移
    var d: CGFloat {
        get {
            if start.y < end.y {//上升
                return start.y + a
            }else{//下降
                return end.y + a
            }
        }
    }
    //周期数(半个周期)
    let num: CGFloat = 0.5
    
    //通过x解sine函数得到y
    func solveSineFunctionWithX(_ x:CGFloat) -> CGFloat {
       return a*sin(w*x+p)+d
    }
}
