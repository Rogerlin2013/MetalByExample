//
//  MetalView.m
//  MetalByExample
//
//  Created by linyongzhi on 2019/2/19.
//  Copyright © 2019 BabyTiger. All rights reserved.
//

#import "MetalView.h"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface MetalView ()

@property (nonatomic, strong) id <MTLDevice> device;

@property (nonatomic, strong) id <MTLBuffer> colorBuffer;
@property (nonatomic, strong) id <MTLBuffer> positionBuffer;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipeline;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation MetalView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (id)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildDevice];
        [self buildVertexBuffers];
        [self buildPipeline];
    }
    return self;
}

- (void)buildDevice {
    _device = MTLCreateSystemDefaultDevice();
    _metalLayer = (CAMetalLayer *)[self layer];
    _metalLayer.device = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)buildVertexBuffers {
    static const float positions[] = {
         0.0,  0.0, 0, 1,
        -0.5, -0.5, 0, 1,
         0.5, -0.5, 0, 1,
    };
    
    static const float colors[] = {
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
    };
    
    self.positionBuffer = [self.device newBufferWithBytes:positions length:sizeof(positions) options:MTLResourceOptionCPUCacheModeDefault];
    self.colorBuffer = [self.device newBufferWithBytes:colors length:sizeof(colors) options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)buildPipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat;
    
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    if (self.superview) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)displayLinkDidFire:(CADisplayLink *)displayLink {
    [self redraw];
}

- (void)redraw {
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> texture = drawable.texture;
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = texture;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    
    id<MTLCommandQueue> commandQueue = [self.device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    
    [commandEncoder setRenderPipelineState:self.pipeline];
    [commandEncoder setVertexBuffer:self.positionBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:self.colorBuffer offset:0 atIndex:1];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3 instanceCount:1];
    
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
