#import "Test.h"
#import <ofxCocoaPlugins/Keystoner.h>

@implementation Test

-(void)initPlugin{
    [self addPropF:@"whiteBack"];   
    [self addPropF:@"whiteFront"];
    [self addPropF:@"grovKalibrering"];

}

//
//----------------
//


-(void)setup{
}

//
//----------------
//


-(void)update:(NSDictionary *)drawingInformation{
}

//
//----------------
//

-(void)draw:(NSDictionary *)drawingInformation{
    ofFill();
    if(ViewNumber == 0){
        if(PropF(@"whiteBack")){
            ofSetColor(255, 255, 255);
            ofRect(0, 0, 1, 1);
            
            ofSetColor(0, 0, 0);
            ApplySurface(@"Floor"){
                ofSetLineWidth(10);
                ofLine(0,-0.5,0,1.2);
                ofLine(0.3333,-0.5,0.3333,1.2);
                ofLine(0.66666,-0.5,0.66666,1.2);
                ofLine(1,-0.5,1,1.2);
                                ofSetLineWidth(1);
            } PopSurfaceWithoutSoftedge();
        } 
        
        
                                     
    } else {
        if(PropF(@"whiteFront")){
            ofSetColor(255, 255, 255);
            ofRect(0, 0, 1, 1);
        }
    }
    
    
    if(PropF(@"grovKalibrering")){
        if([GetPlugin(Keystoner) selectedOutputview] == ViewNumber){
            int selProj = [GetPlugin(Keystoner) selectedProjector];
            int numViews = 1;
            if(ViewNumber == 0)
                numViews = 3;
            
            ApplySurface(@"Floor"){
                ofSetColor(255, 0, 0);
                ofRect(1.0/numViews*selProj, 0, 1.0/numViews, 1);
                ofNoFill();
                ofSetColor(255, 255, 255);
                ofSetLineWidth(3);
                ofRect(1.0/numViews*selProj, 0, 1.0/numViews, 1);                
                ofSetLineWidth(1);
                ofFill();
            } PopSurfaceWithoutSoftedge();
        }
    }
    
}

//
//----------------
//

-(void)controlDraw:(NSDictionary *)drawingInformation{    
}

@end
