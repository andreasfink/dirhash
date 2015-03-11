//
//  main.m
//  dirhash
//
// creates a hash of every file in a directory
//
//  Created by Andreas Fink on 11/03/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stddef.h>
#include <stdio.h>
#include <time.h>
#import "FileEntry.h"

int main(int argc, const char *argv[])
{
    NSMutableArray *pathsToCheck = [[NSMutableArray alloc]init];
    const char      *outputfilename = "dirhash.plist";

    @autoreleasepool
    {
        const char *toolname = argv[0];
        int i;
        if(argc==1)
        {
            fprintf(stderr,"Usage: %s --output <outputfile> {PathToXCode.app} ...\n",toolname);
            exit(0);
        }
        for(i=1;i<argc;i++)
        {
            const char *option = argv[i];
            
            if((strcmp(option,"-?")==0) || (strcmp(option,"-h")==0) || (strcmp(option,"--help")==0))
            {
                fprintf(stderr,"Usage: %s --output <outputfile> {PathToXCode.app} ...\n",toolname);
                exit(0);
            }
            if(strcmp(option,"--output")==0)
            {
                i++;
                if(i < argc)
                {
                    outputfilename = argv[i];
                    
                }
            }
            else
            {
                [pathsToCheck addObject:@(argv[i])];
            }
        }

        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];

        for(NSString *root in pathsToCheck)
        {
            fprintf(stderr,"Scanning path %s:\n",root.UTF8String);
            NSMutableArray *allFileEntries = [[NSMutableArray alloc]init];
            NSMutableArray *allFileInfos = [[NSMutableArray alloc]init];
            NSFileManager *mgr = [NSFileManager defaultManager];
            for (NSString *filePath in [mgr enumeratorAtPath:root])
            {
                FileEntry *e = [[FileEntry alloc]initWithRoot:root path:filePath];
                [allFileEntries addObject:e];
            }
            NSArray *sortedFileEntries = [allFileEntries sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            for(FileEntry *e in sortedFileEntries)
            {
                fprintf(stderr," %s/\n",e.relativePath.UTF8String);
                [allFileInfos addObject:[e processEntry]];
            }
            dict[root] = allFileInfos;
        }
        [dict writeToFile:@(outputfilename) atomically:YES];
    }
    return 0;
}

