#import "Fluids.h"
#import <ofxCocoaPlugins/CustomGraphics.h>
#import <ofxCocoaPlugins/Keystoner.h>
#import <ofxCocoaPlugins/Tracker.h>
#import <ofxCocoaPlugins/BlobTracker2d.h>

@implementation Fluids
@synthesize controlMouseColor;
@synthesize controlMouseColorEnabled;
@synthesize controlMouseForceEnabled;
@synthesize controlMouseForce;

-(void)initPlugin{
    [[self addPropF:@"controlDrawMode"] setMinValue:0 maxValue:3];
    
    [[self addPropF:@"fluidsDeltaT"] setMinValue:0 maxValue:0.1];
    [[self addPropF:@"fluidsFadeSpeed"] setMinValue:0 maxValue:1];
    [[self addPropF:@"fluidsSolverIterations"] setMinValue:0 maxValue:50];
    [[self addPropF:@"fluidsVisc"] setMaxValue:1];
    [self addPropB:@"fluidsReset"];
    
    [self addPropF:@"opticalFlowForce"];
    [[self addPropF:@"opticalFlowForceMin"] setMaxValue:10];
    
    [[self addPropF:@"mFluidWeight"] setMaxValue:1.0];
    [[self addPropF:@"mFluidWeightDir"] setMaxValue:360];
    [self addPropF:@"mSuckTracking"]; 
    [self addPropF:@"mSuckCenter"]; 
    [self addPropF:@"mSuckCenterYAxis"]; 
    
    [self addPropF:@"mTurnSpeed"]; 
    [self addPropF:@"mTurnForce"]; 
    [[self addPropF:@"mTurnCount"] setMaxValue:10];
    
    [self addPropF:@"trackerForceBlock"];
    [self addPropF:@"trackerColorAdd"]; 
    [[self addPropF:@"trackerColorAddJump"] setMaxValue:100]; 
    [self addPropF:@"trackerBlack"];    
    
    [self addPropF:@"globalForce"];
    [[self addPropF:@"globalForceRotation"] setMaxValue:360];
    [self addPropF:@"globalTwirl"];
    
    [self addPropF:@"projectorFront"];
    [self addPropF:@"projectorBack"];
    
    [self addPropF:@"generateLinesSideDuration"];
    [[self addPropF:@"generateLinesSideNum"] setMaxValue:30];
    [self addPropF:@"generateDrops"];
    [[self addPropF:@"generateFallingFluids"] setMaxValue:2];
    [self addPropF:@"generateStartLight"];
    
    [[self addPropF:@"postGain"] setMinValue:-1 maxValue:10.0]; 
    
    [self addPropB:@"bufferRecord"]; 
    [self addPropB:@"bufferPlaybackReset"]; 
    [self addPropF:@"bufferAlpha"]; 
    [self addPropB:@"bufferTriggerStart"]; 
    [[self addPropF:@"bufferOffset"] setMinValue:-1 maxValue:1]; 
    [[self addPropF:@"bufferPlaybackRate"] setMinValue:0 maxValue:2];   
    [self addPropF:@"bufferClipLeft"]; 
    
    [self addPropF:@"colorR"];
    [self addPropF:@"colorG"];
    [self addPropF:@"colorB"];
    
    [self addPropF:@"maskVerticalBack"];
    [self addPropF:@"maskVerticalFront"];
    
    [self addPropF:@"maskTrackingBack"];
    [self addPropF:@"maskTrackingFront"];
    
}

//
//----------------
//


