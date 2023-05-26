//
//  ViewController.swift
//  OpenGLVideoPlayer
//
//  Created by Ray on 2023/5/25.
//


import UIKit

class ViewController: UIViewController {
    var mediaModel: MovieDecode = MovieDecode.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        mediaModel.open("")
    }


}

