//
//  SHView.m
//  OpenGLTriangle
//
//  Created by Mac on 2023/5/24.
//

#import "SHView.h"


@interface SHView ()
@property (nonatomic, assign) CAEAGLLayer * eaLayer;
@property (nonatomic, strong) EAGLContext * context;
@end

@implementation SHView

- (CAEAGLLayer *)eaLayer {
    return  (CAEAGLLayer *)self.layer;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initCommon];
    }
    return self;
}

-(void)initCommon {
    [self.eaLayer setDrawableProperties:@{
        kEAGLDrawablePropertyRetainedBacking: @(NO),
        kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8,
    }];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    [EAGLContext setCurrentContext:self.context];
}





- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
}

@end
