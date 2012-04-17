#pragma once
#import <ofxCocoaPlugins/Plugin.h>
#import <ofxCocoaPlugins/BlobTracker2d.h>

#define BLOBLIGHT_RESOLUTION_W 800
#define BLOBLIGHT_RESOLUTION_H 400

@interface BlobLight : ofPlugin {
    ofxCvFloatImage * image;
    ofxCvFloatImage * trackerFloatImage;

}

@end
