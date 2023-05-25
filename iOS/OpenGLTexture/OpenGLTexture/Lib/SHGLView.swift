//
//  SHGLView.swift
//  OpenGLESTriangle
//
//  Created by Mac on 2023/5/24.
//

import UIKit

class SHGLView: UIView {
    enum Style {
        /// 绘制三角形
        case triangle
        
        case texture
    }
    
    var style: Style = .texture
    
    
    
    /// 上下文 openGL 是状态机 apple 用 EAGLContext 管理状态机
    var myContext:EAGLContext?
    //   颜色顶点缓存的唯一id
    var myColorFrameBuffer:GLuint = 0
    /// 颜色缓存的唯一id
    var myColorRenderBuffer:GLuint = 0
    /// 程序的id
    var myProgram:GLuint?
    
    var positionSlot:GLuint = 0

    var colorSlot: GLuint = 0
    
    var textCoordSlot: GLuint = 0
//    纹理id
    var colorMap: GLuint = 0
    
    
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
    //    设置 缓存对象 (帧缓存 和 渲染缓存) FBO 帧缓存 ios 无法直接渲染 需要通过
    fileprivate func setupBuffer() {
        // 为渲染缓存对申请id
        var buffer:GLuint = 0
        glGenRenderbuffers(1, &buffer)
        //        保存到属性里面为了后面 释放所用
        myColorRenderBuffer = buffer
        //  设置为渲染缓存对类型GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        // 为 渲染缓存区 分配存储空间
        myContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer as? CAEAGLLayer)
        
