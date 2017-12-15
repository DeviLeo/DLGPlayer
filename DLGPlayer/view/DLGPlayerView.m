//
//  DLGPlayerView.m
//  DLGPlayer
//
//  Created by Liu Junqi on 05/12/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGPlayerView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "DLGPlayerVideoFrame.h"

#define VERTEX_ATTRIBUTE_POSITION   0
#define VERTEX_ATTRIBUTE_TEXCOORD   1

@interface DLGPlayerView () {
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _programHandle;
    GLuint _positionSlot;
    GLuint _projection;
    GLint _backingWidth;
    GLint _backingHeight;
    GLfloat _position[8];
    GLfloat _texcoord[8];
}

@property (nonatomic, strong) DLGPlayerVideoFrame *lastFrame;

@end

@implementation DLGPlayerView

- (id)init {
    self = [super init];
    if (self) {
        if (![self initVars]) {
            self = nil;
            return nil;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (![self initVars]) {
            self = nil;
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    NSLog(@"DLGPlayerView dealloc");
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self reload];
}

- (void)reload {
    [self deleteGLBuffer];
    [self deleteGLProgram];
    [self createGLBuffer];
    [self createGLProgram];
    [self updatePosition];
    [self render:self.lastFrame];
}

- (void)clear {
    self.keepLastFrame = NO;
    self.lastFrame = nil;
    [self render:nil];
}

- (BOOL)initVars {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking : @(NO),
                                       kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                       };
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (_context == nil) return NO;
    if (![EAGLContext setCurrentContext:_context]) return NO;
    
    [self initVertex];
    [self initTexCord];
    
    self.keepLastFrame = NO;
    
    return YES;
}

- (void)initVertex {
    _position[0] = -1; _position[1] = -1;
    _position[2] =  1; _position[3] = -1;
    _position[4] = -1; _position[5] =  1;
    _position[6] =  1; _position[7] =  1;
}

- (void)initTexCord {
    _texcoord[0] = 0; _texcoord[1] = 1;
    _texcoord[2] = 1; _texcoord[3] = 1;
    _texcoord[4] = 0; _texcoord[5] = 0;
    _texcoord[6] = 1; _texcoord[7] = 0;
}

- (void)createGLBuffer {
    // render buffer
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    // frame buffer
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (void)deleteGLBuffer {
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    
    glDeleteRenderbuffers(1, &_renderBuffer);
    _renderBuffer = 0;
}

- (void)createGLProgram {
    // Create program
    GLuint program = glCreateProgram();
    if (program == 0) {
        NSLog(@"FAILED to create program.");
        return;
    }
    
    // Load shaders
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *vertexShaderFile = [bundle pathForResource:@"DLGPlayerVertexShader" ofType:@"glsl"];
    GLuint vertexShader = [DLGPlayerView loadShader:GL_VERTEX_SHADER withFile:vertexShaderFile];
    NSString *fragmentShaderResource = _isYUV ? @"DLGPlayerYUVFragmentShader" : @"DLGPlayerRGBFragmentShader";
    NSString *fragmentShaderFile = [bundle pathForResource:fragmentShaderResource ofType:@"glsl"];
    GLuint fragmentShader = [DLGPlayerView loadShader:GL_FRAGMENT_SHADER withFile:fragmentShaderFile];
    
    // Attach shaders
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    // Bind
    glBindAttribLocation(program, VERTEX_ATTRIBUTE_POSITION, "position");
    glBindAttribLocation(program, VERTEX_ATTRIBUTE_TEXCOORD, "texcoord");
    
    // Link program
    glLinkProgram(program);
    
    // Check status
    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked == 0) {
        GLint length = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &length);
        if (length > 1) {
            char *log = malloc(sizeof(char) * length);
            glGetProgramInfoLog(program, length, NULL, log);
            NSLog(@"FAILED to link program, error: %s", log);
            free(log);
        }
        
        glDeleteProgram(program);
        return;
    }
    
    glUseProgram(program);
    
    _positionSlot = glGetAttribLocation(program, "position");
    _projection = glGetUniformLocation(program, "projection");
    _programHandle = program;
}

- (void)deleteGLProgram {
    glDeleteProgram(_programHandle);
    _programHandle = 0;
}

