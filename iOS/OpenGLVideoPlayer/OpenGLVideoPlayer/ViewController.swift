//
//  ViewController.swift
//  OpenGLVideoPlayer
//
//  Created by Ray on 2023/5/25.
//


import UIKit

class ViewController: UIViewController {
    var mediaModel: MovieDecode = MovieDecode.init()
    var videoTool: SHVideoDecode = SHVideoDecode.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
//        mediaModel.open("")
    }

    @IBAction func takeAudio() {
//        SHVideoDecode
        let path = Bundle.main.path(forResource: "test.mp4", ofType: nil)!
//        self.videoTool.open(path)
//        self.videoTool.takeVideo(path)
        self.videoTool.remux(path)
    }
}

