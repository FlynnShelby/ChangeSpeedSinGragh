//
//  CustomSineCurveModel.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/12/14.
//

import UIKit
//变速曲线模型
class CustomSineCurveModel: NSObject {
    
    //变速曲线名称
    var curveName = ""
    
    //总时长 s
    var totalTime = 10.0
    
    //初始控制点
    var originPointArr:[CGPoint] = [] 
    
    //控制点
    var pointArr:[CGPoint] = []{
        didSet {
             self.sineModelArr = createModelArr(pointArr)
        }
    }
    
    //是否开启智能补帧
    var isSmartFillFrame = false

    
    //时间最大百分值 %
    let maxTimePercent = 100.0
    
    //单调曲线模型组
    var sineModelArr:[MonotonicSineCurveModel] = []
    
    //（视图显示的）标速原点
    var whO:CGPoint = CGPointMake(0.0, 90.0)
    //（视图）宽度w阈值
    var wR:CGPoint = CGPointMake(0.0, 350.0)
    //（视图）高度h阈值
    var hR:CGPoint = CGPointMake(0.0, 180.0)
    
    //根据控制点和画布参数创建单调曲线模型组（不画曲线时，画布参数可忽略）
    func createModelArr(_ pArr:[CGPoint]) -> [MonotonicSineCurveModel] {
        var arr:[MonotonicSineCurveModel] = []
        if pointArr.count > 1 {
            
            //从第二个点开始创建model
            for i in 1...pointArr.count-1{
                let start = pointArr[i-1]
                let end = pointArr[i]
                
                let model = MonotonicSineCurveModel(vtP0: start, vtP1: end,whO:whO,wR:wR,hR:hR)
                
                arr.append(model)
            }
        }
        
        return arr
    }
    
    //锁定某时间对应的函数模型
    func findSineModel(x:CGFloat)->[String:Any]{
        for model in sineModelArr {
            if model.vtP0.x <= x && x <= model.vtP1.x {
                return ["success":true,"model":model]
            }
        }
        return ["success":false,"model":NSNull()]
    }
    
    //某时刻的速度
    func getValueWithTime(_ t:CGFloat)->CGFloat{
        
        let res = findSineModel(x: t)
        guard let success = res["success"] as? Bool,success != false,
              let model = res["model"] as? MonotonicSineCurveModel else {
            return 0.0
        }
        let v = model.solveSineFuncGetVWithT(t-model.vtP0.x)
        
        return v
    }
    
    //变速后的总时间
    func getFinallyTime() -> TimeInterval {
        var t = 0.0
        var timePercent = 0.0
        
        while t < maxTimePercent {
            let interval = 1.0
            
            t += interval
            t = min(t, maxTimePercent)
            
            let res = findSineModel(x: t)
            guard let success = res["success"] as? Bool,success != false,
                  let model = res["model"] as? MonotonicSineCurveModel else {
                return 0.0
            }
            let v = model.solveSineFuncGetVWithT(t-model.vtP0.x)
            
            timePercent += interval/v
        }
        
        let finalTime = totalTime * (timePercent / maxTimePercent)
        return finalTime
    }
}
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
    
    *双Y轴：Y轴实际阈值为v=【10，1】、（1，0.1】，上下半轴等距不等值，（0，1）为标速原点
         
    *双Y轴坐标y值转换公式
        ** 实际v-t图，tR=【0，totalTime】，vR=【0.1，10】，标速原点 vtO = （0，1）
        ** 函数x-y图，xR=【0，100】，yR=【-100，100】，原点 xyO=（0，0）,对应vtO和whO位置
        ** 视图w-h图，wR=【0，bounds.width】，hR=【0，bounds.height】,标速原点 whO=（0，bounds.height/2），H = (hR.y - hR.x)
     
    //一、实际值v => 函数值y
        v >= vtO.y: y = (v-vtO.y)/(vR.y-vtO.y)*yR.y
        v < vtO.y:  y = (v-vtO.y)/(vtO.y-vR.x)*yR.y
     //二、函数值y => 视图坐标值h
        h = whO.y-(y/yR.y)*(H/2)
     //三、视图坐标值h => 函数值y
        y = (whO.y-h)/(H/2)*yR.y
     //四、函数值y => 实际值v
        y >= 0: v = (y/yR.y)*(vR.y-vtO.y)+vtO.y
        y < 0:  v = (y/yR.y)*(vtO.y-vR.x)+vtO.y
 
    //辅一、视图坐标值h => 实际值v
        h <= whO.y:  v = (whO.y-h)/(H/2)*(vR.y-vtO.y)+vtO.y
        h > whO.y:   v = (whO.y-h)/(H/2)*(vtO.y-vR.x)+vtO.y
    //辅二、实际值v => 视图坐标值h
        v >= vtO.y: h = whO.y-(v-vtO.y)/(vR.y-vtO.y)*(H/2)
        v < vtO.y:  h = whO.y-(v-vtO.y)/(vtO.y-vR.x)*(H/2)
 */
