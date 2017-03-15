//
//  ObjParser.m
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-14.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ObjParser.h"

@interface ObjParser()
{
    
    
}

//- (int) parseFile :(NSString *)file;
-(void) parseFile;

@end

@implementation ObjParser

-(void) parseFile{
    float x, y, z;
    NSScanner *scanner;
    
    //float finalArray[36];
    NSMutableArray *vertexArray;
    VertexObj *vInfo = [[VertexObj alloc] init];
    
    NSLog(@"parsingobj");
    /*
    //NSString *path = NSBundle.mainBundle().pathForResource("cubeTest3.obj")
    NSString *s = String(contentsOfFile: NSBundle.mainBundle().pathForResource("cubeTest3.obj"),
                           encoding: NSUTF8StringEncoding,
                           error: nil);
    
    // read everything from text
     */
    //NSString* filePath = @"cubeTest3.obj";//file path...
    NSString* fileRoot = [[NSBundle mainBundle]
                          pathForResource:@"cubeTest3" ofType:@"obj"];
    
    NSString* fileContents =
    [NSString stringWithContentsOfFile:fileRoot
                              encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray* allLinedStrings =
    [fileContents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
    
    // then break down even further
    /*
    NSString* strsInOneLine =
    [allLinedStrings objectAtIndex:5];
    */
    GLKVector2 t;
    GLKVector3 v;
    GLKVector3 n;
    
    int tCount = 1;
    int vCount = 1;
    int nCount = 1;
    int fCount = 0;
    
    GLKVector3 vArray[[allLinedStrings count]];
    GLKVector3 nArray[[allLinedStrings count]];
    GLKVector2 tArray[[allLinedStrings count]];
    
    int vIndex, nIndex, tIndex;

    for (NSString* line in allLinedStrings) {
        scanner = [NSScanner scannerWithString:line];
      
      //  NSMutableArray *vArray, *tArray, *nArray;
        
        if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 't') {
           // NSScanner *scanner = [NSScanner scannerWithString:line];
            [scanner scanUpToString:@" " intoString:NULL];
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&t.x];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&t.y];

            tArray[tCount] = t;
            tCount++;
            //NSLog(@"Scanned texture %f, %f", t.x, t.y);
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == 'n') {
           // NSScanner *scanner = [NSScanner scannerWithString:line];
            [scanner scanUpToString:@" " intoString:NULL];
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&n.x];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&n.y];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&n.z];
            
            nArray[nCount] = n;
            nCount++;
           // NSLog(@"Scanned Normals %f, %f. %f", n.x, n.y, n.z);
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'v' && [line characterAtIndex:1] == ' ') {
           // NSScanner *scanner = [NSScanner scannerWithString:line];
            [scanner scanUpToString:@" " intoString:NULL];
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&v.x];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&v.y];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanFloat:&v.z];
            
            vArray[vCount] = v;
            vCount++;
            //NSLog(@"Scanned verteces %f, %f. %f", v.x, v.y, v.z);
        }
        else if (line.length > 1 && [line characterAtIndex:0] == 'f'){
            [scanner scanUpToString:@" " intoString:NULL];
            
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanInt:&vIndex];
            vInfo->v = vArray[vIndex];
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanInt:&tIndex];
            vInfo->t = tArray[tIndex];
            [scanner setScanLocation:[scanner scanLocation] + 1];
            [scanner scanInt:&nIndex];
             vInfo->n = nArray[nIndex];
            [vertexArray addObject:(vInfo)];
            //TODO: make custom face object with vtn
            
        }
        
  
    }
    VertexObj *retrievedInfo = vertexArray[1];
    NSLog(@"Scanned verteces %f, %f, %f", retrievedInfo->v.x, retrievedInfo->v.y, retrievedInfo->v.z);
    retrievedInfo = vertexArray[2];
    NSLog(@"Scanned verteces %f, %f, %f", retrievedInfo->v.x, retrievedInfo->v.y, retrievedInfo->v.z);
    retrievedInfo = vertexArray[3];
    NSLog(@"Scanned verteces %f, %f, %f", retrievedInfo->v.x, retrievedInfo->v.y, retrievedInfo->v.z);
   // NSLog(@"Scanned verteces %f, %f. %f", tArray[7].x, tArray[7].y, tArray[7].y);
    
    /*
     // choose whatever input identity you have decided. in this case ;
     NSArray* singleStrs =
     [currentPointString componentsSeparatedByCharactersInSet:
     [NSCharacterSet characterSetWithCharactersInString:@";"]];
     */
}

@end
