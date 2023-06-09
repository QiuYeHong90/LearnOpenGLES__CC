//
//  MovieGLView.swift
//  OpenGLVideoPlayer
//
//  Created by Ray on 2023/5/25.
//

import UIKit
let vertexShaderString = """
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
"""



class MovieGLView: UIView {
    
    
}