//单调曲线模型
class MonotonicSineCurveModel: NSObject {
    
    //v-t坐标系参数
    //标速原点
    let vtO: CGPoint = CGPointMake(0.0, 1.0)
    //（竖轴）速度v阈值
    let vR:CGPoint = CGPointMake(0.1, 10.0)
    //（横轴）时间t阈值（百分值），t值可视为时间百分比
    let tR:CGPoint = CGPointMake(0.0, 100.0)
    //该段曲线起点
    var vtP0:CGPoint = CGPointMake(0.0, 1.0)
    //该段曲线终点
    var vtP1:CGPoint = CGPointMake(100.0, 1.0)
    
    //x-y坐标系参数（数学坐标系）
    //原点
    let xyO:CGPoint = CGPointMake(0.0, 0.0)
    //x阈值
    let xR:CGPoint = CGPointMake(0.0, 100.0)
    //y阈值
    let yR:CGPoint = CGPointMake(-100.0, 100.0)
    //该段曲线起点
    private var p0 = CGPointMake(0.0, 0.0)
    //该段曲线终点
    private var p1 = CGPointMake(100.0, 0.0)
    
    //w-h坐标系参数 (画曲线需以下参数，不画曲线可忽略)
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
    //该段曲线起点
    var whP0:CGPoint {
        get {
            CGPointMake(getWWithT(vtP0.x), getHWithV(vtP0.y))
        }
    }
    //该段曲线终点
    var whP1:CGPoint {
        get {
            CGPointMake(getWWithT(vtP1.x), getHWithV(vtP1.y))
        }
    }
    
    init(vtP0:CGPoint,vtP1:CGPoint,
         whO:CGPoint = CGPointMake(0.0, 90.0),
         wR:CGPoint = CGPointMake(0.0, 350.0),
         hR:CGPoint = CGPointMake(0.0, 180.0)) {
        super.init()
        
        self.vtP0 = vtP0
        self.vtP1 = vtP1
        
        self.p0 = CGPoint(x: getXWithT(vtP0.x), y: getYWithV(vtP0.y))
        self.p1 = CGPoint(x: getXWithT(vtP1.x), y: getYWithV(vtP1.y))
        
        a = abs(p1.y-p0.y)/2.0
        T = abs(p1.x-p0.x)*2
        w = 2*CGFloat.pi/T
        if p0.y < p1.y {//上升
            offsetX =  -T/4
            d = p0.y + a
        }else{//下降
            offsetX =  T/4
            d = p1.y + a
        }
        p = w*offsetX
        
        
         
        // whO、wR、hR 不画曲线可不设值
        self.whO = whO
        self.wR = wR
        self.hR = hR
    }
    
    //振幅
    private var a: CGFloat = 0.0
    //周期T
    private var T: CGFloat = 200.0
    
    //波长缩放倍率
    private var w:CGFloat = 2*CGFloat.pi/200.0
    
    //x偏移量，<0右移，>0左移
    //注：变速曲线只取两点之间单调上升或下降的部分，因此需偏移1/4个周期
    private var offsetX: CGFloat = -200.0/4
    
    //参数p
    private var p:CGFloat = -CGFloat.pi/2
    
    //y偏移量，>0上移,<0下移
    private var d: CGFloat = 0.0
    //周期数(半个周期)
    let num: CGFloat = 0.5
    
    
    //解sine函数公式得到y
    // x => y
    func solveSineFuncGetYWithX(_ x:CGFloat) -> CGFloat {
        return  a*sin(w*x+p)+d
    }
    
