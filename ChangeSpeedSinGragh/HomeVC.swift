//
//  HomeVC.swift
//  ChangeSpeedSinGragh
//
//  Created by XieLinFu_Mac on 2022/11/24.
//

import UIKit

let KScreenW = UIScreen.main.bounds.width
let KScreenH = UIScreen.main.bounds.height

class HomeVC: UIViewController {

    var titleArr: [String] = ["Sin常规曲线","Sin上移","Sin下移","Sin左移","Sin右移","Sin周期大小","Sin幅度大小","Sin周期数量","Sin半周期-上升","Sin半周期下降","Sin变速曲线","Sin可增减变速曲线","Sin自定义变速曲线"]
    
    var tableView = UITableView(frame: CGRectZero, style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "sin曲线demo集"
        
        
        tableView.frame = CGRect(x: 0, y: 0, width: KScreenW, height: KScreenH)
        tableView.rowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
    }
    
}

extension HomeVC : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = titleArr[indexPath.row]
        
        var config = UIListContentConfiguration.cell()
        config.text = titleArr[indexPath.row]
        config.textProperties.color = .black
        config.textProperties.font = UIFont.systemFont(ofSize: 14)
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var vc = UIViewController()
        
        switch indexPath.row {
        case 0://常规
//            vc = SinGraghVC()
            vc = SineCurveVC()
            break
        case 1://上移
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,0.0,20.0,1.0)
            vc = sinVC
            break
        case 2://下移
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,0.0,-20.0,1.0)
            vc = sinVC
            break
        case 3://左移
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,-20.0,0.0,1.0)
            vc = sinVC
            break
        case 4://右移
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,20.0,0.0,1.0)
            vc = sinVC
            break
        case 5://周期大小
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,300.0,0.0,0.0,1.0)
            vc = sinVC
            break
        case 6://振幅大小
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (80.0,200.0,0.0,0.0,1.0)
            vc = sinVC
            break
        case 7://周期数
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,100.0,0.0,0.0,3.0)
            vc = sinVC
            break
        case 8://半周期上升
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,1/4*200,50.0,0.5)
            vc = sinVC
            break
        case 9://半周期下降
            let sinVC = SineCurveVC()
            sinVC.sineView.funcParams = (50.0,200.0,-1/4*200,50.0,0.5)
            vc = sinVC
            break
        default:
            vc = SineCurveVC()
            break
        }
        
        vc.title = titleArr[indexPath.row]
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

