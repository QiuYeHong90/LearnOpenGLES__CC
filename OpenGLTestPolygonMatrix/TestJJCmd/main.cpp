#include "GLShaderManager.h"

#include "GLTools.h"

#include <glut/glut.h>

GLBatch triangleBatch;

GLShaderManager shaderManager;

//窗口大小改变时接受新的宽度和高度，其中0,0代表窗口中视口的左下角坐标，w，h代表像素

GLfloat itemW = 0.1f;
GLfloat centerX = 0.0f;
GLfloat centerY = 0.0f;
GLfloat stepSpace = 0.025;
GLfloat vVerts[] = {
    -itemW/2 + centerX,-itemW/2  + centerY,0.0f,
    -itemW/2+ centerX,itemW/2 + centerY,0.0f,
    itemW/2 + centerX,itemW/2 + centerY,0.0f,
    itemW/2 + centerX,-itemW/2 + centerY,0.0f,
    
};

int isFlag = -1;

void ChangeSize(int w,int h)

{
    
    glViewport(0,0, w, h);
    
}

//为程序作一次性的设置

void SetupRC()

{
    
    //设置背影颜色
    
    glClearColor(0.0f,0.0f,1.0f,1.0f);
    
    //初始化着色管理器
    
    shaderManager.InitializeStockShaders();
    
    //设置三角形，其中数组vVert包含所有3个顶点的x,y,笛卡尔坐标对。
    
    
    
    //批次处理
    
    triangleBatch.Begin(GL_TRIANGLE_FAN,4);
    
    triangleBatch.CopyVertexData3f(vVerts);
    
    triangleBatch.End();
    
}

//开始渲染

void RenderScene(void)

{
    
    //清除一个或一组特定的缓冲区
    
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
    
    //设置一组浮点数来表示红色
    
    GLfloat vRed[] = {1.0f,0.0f,0.0f,1.0f};
    
   
//    添加矩阵
    
    M3DMatrix44f  first, rotation, finalMatri;
    
//    获取平移矩阵
    m3dTranslationMatrix44(first, centerX, centerY, 0);
//    获取旋转矩阵
    static float angle = 0;
    float angleStep = 3.14 * 2 * 10 / 360;
    if (isFlag == 0) {
        angle -= angleStep;
    } else if (isFlag == 1) {
        angle += angleStep;
    }
    isFlag = -1;
    m3dRotationMatrix44(rotation, angle, 0, 0, 1);
    
    // 矩阵相乘 获取最终的 矩阵
    m3dMatrixMultiply44(finalMatri, first, rotation);
//
    //传递到存储着色器，即GLT_SHADER_IDENTITY着色器，这个着色器只是使用指定颜色以默认笛卡尔坐标第在屏幕上渲染几何图形
    // GLT_SHADER_FLAT  代表平面
    shaderManager.UseStockShader(GLT_SHADER_FLAT,finalMatri,vRed);
    
    
    //提交着色器
    
    triangleBatch.Draw();
    
    //将在后台缓冲区进行渲染，然后在结束时交换到前台
    
    glutSwapBuffers();
    
}

void reloadCenter() {
    
    if (centerX < -1 + itemW/2.0) {
        centerX = -1 + itemW/2.0;
    }
    if (centerX > 1 - itemW/2.0) {
        centerX = 1 - itemW/2.0;
    }
    
    if (centerY < -1 + itemW/2.0) {
        centerY = -1 + itemW/2.0;
    }
    if (centerY > 1 - itemW/2.0) {
        centerY = 1 - itemW/2.0;
    }
}

void specialM(int key, int x, int y) {
    printf("key == %d",key);
    if (key == GLUT_KEY_RIGHT) {
        centerX += stepSpace;
        isFlag = 1;
    }
    if (key == GLUT_KEY_LEFT) {
        centerX -= stepSpace;
        isFlag = 0;
    }
    if (key == GLUT_KEY_UP) {
        centerY += stepSpace;
        isFlag = 1;
    }
    if (key == GLUT_KEY_DOWN) {
        centerY -= stepSpace;
        isFlag = 0;
    }
    
    reloadCenter();
    
//    GLfloat vVertsNew[] = {
//        -itemW/2 + centerX,-itemW/2  + centerY,0.0f,
//        -itemW/2+ centerX,itemW/2 + centerY,0.0f,
//        itemW/2 + centerX,itemW/2 + centerY,0.0f,
//        itemW/2 + centerX,-itemW/2 + centerY,0.0f,
//
//    };
//    triangleBatch.CopyVertexData3f(vVertsNew);
    
    glutPostRedisplay();
    
}

int main(int argc,char* argv[])

{
    
    //设置当前工作目录，针对MAC OS X
    
    gltSetWorkingDirectory(argv[0]);
    
    //初始化GLUT库
    
    glutInit(&argc, argv);
    
    /*初始化双缓冲窗口，其中标志GLUT_DOUBLE、GLUT_RGBA、GLUT_DEPTH、GLUT_STENCIL分别指
     
     双缓冲窗口、RGBA颜色模式、深度测试、模板缓冲区*/
    
    glutInitDisplayMode(GLUT_DOUBLE|GLUT_RGBA|GLUT_DEPTH|GLUT_STENCIL);
    
    //GLUT窗口大小，标题窗口
    
    glutInitWindowSize(800,800);
    
    glutCreateWindow("Triangle");
    
    //注册回调函数
    
    glutReshapeFunc(ChangeSize);
    
    glutDisplayFunc(RenderScene);
    
    glutSpecialFunc(specialM);
    //驱动程序的初始化中没有出现任何问题。
    
    GLenum err = glewInit();
    
    if(GLEW_OK != err) {
        
        fprintf(stderr,"glew error:%s\n",glewGetErrorString(err));
        
        return 1;
        
    }
    
    //调用SetupRC
    
    SetupRC();
    
    glutMainLoop();
    
    return 0;
    
}