- (void)updatePosition {
    const float cw = _contentSize.width;
    const float ch = _contentSize.height;
    if (self.contentMode == UIViewContentModeScaleToFill ||
        cw == 0 || ch == 0) {
        _position[0] = -1; _position[1] = -1;
        _position[2] =  1; _position[3] = -1;
        _position[4] = -1; _position[5] =  1;
        _position[6] =  1; _position[7] =  1;
        return;
    }
    
    const float bw = _backingWidth;
    const float bh = _backingHeight;
    const float rw = bw / cw; // ratio of width
    const float rh = bh / ch; // ratio of height
    float ratio = 1;
    if (self.contentMode == UIViewContentModeScaleAspectFit) {
        ratio = MIN(rw, rh);
    } else if (self.contentMode == UIViewContentModeScaleAspectFill) {
        ratio = MAX(rw, rh);
    }
    const float w = (cw * ratio) / bw;
    const float h = (ch * ratio) / bh;
    
    _position[0] = -w; _position[1] = -h;
    _position[2] =  w; _position[3] = -h;
    _position[4] = -w; _position[5] =  h;
    _position[6] =  w; _position[7] =  h;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    [self updatePosition];
}

- (void)setContentSize:(CGSize)contentSize {
    _contentSize = contentSize;
    [self updatePosition];
}

- (void)setIsYUV:(BOOL)isYUV {
    _isYUV = isYUV;
    [self reload];
}

- (void)render:(DLGPlayerVideoFrame *)frame {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Setup viewport
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    // Set frame
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if ([frame prepareRender:_programHandle]) {
        GLfloat proj[16];
        [DLGPlayerView ortho:proj];
        glUniformMatrix4fv(_projection, 1, GL_FALSE, proj);
        glVertexAttribPointer(VERTEX_ATTRIBUTE_POSITION, 2, GL_FLOAT, GL_FALSE, 0, _position);
        glEnableVertexAttribArray(VERTEX_ATTRIBUTE_POSITION);
        glVertexAttribPointer(VERTEX_ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 0, _texcoord);
        glEnableVertexAttribArray(VERTEX_ATTRIBUTE_TEXCOORD);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }

    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    if (_keepLastFrame) self.lastFrame = frame;
}

#pragma mark - Utils
+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString {
    // 1. Create shader
    GLuint shader = glCreateShader(type);
    if (shader == 0) {
        NSLog(@"FAILED to create shader.");
        return 0;
    }
    
    // 2. Load shader source
    const char *shaderUTF8String = [shaderString UTF8String];
    glShaderSource(shader, 1, &shaderUTF8String, NULL);
    
    // 3. Compile shader
    glCompileShader(shader);
    
    // 4. Check status
    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (compiled == 0) {
        GLint length = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        if (length > 1) {
            char *log = malloc(sizeof(char) * length);
            glGetShaderInfoLog(shader, length, NULL, log);
            NSLog(@"FAILED to compile shader, error: %s", log);
            free(log);
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

+ (GLuint)loadShader:(GLenum)type withFile:(NSString *)shaderFile {
    NSError *error = nil;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderFile encoding:NSUTF8StringEncoding error:&error];
    if (shaderString == nil) {
        NSLog(@"FAILED to load shader file: %@, Error: %@", shaderFile, error);
        return 0;
    }
    
    return [self loadShader:type withString:shaderString];
}

/*
 * https://www.opengl.org/sdk/docs/man2/xhtml/glOrtho.xml
 */
+ (void)ortho:(float *)mat4f {
    float left = -1, right = 1;
    float bottom = -1, top = 1;
    float near = -1, far = 1;
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / r_l;
    float ty = - (top + bottom) / t_b;
    float tz = - (far + near) / f_n;
    
    mat4f[0] = 2 / r_l;
    mat4f[1] = 0;
    mat4f[2] = 0;
    mat4f[3] = 0;
    
    mat4f[4] = 0;
    mat4f[5] = 2 / t_b;
    mat4f[6] = 0;
    mat4f[7] = 0;
    
    mat4f[8] = 0;
    mat4f[9] = 0;
    mat4f[10] = -2 / f_n;
    mat4f[11] = 0;
    
    mat4f[12] = tx;
    mat4f[13] = ty;
    mat4f[14] = tz;
    mat4f[15] = 1;
}

@end