-(void)setup{
    fluids = new FluidSolver();
    fluids->setup(FLUIDS_WIDTH , FLUIDS_HEIGHT + OVERFLOW_TOTAL);
    fluids->enableRGB(YES);
    
    fluidsDrawer = new FluidDrawerGl();
    fluidsDrawer->setup(fluids);
    fluidsDrawer->vectorSkipCount = 4; //Vector mode
    
    lastControlMouse.x = -1;
    
    fluidImage.allocate(FLUIDS_WIDTH,FLUIDS_HEIGHT);
    
    for(int i=0;i<30;i++){
        turnerPoints[i].pos = ofRandom(0,1);
    }
    
    //[[GetPlugin(BlobTracker2d) getInstance:0] enableBufferWithSize:300];
    //[[GetPlugin(BlobTracker2d) getInstance:0] setBufferRecording:YES];
    
    verticalMask = new ofImage();    
    verticalMask->loadImage([[[NSBundle mainBundle] pathForResource:@"VerticalMask" ofType:@"png"] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    verticalMaskWhite = new ofImage();    
    verticalMaskWhite->loadImage([[[NSBundle mainBundle] pathForResource:@"VerticalMaskWhite" ofType:@"png"] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    verticalMaskBlack = new ofImage();    
    verticalMaskBlack->loadImage([[[NSBundle mainBundle] pathForResource:@"VerticalMaskBlack" ofType:@"png"] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    trackerImage.allocate(fluids->getWidth(), fluids->getHeight()-OVERFLOW_TOTAL);
    
    for(int i=0;i<BUFFER_SIZE;i++){
        buffer[i].allocate(fluids->getWidth(), fluids->getHeight()-OVERFLOW_TOTAL);
    }
    bufferTmp.allocate(fluids->getWidth(), fluids->getHeight()-OVERFLOW_TOTAL);
    
}

-(void)awakeFromNib{
}

//
//----------------
//

-(void) addImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color transform:(CGRect)transform{
    
    if(transform.size.width == 1 && transform.size.height == 1){
        Vec3f * fluidColor = fluids->color;
        unsigned char * pixel = inputImage->getPixels();
        
        //  int numCellsToUpdate = fluids->getNumCells() - fluids->getWidth()*(fluids->getHeight() - inputImage->getHeight())*0.5;
        int numCellsToUpdate = inputImage->getWidth() * inputImage->getHeight();
        int maxCellsToUpdate = fluids->getNumCells();
        
        if(transform.origin.y < 0){
            pixel += int(-inputImage->getWidth()*transform.origin.y);
            // numCellsToUpdate -= int(-inputImage->getWidth()*transform.origin.y);
        } else if(transform.origin.y > 0){
            fluidColor += int(inputImage->getWidth()*transform.origin.y);
            maxCellsToUpdate -= int(inputImage->getWidth()*transform.origin.y);
            // numCellsToUpdate -= int(inputImage->getWidth()*transform.origin.y);            
        }
        
        int jump = PropI(@"trackerColorAddJump");
        if(jump<=0)
            jump = 1;
        //        for(int i=0 ; i<numCellsToUpdate ; i+=jump,fluidColor+=jump, pixel+=jump){
        for(int i=0 ; i<numCellsToUpdate ; i++,fluidColor++, pixel++){
            if(i<maxCellsToUpdate){
                float pixelValue = factor * (*pixel);
                pixelValue /= 255.0;
                if(i%jump==0){
                    
                } else {
                    pixelValue *= 0.02;
                }
                *fluidColor += Vec3f(pixelValue*color.r, pixelValue*color.g , pixelValue * color.b);
            }
        }
    } else {
        NSLog(@"Scale not implemented in addImageToFluids");
    }
}

-(void) addImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color{
    [self addImageToFluids:inputImage withFactor:factor color:color transform:CGRectMake(0, OVERFLOW_TOP, 1, 1)];
}



-(void) subtractImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color{
    Vec3f * fluidColor = fluids->color + OVERFLOW_TOP*fluids->getWidth();
    unsigned char * pixel = inputImage->getPixels();
    for(int i=OVERFLOW_TOP*fluids->getWidth() ; i<fluids->getNumCells()-OVERFLOW_BOTTOM*fluids->getWidth() ; i++,fluidColor++, pixel++){
        float pixelValue = factor * (*pixel);
        pixelValue /= 255.0;
        *fluidColor -= Vec3f(pixelValue*color.r, pixelValue*color.g , pixelValue * color.b);
    }
}

-(void) multImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color{
    Vec3f * fluidColor = fluids->color + OVERFLOW_TOP*fluids->getWidth();
    unsigned char * pixel = inputImage->getPixels();
    //for(int i=0 ; i<fluids->getNumCells() ; i++,fluidColor++, pixel++){
    for(int i=OVERFLOW_TOP*fluids->getWidth() ; i<fluids->getNumCells()-OVERFLOW_BOTTOM*fluids->getWidth() ; i++,fluidColor++, pixel++){
        
        float pixelValue = factor * (*pixel);
        *fluidColor *= Vec3f(pixelValue*color.r, pixelValue*color.g , pixelValue * color.b);
    }
}
-(void) multInverseImageToFluids:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor color:(Color)color{
    Vec3f * fluidColor = fluids->color + OVERFLOW_TOP*fluids->getWidth();
    unsigned char * pixel = inputImage->getPixels();
    //    for(int i=0 ; i<fluids->getNumCells() ; i++,fluidColor++, pixel++){
    for(int i=OVERFLOW_TOP*fluids->getWidth() ; i<fluids->getNumCells()-OVERFLOW_BOTTOM*fluids->getWidth() ; i++,fluidColor++, pixel++){
        
        float pixelValue = factor * (*pixel);
        pixelValue /= 255.0;
        *fluidColor *= Vec3f(1-pixelValue*color.r, 1-pixelValue*color.g , 1-pixelValue * color.b);
    }
}


-(void) multInverseImageWithFluidsForces:(ofxCvGrayscaleImage*)inputImage withFactor:(float)factor {
    Vec2f * fluidUv = fluids->uv + OVERFLOW_TOP*fluids->getWidth();
    unsigned char * pixel = inputImage->getPixels();
    // for(int i=0 ; i<fluids->getNumCells() ; i++,fluidUv++, pixel++){
    for(int i=OVERFLOW_TOP*fluids->getWidth() ; i<fluids->getNumCells()-OVERFLOW_BOTTOM*fluids->getWidth() ; i++,fluidUv++, pixel++){
        float pixelValue = factor * (*pixel);
        *fluidUv *= fabs(1-pixelValue/255.0);
    }
    
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
    /*  [[GetPlugin(BlobTracker2d) getInstance:0] setBufferRecording:PropB(@"bufferRecord")];
     [[GetPlugin(BlobTracker2d) getInstance:0] setBufferPlaybackRate:PropF(@"bufferPlaybackRate")];    
     */
    
    NSColor * color = [NSColor colorWithCalibratedRed:PropF(@"colorR") green:PropF(@"colorG") blue:PropF(@"colorB") alpha:1.0];
    Color c(MSA::CM_RGB,  [color redComponent], [color greenComponent], [color blueComponent] );
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self controlMouseColor] setColor:color];
    });
    
    
    //------------- Tracker -------------------
    
    Tracker * tracker = GetPlugin(Tracker);
    trackerImage = [tracker trackerImageWithSize:CGSizeMake(fluids->getWidth(), fluids->getHeight()-OVERFLOW_TOTAL)];
    
    if(PropB(@"bufferRecord")){
        if(!alreadyRecording){
            alreadyRecording = YES;
            bufferRecordIndex = 0;
            NSLog(@"Start recording");
        }
        
        if(bufferRecordIndex >= BUFFER_SIZE){
            SetPropB(@"bufferRecord", NO);
            NSLog(@"Recording ran out of tape");
        } else {
            buffer[bufferRecordIndex++] = trackerImage;            
        }
    } else {
        alreadyRecording = NO;
    }
    
    if(PropB(@"bufferPlaybackReset")){
        SetPropB(@"bufferPlaybackReset", NO);
        for(int i=0;i<BUFFER_PLAYBACK_COUNT;i++){
            bufferPlaybackIndexes[i] = 0;
        }
    }
    
    if(PropB(@"bufferTriggerStart")){
        SetPropB(@"bufferTriggerStart", NO);
        bufferPlaybackOffset[bufferPlaybackCount] = int(PropF(@"bufferOffset")*100);
        bufferPlaybackIndexes[bufferPlaybackCount++] = bufferRecordIndex;
        
        if(bufferPlaybackCount >= BUFFER_PLAYBACK_COUNT){
            bufferPlaybackCount = 0;
        }
    }
    
    CachePropF(bufferAlpha);
    if(bufferAlpha){
        for(int i=0;i<BUFFER_PLAYBACK_COUNT;i++){
            if(bufferPlaybackIndexes[i] != 0){
                bufferPlaybackIndexes[i] -= PropF(@"bufferPlaybackRate");
                if(int(bufferPlaybackIndexes[i]) >=0 && int(bufferPlaybackIndexes[i]) < bufferRecordIndex){
                    int bufferIndex = int(bufferPlaybackIndexes[i]);
                    buffer[bufferIndex].setROI(100*PropF(@"bufferClipLeft"), 
                                               0, 
                                               fluids->getWidth()-100*PropF(@"bufferClipLeft"),  
                                               buffer[bufferIndex].getHeight());
                    cvResize(buffer[bufferIndex].getCvImage(), bufferTmp.getCvImage());
                    bufferTmp.flagImageChanged();
                    
                    [self addImageToFluids:&bufferTmp withFactor:bufferAlpha color:c transform:CGRectMake(0, bufferPlaybackOffset[i]+OVERFLOW_TOP, 1, 1)];                
                }
            }
        }
    }
    
    
    //---------------  ---------------
    
    
    surfaceAspect = Aspect(@"Floor",0);
    if(PropB(@"fluidsReset")){
        SetPropB(@"fluidsReset", 0);
        fluids->reset(); 
    }
    
    
    
    //-------- globalForce --------
    CachePropF(globalForce);
    if(globalForce){
        CachePropF(globalForceRotation);
        Vec2f f = Vec2f(0,globalForce*0.01);
        f.rotate(globalForceRotation*DEG_TO_RAD);
        for(int i=0;i<fluids->getNumCells();i++){
            fluids->uv[i] += f;
        }
    }
    
    //---------- mFluidWeight --------
    CachePropF(mFluidWeight);
    if(mFluidWeight){
        CachePropF(mFluidWeightDir);
        for(int i=0;i<fluids->getNumCells();i++){
            Color c = fluids->getColorAtIndex(i);
            Vec2f v = Vec2f(0,0.1*c.length()*pow(mFluidWeight,3));
            v.rotate(mFluidWeightDir*DEG_TO_RAD);
            fluids->addForceAtIndex(i, v);
        }
    }
    
    //---------- mSuckCenter --------    
    CachePropF(mSuckCenter);
    if(mSuckCenter){
        float w = fluids->getSize().x;
        float h = fluids->getSize().y;
        ofVec2f center = ofVec2f(0.5,0.5);
        int i=0;
        for(int y=0;y<h;y++){            
            for(int x=0;x<w;x++){
                ofVec2f p = ofVec2f(x/w, y/h);
                ofVec2f dir = center-p;
                fluids->addForceAtIndex(i, Vec2f(dir.x,dir.y)*mSuckCenter*0.01);
                i++;
            }
        }
        
    }
    
    // --------- mSuckCenterYAxis -------
    CachePropF(mSuckCenterYAxis);
    if(mSuckCenterYAxis){
        float w = fluids->getSize().x;
        float h = fluids->getSize().y;
        float center = 0.5;
        int i=0;
        for(int y=0;y<h;y++){            
            for(int x=0;x<w;x++){
                float p =y/h;
                float dir = center-p;
                fluids->addForceAtIndex(i, Vec2f(0,dir)*mSuckCenterYAxis*0.01);
                i++;
            }
        }
        
    }
    
    //---------- mSuckTracking --------    
    CachePropF(mSuckTracking);
    if(mSuckTracking){
        float w = fluids->getSize().x;
        float h = fluids->getSize().y;
        
        for(int t=0;t<[tracker numberTrackers];t++){
            ofVec2f center = [tracker trackerCentroid:t] / ofVec2f(surfaceAspect,1);
            int i=0;
            for(int y=0;y<h;y++){            
                for(int x=0;x<w;x++){
                    ofVec2f p = ofVec2f(x/w, y/h);
                    ofVec2f dir = center-p;
                    fluids->addForceAtIndex(i, Vec2f(dir.x,dir.y)*mSuckTracking*0.01);
                    i++;
                }
            }
        }
        
    }
    
    //------------- mTurnSpeed ----------
    CachePropF(mTurnForce);
    if(mTurnForce){
        CachePropF(mTurnSpeed);
        CachePropI(mTurnCount);
        
        for(int i=0;i<mTurnCount;i++){
            turnerPoints[i].pos += mTurnSpeed*0.01;
            
            while (turnerPoints[i].pos > 1) turnerPoints[i].pos -= 1;
            
            Vec2f p = 0.4*Vec2f(0.5,1) *Vec2f(sin(turnerPoints[i].pos*TWO_PI), cos(turnerPoints[i].pos*TWO_PI)) + Vec2f(0.5,0.5);
            Vec2f dir = -mTurnForce * mTurnSpeed * Vec2f(-cos(turnerPoints[i].pos*TWO_PI), sin(turnerPoints[i].pos*TWO_PI));
            
            fluids->addForceAtPos(p, dir);
        }
        
    }
    
    //---------- Twirl -------------
    CachePropF(globalTwirl);
    if(globalTwirl){
        int i=0;
        for(int y=0;y<fluids->getSize().y;y++){            
            for(int x=0;x<fluids->getSize().x;x++){
                ofVec2f p = ofVec2f(x/fluids->getSize().x-0.5,y/fluids->getSize().y-0.5);
                ofVec2f hat = ofVec2f(-p.y*0.5,p.x);
                fluids->uv[i] += ( Vec2f(hat.x,hat.y) * globalTwirl - fluids->uv[i])*0.02;
                i++;
            }
        }
    }
    
    
    
    //--------- OpticalFlow --------
    CachePropF(opticalFlowForce);
    if(opticalFlowForce){
        opticalFlowField = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowFieldCalibrated];
        if(opticalFlowField != nil){
            CachePropF(opticalFlowForceMin);
            
            opticalW = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowW];
            opticalH = [[GetPlugin(BlobTracker2d) getInstance:0] opticalFlowH];
            
            ofVec2f * field = opticalFlowField;
            for(int y=0;y<opticalH;y++){
                for(int x=0;x<opticalW;x++){
                    ofVec2f f = *field++;
                    float l = f.lengthSquared();
                    if(l > opticalFlowForceMin){                    
                        fluids->addForceAtPos(Vec2f((float)x/opticalW, (float)y/opticalH), Vec2f(f.x,f.y)*opticalFlowForce);
                    }
                }
            }
            
        }
    }
    
    
    //------ Tracker Color ----------
    CachePropF(trackerColorAdd);
    if(trackerColorAdd){
        [self addImageToFluids:&trackerImage withFactor:trackerColorAdd color:c];
    }
    
    //------ Tracker Black ----------
    CachePropF(trackerBlack);
    if(trackerBlack){
        [self multInverseImageToFluids:&trackerImage withFactor:trackerBlack color:Color(CM_RGB,1,1,1)];
        
    }
    
    //------ Tracker Block Force ----------    
    CachePropF(trackerForceBlock);
    if(trackerForceBlock){
        [self multInverseImageWithFluidsForces:&trackerImage withFactor:trackerForceBlock];
    }
    
    
    //--------------- generateLinesSide ---------
    CachePropF(generateLinesSideNum);
    if(generateLinesSideNum){
        CachePropF(generateLinesSideDuration);
        for(int i=0;i<generateLinesSideNum;i++){
            if(fluidLines[i].countdown <= 0){
                fluidLines[i].countdown = ofRandom(generateLinesSideDuration*100,generateLinesSideDuration*500);
                fluidLines[i].pos = ofRandom(OVERFLOW_TOP/(FLUIDS_HEIGHT+OVERFLOW_TOTAL),(FLUIDS_HEIGHT+OVERFLOW_TOP)/(FLUIDS_HEIGHT+OVERFLOW_TOTAL));
            } else {
                fluids->addColorAtPos(Vec2f(0.99,fluidLines[i].pos), c);
            }
            
            fluidLines[i].countdown--;
            
            
        }
    }
    
    //-------------- Generate Drops ----------------
    CachePropF(generateDrops);
    if(generateDrops > 0){
        SetPropF(@"generateDrops", generateDrops-0.1);
        
        float radius = 0.02; 
        int i=0;
        for(int y=0;y<fluids->getSize().y;y++){            
            for(int x=0;x<fluids->getSize().x;x++){
                ofVec2f p = ofVec2f(x/fluids->getSize().x, y/fluids->getSize().y);
                if (p.distance(dropsPos) < radius) {
                    fluids->addColorAtIndex(i, c);           
                }
                i++;
            }
        }
    } else if(generateDrops < 0){
        SetPropF(@"generateDrops", 0);
        dropsPos = ofVec2f(ofRandom(0.1,0.9), ofRandom(0.26,0.30));
        
    }
    
    
    //------------- generateFallingFluids ---------
    CachePropF(generateFallingFluids);
    if(generateFallingFluids){
        fallingFluidsPos = (sin((ofGetElapsedTimeMillis()/1000.0)/generateFallingFluids)+1)/2.0 + ofRandom(-0.1,0.1);
        for(int i=-5;i<5;i++){
            fluids->addColorAtPos(Vec2f(fallingFluidsPos+i*1.0/fluids->getWidth(),0.1), c);
        }
        
    }
    
    //------------- generateStartLight ---------
    CachePropF(generateStartLight);
    int startLightCount = 100;
    if(generateStartLight){
        float _distance = generateStartLight*0.8;
        for(int i=0;i<startLightCount;i++){
            if((startLight[i].countdown--) <= 0){
                startLight[i].countdown = ofRandom(5,30);                

                ofVec2f offset = ofVec2f(ofRandom(0,_distance),0).rotated(ofRandom(0,360));                
                offset /= ofVec2f(1.5,1);
                
                startLight[i].pos = Vec2f(0.5+offset.x, 0.5+offset.y);
            }

            float fOffsetX = 1.0/fluids->getWidth();
            float fOffsetY = 1.0/fluids->getHeight();
            
            fluids->addColorAtPos(startLight[i].pos-Vec2f(fOffsetX,0), c);
            fluids->addColorAtPos(startLight[i].pos-Vec2f(0,fOffsetY), c);
            fluids->addColorAtPos(startLight[i].pos, c);
            fluids->addColorAtPos(startLight[i].pos+Vec2f(fOffsetX,0), c);
            fluids->addColorAtPos(startLight[i].pos+Vec2f(0,fOffsetY), c);
        }
    }
    

    
    //---------------------------
    
    
    if([[self controlMouseColorEnabled] state] && lastControlMouse.x != -1){
        NSColor * color = [[self controlMouseColor] color];
        Color c(MSA::CM_RGB,  [color redComponent], [color greenComponent], [color blueComponent] );
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
            }
        }
        
    }
    
    //------
    int i=0;
    for(int y=0;y<fluids->getSize().y;y++){            
        for(int x=0;x<fluids->getSize().x;x++){
            if(x <= 1 || y <= 1 || x >= fluids->getWidth() -2  || y >= fluids->getHeight() -2 ){
                fluids->color[i] = Vec3f(0,0,0);
                // fluids->uv[i] = Vec2f(0,0);
            }
            i++;
        }
    }
    //---------------------------
    
    fluids->setDeltaT(PropF(@"fluidsDeltaT")*60.0/ofGetFrameRate());
    fluids->setFadeSpeed(pow(PropF(@"fluidsFadeSpeed"),3));
    fluids->setSolverIterations(PropI(@"fluidsSolverIterations"));
    fluids->setVisc(pow(PropF(@"fluidsVisc")*0.2,3)*0.1);
    fluids->update();
    
    
    
    
    //-----
    CachePropF(postGain);
    
    unsigned char * pixel = (unsigned char*) fluidImage.getCvImage()->imageData;
    Vec3f * fluidPixel = fluids->color + OVERFLOW_TOP * fluids->getWidth(); 
    for(int i=0;i<fluidImage.width*fluidImage.height*3; i++,pixel++){
        if(i%3 == 0){
            fluidPixel++;
        }
        if(i > 0 && (i) % (3*(fluids->getWidth()-2)) == 0){
            fluidPixel++;
            fluidPixel++;
        }
        
        *pixel  = MIN((*fluidPixel)[i%3]*255*(1+postGain),255);
    }
    fluidImage.flagImageChanged();
    
    
    
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    //    fluidsDrawer->setDrawMode(kFluidDrawColor);
    //    fluidsDrawer->draw(0,0,1,1);
    ApplySurface(@"Floor"){
        //    fluidsDrawer->getTextureReference().draw(0, 0, surfaceAspect, 1);
        
        ofEnableAlphaBlending();
        
        CachePropF(maskTrackingBack);
        CachePropF(maskTrackingFront);
        
        ofxCvGrayscaleImage mask = trackerImage;
        if(maskTrackingBack || maskTrackingFront){
            //    Tracker * tracker = GetPlugin(Tracker);
            //  mask = [tracker trackerImageWithSize:CGSizeMake(fluids->getWidth(), fluids->getHeight())];
            mask.dilate_3x3();
            mask.dilate_3x3();
            mask.dilate_3x3();
            mask.dilate_3x3();
            mask.blurGaussian(15);
            mask.invert();
        }
        
        
        if(ViewNumber == 0){
            //Back
            ofSetColor(255, 255, 255);
            ofRect(0, 0, surfaceAspect, 1);            
            
            // --- Vertical mask --
            CachePropF(maskVerticalBack);
            if(maskVerticalBack){
                for (int i=0; i<9; i++) {
                    ofSetColor(255, 255, 255,255*maskVerticalBack);
                    verticalMaskBlack->draw(i*surfaceAspect/8.0-0.05,0,0.1,1);                    
                }
            }
            
            
            //---- Tracking mask ----
            if(maskTrackingBack){
                ofSetColor(255, 255, 255,255*maskTrackingBack);
                mask.invert();
                mask.draw(0, 0,surfaceAspect,1);
                mask.invert();
            }
            glBlendFunc(GL_DST_COLOR, GL_ZERO);
            
        } 
        if(ViewNumber == 1){
            //Front
            
            // --- Vertical mask --
            CachePropF(maskVerticalFront);
            if(maskVerticalFront){
                for (int i=0; i<9; i++) {
                    ofSetColor(255, 255, 255,255*maskVerticalFront);
                    verticalMaskWhite->draw(i*surfaceAspect/8.0-0.05,0,0.1,1);
                }
                
                
            }
            
            ofSetColor(255,255,255,255*(1-maskVerticalFront));
            ofRect(0, 0, surfaceAspect, 1);
            
            //---- Tracking mask ----
            if(maskTrackingFront){
                ofSetColor(255, 255, 255,255*maskTrackingFront);
                
                mask.draw(0, 0,surfaceAspect,1);
            }
            
            glBlendFunc(GL_DST_COLOR, GL_ZERO);
            
        }
        
        
        
        float alpha = 1.0;
        switch (ViewNumber) {
            case 1:
                alpha = PropF(@"projectorFront");
                break;
            case 0:
                alpha = PropF(@"projectorBack");
                break;
            default:
                break;
        }
        ofSetColor(255*alpha, 255*alpha, 255*alpha);
        fluidImage.draw(0, 0,aspect,1);
        
        
        
    } PopSurface();
    
    ofSetColor(255, 255, 255);
    
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

