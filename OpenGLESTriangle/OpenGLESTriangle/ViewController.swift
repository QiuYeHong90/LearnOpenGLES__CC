//
//  ViewController.swift
//  OpenGLESTriangle
//
//  Created by Mac on 2023/5/24.
//

import UIKit


class TestView: UIView {
    var shapLayer = CAShapeLayer()
    override func layoutSubviews() {
        super.layoutSubviews()
        // 创建带有圆角的 UIBezierPath 对象
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height), cornerRadius: 50)
        // 添加闭合路径
        path.close()

        // 创建不带圆角的 CAShapeLayer 对象
        
        shapLayer.backgroundColor = UIColor.red.cgColor
        shapLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        shapLayer.path = path.cgPath
        if shapLayer.superlayer == self {
            return
        }
        self.layer.addSublayer(shapLayer)
    }
}


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }


}

