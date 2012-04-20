#import "BlobLight.h"
#import <ofxCocoaPlugins/Tracker.h>
#import <ofxCocoaPlugins/Keystoner.h>

@implementation BlobLight

-(void)initPlugin{

    [self addPropF:@"trackingAdd"];
    [self addPropF:@"trackingBlur"];
    [self addPropF:@"trackingDilate"];
    
    [self addPropF:@"postBlur"];
    [self addPropF:@"postFade"];
    
    [self addPropF:@"colorR"];
    [self addPropF:@"colorG"];
    [self addPropF:@"colorB"];
    
    [self addPropF:@"alphaFront"];
    [self addPropF:@"alphaBack"];
    
    [self addPropB:@"clear"];

}

//
//----------------
//


-(void)setup{
    image = new ofxCvFloatImage();
    image->allocate(BLOBLIGHT_RESOLUTION_W, BLOBLIGHT_RESOLUTION_H);
    
    trackerFloatImage = new ofxCvFloatImage();
    trackerFloatImage->allocate(BLOBLIGHT_RESOLUTION_W, BLOBLIGHT_RESOLUTION_H);
    
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    
    if(PropB(@"clear")){
        SetPropB(@"clear",0);
        image->set(0);
    }
    
    
    //--- Tracking ------
    CachePropF(trackingAdd);
    if(trackingAdd){
        Tracker * tracker = GetPlugin(Tracker);
        ofxCvGrayscaleImage trackerGrayscaleImage = [tracker trackerImageWithSize:CGSizeMake(BLOBLIGHT_RESOLUTION_W, BLOBLIGHT_RESOLUTION_H)];

        if(PropF(@"trackingDilate")){
            int dilate = PropF(@"trackingDilate")*5;
            for(int i=0;i<dilate;i++){
                trackerGrayscaleImage.dilate_3x3();
            }
        }
        
        if(PropF(@"trackingBlur")){
            int blur = PropF(@"trackingBlur")*25;
            trackerGrayscaleImage.blurGaussian(blur);
        }
        
        
        trackerGrayscaleImage.convertToRange(0, trackingAdd*255);
        *trackerFloatImage = trackerGrayscaleImage;
        
        *image += *trackerFloatImage;
    }
    
    
    // ------ POST ----------
    CachePropF(postBlur);
    if(postBlur){
        image->blurGaussian(postBlur*15);
    }
    
    CachePropF(postFade);
    if(postFade){
        *image -= postFade*0.2;
    }    
    
    cvThreshold(image->getCvImage(), image->getCvImage(), 1.0, 1.0, CV_THRESH_TRUNC);
    cvThreshold(image->getCvImage(), image->getCvImage(), 0, 1.0, CV_THRESH_TOZERO);
    image->flagImageChanged();
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Floor"){
        ofEnableAlphaBlending();
        glBlendFunc(GL_ONE, GL_ONE);
        if(ViewNumber == 0){
            CachePropF(alphaBack);
            glColor3f(PropF(@"colorR")*alphaBack, PropF(@"colorG")*alphaBack, PropF(@"colorB")*alphaBack);
        }
        if(ViewNumber == 1){
            CachePropF(alphaFront);
            glColor3f(PropF(@"colorR")*alphaFront, PropF(@"colorG")*alphaFront, PropF(@"colorB")*alphaFront);
        }
        image->draw(0,0,aspect,1);
    } PopSurface();
    
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
    image->draw(0,0,[self.controlGlView frame].size.width, [self.controlGlView frame].size.height);
}

@end
