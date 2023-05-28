//
//  SHGLView.swift
//  OpenGLESTriangle
//
//  Created by Mac on 2023/5/24.
//

import UIKit

class SHGLView: UIView {
    /// 上下文 openGL 是状态机 apple 用 EAGLContext 管理状态机
    var myContext:EAGLContext?
    //   颜色顶点缓冲的唯一id
    var myColorFrameBuffer:GLuint = 0
    /// 颜色缓冲的唯一id
    var myColorRenderBuffer:GLuint = 0
    /// 程序的id
    var myProgram:GLuint?
    
    var positionSlot:GLuint = 0

    var colorSlot: GLuint = 0
    
    // 只有CAEAGLLayer 类型的 layer 才支持 OpenGl 描绘
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        initCommon()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initCommon()
    }
    func initCommon() {
        self.setupLayer()
        self.setupContext()
    }
    fileprivate func setupLayer() {
        let eagLayer = layer as? CAEAGLLayer

        // CALayer 默认是透明的，必须将它设为不透明才能让其可见
        eagLayer?.isOpaque = true
        // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
        eagLayer?.drawableProperties = [
            // 显示过的画面是否需要保存, 默认不保存
            kEAGLDrawablePropertyRetainedBacking:false,kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
    }
    /**
     4、至此 layer 的配置已经就绪，下面我们来创建也设置 OpenGL ES 相关的东西。首先，我们需要创建OpenGL ES 渲染上下文(在iOS 中对应的实现为EAGLContext)，这个 context 管理所有使用OpenGL ES 进行描绘的状态，命令以及资源信息。这与使用 Core Graphics 进行描绘必须创建 Core Graphics Context 的道理是一样。
       
      Core Animation
     */
    fileprivate func setupContext() {
        // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 3.0
        myContext = EAGLContext(api: .openGLES3)
        
        if myContext == nil {
            print("Failed to initialize OpenGLES 3.0 context")
            return
        }
        // 设置为当前上下文
        if !EAGLContext.setCurrent(myContext) {
            print("Failed to set current OpenGL context")
            return
        }
    }
    
    fileprivate func setupBuffer() {
//        申请渲染缓冲id
        var buffer:GLuint = 0
        glGenRenderbuffers(1, &buffer)
        myColorRenderBuffer = buffer
//        设置为渲染类型GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        // 为 颜色缓冲区 分配存储空间
        myContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer as? CAEAGLLayer)
        
//        申请顶点缓冲id 唯一值
        glGenFramebuffers(1, &buffer)
        myColorFrameBuffer = buffer
        // 为告诉openGLES 我是GL_FRAMEBUFFER 类型 就是我是顶点缓冲类型
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }
    
    
    
    fileprivate func setupProgram() {
        myProgram = ShaderTool.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
        guard let myProgram = myProgram else {
            return
        }
        
        glUseProgram(myProgram)
    
        positionSlot = GLuint(glGetAttribLocation(myProgram, "vPosition"))
        colorSlot = GLuint(glGetAttribLocation(myProgram, "a_Color"))
    }
    fileprivate func destoryRenderAndFrameBuffer() {
        //        当 UIView 在进行布局变化之后，由于 layer 的宽高变化，导致原来创建的 renderbuffer不再相符，我们需要销毁既有 renderbuffer 和 framebuffer。下面，我们依然创建私有方法 destoryRenderAndFrameBuffer 来销毁生成的 buffer
        glDeleteFramebuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
        glDeleteRenderbuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
    }
    fileprivate func render() {
        
        glClearColor(0, 1.0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        let vertices: [GLfloat] = [
            0, 0.5, 0,
            -0.5, -0.5, 0,
            0.5, -0.5, 0
        ]
        
        let colors: [GLfloat] = [
            1, 0, 0, 1,
            0, 1, 0, 1,
            0, 0, 1, 1
        ]
        
        
        
        
        // 加载顶点数据
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 3), vertices )
        glEnableVertexAttribArray(positionSlot)
        
        // 加载颜色数据
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, colors)
        // 启用顶点属性数据
        glEnableVertexAttribArray(colorSlot)
        
        // 绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        //  向openGLES 发起渲染命令请求
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        destoryRenderAndFrameBuffer()
        setupBuffer()
        setupProgram()
        
        render()
    }
    
}
