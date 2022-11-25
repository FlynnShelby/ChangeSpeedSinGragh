//
//  SinGraghVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/24.
//

import UIKit

class SinGraghVC: UIViewController {
    
    var sineView = SineView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        sineView.frame = CGRect(x: 0, y: 200, width: KScreenW, height: 200)
        sineView.backgroundColor = .cyan
        
        view.addSubview(sineView)
        
    }
    


}