        //        申请帧缓存对象id 唯一值
        glGenFramebuffers(1, &buffer)
        //        保存到属性里面为了后面 释放所用
        myColorFrameBuffer = buffer
        // 为告诉openGLES 我是GL_FRAMEBUFFER 类型 就是我是帧缓存类型
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }
    
    
    
    fileprivate func setupProgram() {
        
        myProgram = ShaderTool.loanProgram(verShaderFileName: "shaderTexturev.glsl", fragShaderFileName: "shaderTexturef.glsl")
        guard let myProgram = myProgram else {
            return
        }
        glUseProgram(myProgram)
        positionSlot = GLuint(glGetAttribLocation(myProgram, "vPosition"))
        textCoordSlot = GLuint(glGetAttribLocation(myProgram, "textCoordinate"))
        colorMap = GLuint(glGetUniformLocation(myProgram, "colorMap"))
//        glUniform1i(GLint(colorMap), 0)
        
    }
    fileprivate func destoryRenderAndFrameBuffer() {
        //        当 UIView 在进行布局变化之后，由于 layer 的宽高变化，导致原来创建的 renderbuffer不再相符，我们需要销毁既有 renderbuffer 和 framebuffer。下面，我们依然创建私有方法 destoryRenderAndFrameBuffer 来销毁生成的 buffer
        glDeleteFramebuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
        glDeleteRenderbuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        
        
    }
    fileprivate func render() {
        /// 清除
        glClearColor(0, 1.0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        do {

            // 注:纹理上下颠倒,这是因为OpenGL要求y轴0.0坐标是在图片的底部的，但是图片的y轴0.0坐标通常在顶部。
            // 解决1:glsl 里面 反转 y 轴(gl_Position = vec4(vPosition.x,-vPosition.y,vPosition.z,1.0))
            // 解决2:纹理坐标(s,t) -> (s,abs(t - 1))
            let vertices: [GLfloat] = [
                0.2, 0.2, -1,       1, 1,   // 右上               1, 0
                0.2, -0.2, -1,      1, 0,   // 右下               1, 1
                -0.2, -0.2, -1,     0, 0,   // 左下               0, 1
                -0.2, -0.2, -1,     0, 0,   // 左下               0, 1
                -0.2, 0.2, -1,      0, 1,   // 左上               0, 0
                0.2, 0.2, -1,       1, 1    // 右上               1, 0
            ]


            var VAO:GLuint = 0
            var VBO:GLuint = 0
            glGenVertexArrays(1, &VAO)
            glGenBuffers(GLsizei(1), &VBO)

            glBindVertexArray(VAO)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)
            let count = vertices.count
            let size =  MemoryLayout<GLfloat>.size
            glBufferData(GLenum(GL_ARRAY_BUFFER), count * size, vertices, GLenum(GL_STATIC_DRAW))

            ///
            glVertexAttribPointer(
                positionSlot,
                3,
                GLenum(GL_FLOAT),
                GLboolean(GL_FALSE),
                GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
            glEnableVertexAttribArray(positionSlot)

            glVertexAttribPointer(
                GLuint(textCoordSlot),
                2,
                GLenum(GL_FLOAT),
                GLboolean(GL_FALSE),
                GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
            glEnableVertexAttribArray(GLuint(textCoordSlot))


            setupTexture(fileName: "fffss.png")

            // 绘制
            glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)

            myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
            glDeleteVertexArrays(1, &VAO)
            glDeleteBuffers(1, &VBO)
            
            glBindTexture(GLenum(GL_TEXTURE_2D), 0)
            colorMap = 0

        }
        
        
        
        
    }
    
    func setupTexture(fileName:String) {
        // 获取图片的CGImageRef
        guard let spriteImage = UIImage(named: fileName)?.cgImage else {
            print("Failed to load image \(fileName)")
            return
        }
        
        //    https://learnopengl-cn.github.io/01%20Getting%20started/06%20Textures/
        //        GL_TEXTURE_MIN_FILTER 缩小的时候 线性过滤 GL_TEXTURE_MAG_FILTER 放大的时候
        // 为当前绑定的纹理对象设置环绕、过滤方式
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR );
        //    MARK: 纹理环绕方式
        /**
         MARK: 纹理环绕方式
         GL_REPEAT    对纹理的默认行为。重复纹理图像。
         GL_MIRRORED_REPEAT    和GL_REPEAT一样，但每次重复图片是镜像放置的。
         GL_CLAMP_TO_EDGE    纹理坐标会被约束在0到1之间，超出的部分会重复纹理坐标的边缘，产生一种边缘被拉伸的效果。
         GL_CLAMP_TO_BORDER    超出的坐标为用户指定的边缘颜色。
         */
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        
        
        // 读取图片大小
        let width = spriteImage.width
        let height = spriteImage.height
        // 为图片分配内存 rbga 每个像素点 4个字节 所以内存width * height * 4 个字节 一个字节 8bit
        
        
        let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        // 在CGContextRef上绘图
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), colorMap);
        
        
        // 加载并生成纹理
        let fw = width * 2
        let fh = height * 2
        /**
         第一个参数指定了纹理目标(Target)。设置为GL_TEXTURE_2D意味着会生成与当前绑定的纹理对象在同一个目标上的纹理（任何绑定到GL_TEXTURE_1D和GL_TEXTURE_3D的纹理不会受到影响）。
         第二个参数为纹理指定多级渐远纹理的级别，如果你希望单独手动设置每个多级渐远纹理的级别的话。这里我们填0，也就是基本级别。
         第三个参数告诉OpenGL我们希望把纹理储存为何种格式。我们的图像只有RGB值，因此我们也把纹理储存为RGB值。
         第四个和第五个参数设置最终的纹理的宽度和高度。我们之前加载图像的时候储存了它们，所以我们使用对应的变量。
         下个参数应该总是被设为0（历史遗留的问题）。
         第七第八个参数定义了源图的格式和数据类型。我们使用RGB值加载这个图像，并把它们储存为char(byte)数组，我们将会传入对应值。
         最后一个参数是真正的图像数据。
         */
//        这里生成的 宽高 可以生效 纹理环绕的枚举
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(fw), GLsizei(fh), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData);
        
        // 释放资源
        free(spriteData)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        destoryRenderAndFrameBuffer()
        setupBuffer()
        setupProgram()
        
        render()
    }
    
}
