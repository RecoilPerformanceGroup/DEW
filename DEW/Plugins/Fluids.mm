#import "Fluids.h"
#import <ofxCocoaPlugins/CustomGraphics.h>
#import <ofxCocoaPlugins/Keystoner.h>
#import <ofxCocoaPlugins/Tracker.h>

@implementation Fluids
@synthesize controlMouseColor;
@synthesize controlMouseColorEnabled;
@synthesize controlMouseForceEnabled;
@synthesize controlMouseForce;

-(void)initPlugin{
    [[self addPropF:@"controlDrawMode"] setMinValue:0 maxValue:3];
    
    [[self addPropF:@"fluidsDeltaT"] setMinValue:0 maxValue:0.1];
    [[self addPropF:@"fluidsFadeSpeed"] setMinValue:0 maxValue:0.1];
    [[self addPropF:@"fluidsSolverIterations"] setMinValue:1 maxValue:50];
    [[self addPropF:@"fluidsVisc"] setMaxValue:0.0002f];
    [self addPropB:@"fluidsReset"];
    
    [self addPropF:@"opticalFlowForce"];
    
    [self addPropF:@"fluidWeight"];
    
    [self addPropF:@"trackerForceBlock"];
    [self addPropF:@"trackerColorAdd"];    
    
    [self addPropF:@"globalForce"];
    [self addPropF:@"globalTwirl"];
    [[self addPropF:@"globalForceRotation"] setMaxValue:360];
    
}

//
//----------------
//


-(void)setup{
    fluids = new FluidSolver();
    fluids->setup(200,100);
    fluids->enableRGB(YES);
    
    fluidsDrawer = new FluidDrawerGl();
    fluidsDrawer->setup(fluids);
    fluidsDrawer->vectorSkipCount = 4; //Vector mode

    lastControlMouse.x = -1;

    fluidImage.allocate(200,100);
}

-(void)awakeFromNib{
}

//
//----------------
//

-(void) addImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color{
    Vec3f * fluidColor = fluids->color;
    unsigned char * pixel = inputImage->getPixels();
    for(int i=0 ; i<fluids->getNumCells() ; i++,fluidColor++, pixel++){
        float pixelValue = factor * (*pixel);
        *fluidColor += Vec3f(pixelValue*color.r, pixelValue*color.g , pixelValue * color.b);
    }
}

