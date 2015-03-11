//
//  FileEntry.m
//  dirhash
//
//  Created by Andreas Fink on 11/03/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "FileEntry.h"
#import <CommonCrypto/CommonDigest.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

@implementation FileEntry

@synthesize absolutePath;
@synthesize relativePath;
@synthesize isDirectory;

- (FileEntry *)initWithRoot:(NSString *)root path:(NSString *)path;
{
    self = [super init];
    if(self)
    {
        self.absolutePath=[root stringByAppendingPathComponent:path];
        self.relativePath=path;
    }
    return self;
}

- (NSComparisonResult)caseInsensitiveCompare:(FileEntry *)other
{
    return [relativePath caseInsensitiveCompare:other.relativePath];
}

- (NSDictionary *)processEntry
{
    struct stat filestat;
    uint32_t  fileLength;
    void    *fileData;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"path"] = relativePath;
    int res = stat(absolutePath.UTF8String, &filestat);
    if(res!=0)
    {
        dict[@"stat_error"] = [NSNumber numberWithLongLong:(long long)errno];
        return dict;
    }
    dict[@"dev"]        = [NSNumber numberWithLongLong:(long long)filestat.st_dev];
    dict[@"ino"]        = [NSNumber numberWithLongLong:(long long)filestat.st_ino];
    dict[@"mode"]       = [NSNumber numberWithLongLong:(long long)filestat.st_mode];
    dict[@"nlink"]      = [NSNumber numberWithLongLong:(long long)filestat.st_nlink];
    dict[@"uid"]        = [NSNumber numberWithLongLong:(long long)filestat.st_uid];
    dict[@"uid"]        = [NSNumber numberWithLongLong:(long long)filestat.st_uid];
    dict[@"rdev"]       = [NSNumber numberWithLongLong:(long long)filestat.st_rdev];
    dict[@"at_time"]    = [NSNumber numberWithLongLong:(long long)filestat.st_atimespec.tv_sec];
    dict[@"atimespec"]  = [NSNumber numberWithLongLong:(long long)filestat.st_atimespec.tv_sec];
    dict[@"mtimespec"]  = [NSNumber numberWithLongLong:(long long)filestat.st_mtimespec.tv_sec];
    dict[@"ctimespec"]  = [NSNumber numberWithLongLong:(long long)filestat.st_ctimespec.tv_sec];
    dict[@"size"]       = [NSNumber numberWithLongLong:(long long)filestat.st_size];
    dict[@"blocks"]     = [NSNumber numberWithLongLong:(long long)filestat.st_blocks];
    dict[@"blksize"]    = [NSNumber numberWithLongLong:(long long)filestat.st_blksize];
    dict[@"flags"]      = [NSNumber numberWithLongLong:(long long)filestat.st_flags];
    dict[@"gen"]        = [NSNumber numberWithLongLong:(long long)filestat.st_gen];
    isDirectory         = S_ISDIR(filestat.st_mode);
    dict[@"isDirectory"]= @(isDirectory);
    
    if(isDirectory)
    {
        return dict;
    }

    if(filestat.st_size > 0xFFFFFFFFLL) /* the SHA functions only work with up to uint32_t size */
    {
        dict[@"error"] = @"File is larger than 4G";
        return dict;
    }

    int fd = open(absolutePath.UTF8String, O_RDONLY);
    if (fd == -1)
    {
        dict[@"open_error"] = [NSNumber numberWithLongLong:(long long)errno];
        return dict;
    }
    

    fileLength = (uint32_t)filestat.st_size;
    fileData = mmap((caddr_t)0, fileLength, PROT_READ, MAP_SHARED, fd, 0);
    if (fileData ==  (caddr_t)(-1))
    {
        dict[@"mmap_error"] = [NSNumber numberWithLongLong:(long long)errno];
        close(fd);
        return dict;
    }
    
    unsigned char hash[CC_SHA512_DIGEST_LENGTH];
    if (CC_SHA512(fileData,fileLength, hash))
    {
        dict[@"sha512"]  = [NSData dataWithBytes:hash length:CC_SHA512_DIGEST_LENGTH];
    }
    close(fd);
    return dict;
}

@end