    //变式一、解sine函数公式得到h
    // w => h
    func solveSineFuncGetHWithW(_ w:CGFloat) -> CGFloat {
        let x = getXWithW(w)
        let y = solveSineFuncGetYWithX(x)
        let h = getHWithY(y)
        return h
    }
    
    //变式二、解sine函数公式得到v (t为百分值)
    // t => v
    func solveSineFuncGetVWithT(_ t:CGFloat) -> CGFloat {
        let x = getXWithT(t)
        let y = solveSineFuncGetYWithX(x)
        let v = getVWithY(y)
        return v
    }
    
    //竖轴转换
    // v => y
    func getYWithV(_ v:CGFloat) -> CGFloat {
        if v >= vtO.y {
            let y = (v-vtO.y)/(vR.y-vtO.y)*yR.y
            return y
        }else{
            let y = (v-vtO.y)/(vtO.y-vR.x)*yR.y
            return y
        }
    }
    
    // y => h
    func getHWithY(_ y:CGFloat) -> CGFloat {
        let h = whO.y-(y/yR.y)*(H/2)
        return h
    }
    
    // h => y
    func getYWithH(_ h:CGFloat) -> CGFloat {
        let y = (whO.y-h)/(H/2)*yR.y
        return y
    }
    
    // y => v
    func getVWithY(_ y:CGFloat) -> CGFloat {
        if y >= 0 {
            let v = (y/yR.y)*(vR.y-vtO.y)+vtO.y
            return v
        }else{
            let  v = (y/yR.y)*(vtO.y-vR.x)+vtO.y
            return v
        }
    }
    
    // 辅一、 h => v (该公式与函数无关)
    func getVWithH(_ h:CGFloat) -> CGFloat {
        if h <= whO.y {
            let v = (whO.y-h)/(H/2)*(vR.y-vtO.y)+vtO.y
            return v
        }else{
            let v = (whO.y-h)/(H/2)*(vtO.y-vR.x)+vtO.y
            return v
        }
    }
    class func getVWithH(_ h:CGFloat,whO:CGPoint,H:CGFloat,vtO:CGPoint,vR:CGPoint)->CGFloat{
        if h <= whO.y {
            let v = (whO.y-h)/(H/2)*(vR.y-vtO.y)+vtO.y
            return v
        }else{
            let v = (whO.y-h)/(H/2)*(vtO.y-vR.x)+vtO.y
            return v
        }
    }
    
    // 辅二、 v => h
    func getHWithV(_ v:CGFloat) -> CGFloat {
        if v >= vtO.y {
            let h = whO.y-(v-vtO.y)/(vR.y-vtO.y)*(H/2)
            return h
        }else{
            let h = whO.y-(v-vtO.y)/(vtO.y-vR.x)*(H/2)
            return h
        }
    }
    class func getHWithV(_ v:CGFloat,whO:CGPoint,H:CGFloat,vtO:CGPoint,vR:CGPoint)->CGFloat {
        if v >= vtO.y {
            let h = whO.y-(v-vtO.y)/(vR.y-vtO.y)*(H/2)
            return h
        }else{
            let h = whO.y-(v-vtO.y)/(vtO.y-vR.x)*(H/2)
            return h
        }
    }
     
    // 横轴转换
    // t => x
    func getXWithT(_ t:CGFloat) -> CGFloat {
        return (t/tR.y)*xR.y
    }
    
    // w => x
    func getXWithW(_ w:CGFloat) -> CGFloat {
        return (w/wR.y)*xR.y
    }
    class func getXWithW(_ w:CGFloat,wRangeMax:CGFloat = 350.0) -> CGFloat {
        return (w/wRangeMax)*100
    }
    
    // t => w
    func getWWithT(_ t:CGFloat) -> CGFloat {
        return (t/tR.y)*wR.y
    }
    class func getWWithT(_ t:CGFloat, wRangeMax:CGFloat) -> CGFloat {
        return (t/100)*wRangeMax
    }
    
    // w => t
    func getTWithW(_ w:CGFloat,wRangeMax:CGFloat = 350.0) -> CGFloat {
        return (w/wRangeMax)*tR.y
    }
    class func getTWithW(_ w:CGFloat,wRangeMax:CGFloat) -> CGFloat{
        return (w/wRangeMax)*100
    }
    
    
}