-(void) multInverseImageWithFluidsForces:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor {
    Vec2f * fluidUv = fluids->uv;
    unsigned char * pixel = inputImage->getPixels();
    for(int i=0 ; i<fluids->getNumCells() ; i++,fluidUv++, pixel++){
        float pixelValue = factor * (*pixel);
        *fluidUv *= (1-pixelValue);
    }

}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    Tracker * tracker = GetPlugin(Tracker);
    
    surfaceAspect = Aspect(@"Floor",0);
    if(PropB(@"fluidsReset")){
        SetPropB(@"fluidsReset", 0);
        fluids->reset(); 
    }
    
    //------ Tracker Color ----------
    ofxCvGrayscaleImage trackerImage = [tracker trackerImageWithSize:CGSizeMake(fluids->getWidth(), fluids->getHeight())];
    CachePropF(trackerColorAdd);
    if(trackerColorAdd){
        [self addImageToFluids:&trackerImage withFactor:trackerColorAdd color:Color(1.0,0.0,0.0)];
    }
    
    //------ Tracker Block Force ----------    
    CachePropF(trackerForceBlock);
    if(trackerForceBlock){
        [self multInverseImageWithFluidsForces:&trackerImage withFactor:trackerForceBlock];
    }
    
    //-------- globalForce --------
    
    CachePropF(globalForce);
    if(globalForce){
//        NSLog(@"%f %f",fluids->uv[10].x, fluids->uv[10].y);
        CachePropF(globalForceRotation);
        Vec2f f = Vec2f(0,globalForce*0.001);
        f.rotate(globalForceRotation*DEG_TO_RAD);
        for(int i=0;i<fluids->getNumCells();i++){
            fluids->uv[i] += f;
        }
    }
    
    //---------- fluidWeight --------
    CachePropF(fluidWeight);
    if(fluidWeight){
        for(int i=0;i<fluids->getNumCells();i++){
            Color c = fluids->getColorAtIndex(i);
            fluids->addForceAtIndex(i, Vec2f(0,c.length()*fluidWeight));
        }
    }
    
    //---------- Twirl -------------
    CachePropF(globalTwirl);
    if(globalTwirl){
        int i=0;
        for(int y=0;y<fluids->getSize().y;y++){            
            for(int x=0;x<fluids->getSize().x;x++){
                ofVec2f p = ofVec2f(x/fluids->getSize().x-surfaceAspect*0.25,y/fluids->getSize().y-0.5);
                float l = p.length();
                ofVec2f hat = ofVec2f(-p.y,p.x);
                //hat.normalize();
                
                fluids->uv[i] += ( Vec2f(hat.x,hat.y) * globalTwirl - fluids->uv[i])*0.2;
                i++;
//                fluids->addForceAtPos(Vec2f(x/fluids->getSize().x, y/fluids->getSize().y), Vec2f(hat.x,hat.y)*globalTwirl);
            }
        }
    }
    
    //--------- OpticalFlow --------
    
    
    CachePropF(opticalFlowForce);
    if(opticalFlowForce){
        opticalFlowField = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowFieldCalibrated];
        if(opticalFlowField != nil){
            opticalW = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowW];
            opticalH = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowH];
            
            ofVec2f * field = opticalFlowField;
            for(int y=0;y<opticalH;y++){
                for(int x=0;x<opticalW;x++){
                    ofVec2f f = *field++;
                    float l = f.length();
                    if(l > 0){                    
                        fluids->addForceAtPos(Vec2f((float)x/opticalW, (float)y/opticalH), Vec2f(f.x,f.y)*opticalFlowForce);
                    }
                }
            }
            
        }
    }
    
    
    //---------------------------
    
    
    if([[self controlMouseColorEnabled] state] && lastControlMouse.x != -1){
        NSColor * color = [[self controlMouseColor] color];
        Color c(MSA::CM_RGB,  [color redComponent], [color greenComponent], [color blueComponent] );
//        fluids->addColorAtPos(Vec2f([self controlMouseX]/[[self controlGlView] frame].size.width, [self controlMouseY]/[[self controlGlView] frame].size.height), c*[color alphaComponent]*100.0);
        int i=0;
        ofVec2f mouse = ofVec2f([self controlMouseX]/[[self controlGlView] frame].size.width, [self controlMouseY]/[[self controlGlView] frame].size.height);
        float radius = 0.02;
        
        for(int y=0;y<fluids->getSize().y;y++){            
            for(int x=0;x<fluids->getSize().x;x++){
                ofVec2f p = ofVec2f(x/fluids->getSize().x, y/fluids->getSize().y);
                if (p.distance(mouse) < radius) {
                    fluids->addColorAtIndex(i, c*[color alphaComponent]*10.0);           
                }
                i++;
                //                fluids->addForceAtPos(Vec2f(x/fluids->getSize().x, y/fluids->getSize().y), Vec2f(hat.x,hat.y)*globalTwirl);
            }
        }

    }
    
    
    //---------------------------
    
    fluids->setDeltaT(PropF(@"fluidsDeltaT"));
    fluids->setFadeSpeed(PropF(@"fluidsFadeSpeed"));
    fluids->setSolverIterations(PropI(@"fluidsSolverIterations"));
    fluids->setVisc(PropF(@"fluidsVisc"));
    fluids->update();
    
    unsigned char * pixel = (unsigned char*) fluidImage.getCvImage()->imageData;
    Vec3f * fluidPixel = fluids->color; 
    for(int i=0;i<fluidImage.width*fluidImage.height*3; i++,pixel++){
        if(i%3 == 0){
            fluidPixel++;
        }
        if(i% fluids->getWidth() == 0){
            fluidPixel++;
        }

        *pixel  = (*fluidPixel)[i%3]*255;
    }
    fluidImage.flagImageChanged();
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
//    fluidsDrawer->setDrawMode(kFluidDrawColor);
//    fluidsDrawer->draw(0,0,1,1);
/*    ApplySurface(@"Floor"){
    //    fluidsDrawer->getTextureReference().draw(0, 0, surfaceAspect, 1);
    } PopSurface();*/
    
    fluidImage.draw(0, 0,1,1);
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
    ofSetColor(0,0,0,255);
    ofRect(0,0,ofGetWidth(), ofGetWidth());

    ofSetColor(255,255,255,255);
    fluidsDrawer->setDrawMode((FluidDrawMode)PropI(@"controlDrawMode"));
    fluidsDrawer->draw(0,0,ofGetWidth(),ofGetHeight());
    
    ofEnableAlphaBlending();
    if(opticalFlowField){
        ofVec2f * field = opticalFlowField;
        for(int y=0;y<opticalH;y++){
            for(int x=0;x<opticalW;x++){
                ofVec2f f = *field++;
                float l = f.length();
                if(l > 0){                    
                    float a = l / 50.0;
                    glColor4f(1.0, 1.0, 1.0, a);
                    ofVec2f p = ofVec2f(ofGetWidth()*x/opticalW , ofGetHeight()*y/opticalH);
                    of2DArrow(p, p+f, 4);
                }
            }
        }
    }
}

-(void)controlMouseDragged:(float)x y:(float)y button:(int)button{
    Vec2f pos = Vec2f((float)x/[[self controlGlView] frame].size.width, (float)y/[[self controlGlView] frame].size.height);
    if(lastControlMouse.x == -1){
        lastControlMouse = pos;
    } else {
        Vec2f _d = pos - lastControlMouse;
        
        if([[self controlMouseForceEnabled] state]){
            fluids->addForceAtPos(pos, _d * [[self controlMouseForce] floatValue]);
        }
        
        lastControlMouse = pos;
    }
}

-(void)controlMouseReleased:(float)x y:(float)y{
    lastControlMouse.x = -1;
}

@end
