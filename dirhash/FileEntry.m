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
#include "version.h"
#include "sha512.h"

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
    struct stat   filestat;
    void         *fileData;
    uint8_t       hash[CC_SHA512_DIGEST_LENGTH]; /* this hash is calculated via CC_SHA512 */
    uint8_t       hash2[SHA512_DIGEST_LENGTH];   /* this hash is calculated via included sha512 */

    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"path"] = relativePath;
    int res = stat(absolutePath.UTF8String, &filestat);
    if(res!=0)
    {
        dict[@"error_cmd"] = @"stat";
        dict[@"error_errno"] = [NSNumber numberWithLongLong:(long long)errno];
        return dict;
    }
    dict[@"dev"]        = [NSNumber numberWithLongLong:(long long)filestat.st_dev];
    dict[@"ino"]        = [NSNumber numberWithLongLong:(long long)filestat.st_ino];
    dict[@"mode"]       = [NSNumber numberWithLongLong:(long long)filestat.st_mode];
    dict[@"nlink"]      = [NSNumber numberWithLongLong:(long long)filestat.st_nlink];
    dict[@"uid"]        = [NSNumber numberWithLongLong:(long long)filestat.st_uid];
    dict[@"gid"]        = [NSNumber numberWithLongLong:(long long)filestat.st_gid];
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
        dict[@"warning"] = @"File is larger than 4G";
    }

    int fd = open(absolutePath.UTF8String, O_RDONLY);
    if (fd == -1)
    {
        dict[@"error_cmd"] = @"open";
        dict[@"error_errno"] = [NSNumber numberWithLongLong:(long long)errno];
        return dict;
    }
    
    size_t fileLength = filestat.st_size;
    fileData = mmap((caddr_t)0, fileLength, PROT_READ, MAP_SHARED, fd, 0);
    if (fileData ==  (caddr_t)(-1))
    {
        dict[@"error_cmd"] = @"mmap";
        dict[@"error_errno"] = [NSNumber numberWithLongLong:(long long)errno];
        close(fd);
        return dict;
    }
    sha512(fileData,fileLength, hash2);
    if(filestat.st_size > 0xFFFFFFFFLL) /* the SHA macro only work with up to uint32_t size */
    {
        dict[@"sha512"]  = [NSData dataWithBytes:hash2 length:SHA512_DIGEST_LENGTH];
    }
    else
    {
        if (CC_SHA512(fileData,(unsigned int)fileLength, hash))
        {
            dict[@"sha512"]  = [NSData dataWithBytes:hash length:CC_SHA512_DIGEST_LENGTH];
        }
        if(memcmp(hash,hash2,SHA512_DIGEST_LENGTH)!=0)
        {
            fprintf(stderr,"CC_SHA512 does not match sha512 hash");
            dict[@"sha512b"]  = [NSData dataWithBytes:hash2 length:SHA512_DIGEST_LENGTH];
        }
    }
    munmap(fileData, fileLength);
    close(fd);
    return dict;
}

@end
