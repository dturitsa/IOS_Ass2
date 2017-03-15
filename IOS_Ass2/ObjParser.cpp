//
//  ObjParser.cpp
//  IOS_Ass2
//
//  Created by Denis Turitsa on 2017-03-14.
//  Copyright © 2017 Denis Turitsa. All rights reserved.
//
/*
#include "ObjParser.h"
#include <iostream>
#include <fstream>
#include <string>
using namespace std;

int CPlusPlus::GetVal()
{
    //printf("%s \n", fp);
    
    // 2
    Model model = {0};
    
    // 3
    // Open OBJ file
    ifstream inOBJ;
    inOBJ.open("cubeTest3.obj");
    if(!inOBJ.good())
    {
        printf("couldnt find file \n");
        cout << "ERROR OPENING OBJ FILE" << endl;
        exit(1);
    }
    printf("found file\n");
    // 4
    // Read OBJ file
    while(!inOBJ.eof())
    {
        // 5
        string line;
        getline(inOBJ, line);
        string type = line.substr(0,2);
        
        // 6
        if(type.compare("v ") == 0)
            model.positions++;
        else if(type.compare("vt") == 0)
            model.texels++;
        else if(type.compare("vn") == 0)
            model.normals++;
        else if(type.compare("f ") == 0)
            model.faces++;
    }
    
    // 7
    model.vertices = model.faces*3;
    
    // 8
    // Close OBJ file
    inOBJ.close();
    return val;
}

void CPlusPlus::SetVal(int newVal)
{
    val = newVal;
}

void CPlusPlus::IncrVal(int incr)
{
    val += incr;
}

Model getOBJinfo(char* fp)
{
    printf("%s \n", fp);
    
    // 2
    Model model = {0};
    
    // 3
    // Open OBJ file
    ifstream inOBJ;
    inOBJ.open(fp);
    if(!inOBJ.good())
    {
        printf("couldnt find file \n");
        cout << "ERROR OPENING OBJ FILE" << endl;
        exit(1);
    }
    printf("found file");
    // 4
    // Read OBJ file
    while(!inOBJ.eof())
    {
        // 5
        string line;
        getline(inOBJ, line);
        string type = line.substr(0,2);
        
        // 6
        if(type.compare("v ") == 0)
            model.positions++;
        else if(type.compare("vt") == 0)
            model.texels++;
        else if(type.compare("vn") == 0)
            model.normals++;
        else if(type.compare("f ") == 0)
            model.faces++;
    }
    
    // 7
    model.vertices = model.faces*3;
    
    // 8
    // Close OBJ file
    inOBJ.close();
    
    // 9
    return model;
    
}
*/

