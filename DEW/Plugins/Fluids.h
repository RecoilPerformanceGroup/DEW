#pragma once

#import <ofxCocoaPlugins/Plugin.h>
#import "MSAFluid.h"
#import <ofxCocoaPlugins/BlobTracker2d.h>

#define BUFFER_SIZE 500
#define BUFFER_PLAYBACK_COUNT 10
typedef struct {
    int countdown;
    float pos;
}    FluidLine;

typedef struct {
    float pos;
}    TurnerPoint;

using namespace MSA;

@interface Fluids : ofPlugin {
    ofImage * img;
    
    FluidSolver * fluids;
    FluidDrawerGl * fluidsDrawer;
    
    Vec2f lastControlMouse;
    NSColorWell *controlMouseColor;
    NSButton *controlMouseColorEnabled;
    NSButton *controlMouseForceEnabled;
    NSSlider *controlMouseForce;
    
    ofVec2f * opticalFlowField;
    
    int opticalW;
    int opticalH;
    
    float surfaceAspect;
    
    ofxCvColorImage fluidImage;
    
    FluidLine fluidLines[30];
    TurnerPoint turnerPoints[30];
    ofVec2f dropsPos;
    
    ofImage * verticalMask;
    ofImage * verticalMaskWhite;
    ofImage * verticalMaskBlack;
    ofxCvGrayscaleImage trackerImage;
    
    ofxCvGrayscaleImage buffer[BUFFER_SIZE];    
    BOOL alreadyRecording;
    int bufferRecordIndex;
    float bufferPlaybackIndexes[BUFFER_PLAYBACK_COUNT];
    int bufferPlaybackCount;
    int bufferPlaybackOffset[BUFFER_PLAYBACK_COUNT];
    
}
@property (assign) IBOutlet NSButton *controlMouseColorEnabled;
@property (assign) IBOutlet NSColorWell *controlMouseColor;
@property (assign) IBOutlet NSButton *controlMouseForceEnabled;
@property (assign) IBOutlet NSSlider *controlMouseForce;

@end


