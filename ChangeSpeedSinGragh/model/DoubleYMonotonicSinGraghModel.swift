//
//  DoubleYMonotonicSinGraghModel.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/6.
//

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
    
    *双Y轴：Y轴实际阈值为v=【10，1】、（1，0.1】，上下半轴等距不等值，（0，1）为原点
         
    *双Y轴坐标y值转换公式
    （注：高度阈值h=【0，H】，视图原点o=（0，H/2），实际阈值v=【10，1】、（1，0.1】，实际原点v_o=（0，1））
    //辅一、视图坐标值h => 实际值v
        h<=H/2: v=((H/2)-h)/(H/2)*10+1
        h>H/2:  v=1+((H/2)-h)/(H/2)
    //辅二、实际值v => 视图坐标值h
        v>=1: h=(H/2)-(v-1)/10*(H/2)
        v<1:  h=(H/2)-(v-1)*(H/2)
 */
class DoubleYMonotonicSinGraghModel: NSObject {

    //双Y坐标系(实际值)
    //起点
    var p0:CGPoint = CGPoint(x: 0, y: 1)
    //终点
    var p1:CGPoint = CGPoint(x: 10, y: 10)
    //x轴单位时长s
    var step_t = 0.1
    //原点
    var o:CGPoint = CGPoint(x: 0, y: 100)
    
    init(p0: CGPoint, p1: CGPoint, step_t: Double = 0.1, o:CGPoint) {
        self.p0 = p0
        self.p1 = p1
        self.step_t = step_t
        self.o = o
        
        //实际坐标转数学坐标
        self.start = CGPoint(x: p0.x/step_t, y: Self.getPointYAtView(p0.y, o: o))
        self.end = CGPoint(x: p1.x/step_t, y: Self.getPointYAtView(p1.y, o: o))
    }
   
    
    //数学坐标系
    //起点(峰点/谷点)
    var start: CGPoint = CGPoint(x: 0, y: 100)
    //终点（谷点/峰点）
    var end: CGPoint = CGPoint(x: 100, y: 10)
        
    //振幅
    var a: CGFloat {
        get {
            abs(end.y-start.y)/2.0
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
    
    //通过x解sine函数得到y (x:宽，y：高)
    func solveSineFunctionWithX(_ x:CGFloat) -> CGFloat {
       return a*sin(w*x+p)+d
    }
    
    //v=>h
    class func getPointYAtView(_ v:CGFloat, o:CGPoint) -> CGFloat {
        var h = 0.0
        if v >= 1 {
            h=(o.y)-(v-1)/10*(o.y)
        }else{
            h=(o.y)-(v-1)*(o.y)
        }
        
        return h
    }
    
    //h=>v
    class func getValueWithPointYAtView(_ h:CGFloat,o:CGPoint)->CGFloat {
        var v = 0.0
        
        if h <= o.y {
            v=(o.y-h)/o.y*10+1
        }else{
            v=1+(o.y-h)/o.y
        }
        
        return v
    }

}
