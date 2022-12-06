//
//  DoubelYMonotonicSineMode.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/3.
//


//双Y轴单调sine函数模型
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
    //一、实际值v => 函数值y（v=【10，1】、（1，0.1】，原点o=（0，1））
        v>=1: y=v-1
        v<1:  y=(v-1)*10
    //二、函数值y => 视图坐标值h（y=【9，-9】，原点o=（0，0））
        h=(H/2)-y/10*(H/2)
    //三、视图坐标值h => 函数值y（h=【0，H】，H=bounds.height，原点o=（0，H/2））
        y=((H/2)-h)/(H/2)*10
    //四、函数值y => 实际值v（y=【9，-9】，原点o=（0，0））
        y>=0: v=y+1
        y<0:  v=1+y/10
 
    //辅一、视图坐标值h => 实际值v（h=【0，H】，H=bounds.height，原点o=（0，H/2））
        h<=H/2: v=((H/2)-h)/(H/2)*10+1
        h>H/2:  v=1+((H/2)-h)/(H/2)
    //辅二、实际值v => 视图坐标值h（v=【10，1】、（1，0.1】，原点o=（0，1））
        v>=1: h=(H/2)-(v-1)/10*(H/2)
        v<1:  h=(H/2)-(v-1)*(H/2)
 */
class DoubelYMonotonicSineMode: NSObject {
    //双Y坐标系(实际值)
    //起点
    var p0:CGPoint = CGPoint(x: 0, y: 1)
    //终点
    var p1:CGPoint = CGPoint(x: 10, y: 10)
    
    init(p0: CGPoint, p1: CGPoint) {
        self.p0 = p0
        self.p1 = p1
        
        //转函数坐标
        if p0.y >= 1 {
            self.start = CGPoint(x: p0.x, y: p0.y-1)
        }else{
            self.start = CGPoint(x: p0.x, y: (p0.y-1)*10)
        }
        
        if p1.y >= 1 {
            self.end = CGPoint(x: p1.x, y: p1.y-1)
        }else{
            self.end = CGPoint(x: p1.x, y: (p1.y-1)*10)
        }
        
    }
    
    //函数数学坐标系
    //起点(峰点/谷点)
    var start: CGPoint = CGPoint(x: 0, y: 0)
    //终点（谷点/峰点）
    var end: CGPoint = CGPoint(x: 10, y: 9)
        
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
    
    //通过x解sine函数得到y
    func solveSineFunctionWithX(_ x:CGFloat) -> CGFloat {
       return a*sin(w*x+p)+d
    }

    //计算视图坐标h
    func getPointYAtView(_ x:CGFloat,_ o:CGPoint) -> CGFloat {
        let y = solveSineFunctionWithX(x)
        let h = (o.y)-y/10*(o.y)
        return h
    }
    
    //计算实际值
    func getRealValue(_ x:CGFloat) -> CGFloat {
        let y = solveSineFunctionWithX(x)
        
        if y >= 0 {
            return y+1
        }else{
            return 1+y/10
        }
    }
}
