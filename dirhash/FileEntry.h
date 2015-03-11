//
//  FileEntry.h
//  dirhash
//
//  Created by Andreas Fink on 11/03/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FileEntry : NSObject
{
    NSString    *absolutePath;
    NSString    *relativePath;
    BOOL         isDirectory;
}

@property(readwrite,strong)     NSString *absolutePath;
@property(readwrite,strong)     NSString *relativePath;
@property(readwrite,assign)     BOOL     isDirectory;

- (FileEntry *)initWithRoot:(NSString *)root path:(NSString *)path;

- (NSComparisonResult)caseInsensitiveCompare:(FileEntry *)other;
- (NSDictionary *)processEntry;

@end
