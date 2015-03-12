//
//  main.m
//  dirhashdiff
//
//  Created by Andreas Fink on 12/03/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stddef.h>
#include <stdio.h>
#include <time.h>
#import "FileEntry.h"
#include "../dirhash/version.h"
#include <bzlib.h>

BOOL detailed = NO;
NSDictionary *readFile(NSString *filename);
NSDictionary *readCompressedFile(NSString *filename);
NSDictionary *readUncompressedFile(NSString *filename);
void compareDicts(NSDictionary *referenceDict,NSDictionary *compareDict,FILE *out);
void compareEntries(NSDictionary *referenceDict,NSDictionary *compareDict,FILE *out);

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        NSString        *referenceFileName = NULL;
        NSMutableArray  *compareToFileNames = [[NSMutableArray alloc]init];
        
        const char *toolname = argv[0];
        int i;
        if(argc==1)
        {
            fprintf(stderr,"Usage: %s {Reference-file} {diff-file(s)...}\n  (Files can be plist files or bz2 compressed plist files ending in .bz2)\n",toolname);
            exit(0);
        }
        for(i=1;i<argc;i++)
        {
            const char *option = argv[i];
            
            if((strcmp(option,"-?")==0) || (strcmp(option,"-h")==0) || (strcmp(option,"--help")==0))
            {
                fprintf(stderr,"Usage: %s {Reference-file} {diff-file(s)...}\n  (Files can be plist files or bz2 compressed plist files ending in .bz2)",toolname);
                exit(0);
            }

            if(strcmp(option,"--detailed")==0)
            {
                detailed = YES;
            }
            else if(strcmp(option,"--version")==0)
            {
                fprintf(stderr,"%s version %s",argv[0],VERSION);
                exit(0);
            }
            else
            {
                if(referenceFileName == NULL)
                {
                    referenceFileName = @(argv[i]);
                }
                else
                {
                    [compareToFileNames addObject:@(argv[i])];
                }
            }
        }
        if((referenceFileName == NULL) || ( [compareToFileNames count]< 1))
        {
            fprintf(stderr,"Usage: %s {Reference-file} {diff-file(s)...}\n  (Files can be plist files or bz2 compressed plist files ending in .bz2)",toolname);
            exit(0);
        }
        NSDictionary *referenceDict = readFile(referenceFileName);
        if(referenceDict==NULL)
        {
            fprintf(stderr,"could not parse file '%s'\n",referenceFileName.UTF8String);
            exit(0);
        }
        
        for(NSString *compareFile in compareToFileNames)
        {
            
            NSDictionary *compareDict = readFile(compareFile);
            if(compareDict==NULL)
            {
                fprintf(stderr,"could not parse file '%s'\n",compareFile.UTF8String);
                exit(0);
            }
            compareDicts(referenceDict,compareDict,stdout);
        }
    }
    return 0;
}


#define BUFFERSIZE  (4096*1024) // 4MB

NSDictionary *readCompressedFile(NSString *filename)
{
    int bzError;
    BZFILE *bzf;
    char buf[BUFFERSIZE];

    NSMutableData *data = [[NSMutableData alloc]init];
    FILE *inputFile = fopen(filename.UTF8String,"rb");
    if(inputFile==NULL)
    {
        fprintf(stderr,"Can not open file %s. errno=%d",filename.UTF8String,errno);
        return NULL;
    }

    bzf = BZ2_bzReadOpen(&bzError, inputFile, 0, 0, NULL, 0);
    if (bzError != BZ_OK)
    {
        fprintf(stderr, "Error: BZ2_bzReadOpen: %d\n", bzError);
        return NULL;
    }
        
    while (bzError == BZ_OK)
    {
        int nread = BZ2_bzRead(&bzError, bzf, buf, sizeof(buf) );
        if (bzError == BZ_OK || bzError == BZ_STREAM_END)
        {
            [data appendBytes:buf length:nread];
        }
    }
    
    if (bzError != BZ_STREAM_END)
    {
        fprintf(stderr, "Error: bzip error after read: %d\n", bzError);
        return NULL;
    }
    BZ2_bzReadClose(&bzError, bzf);
    fclose(inputFile);

    NSError *err = NULL;
    NSDictionary *d = [NSPropertyListSerialization propertyListWithData:data
                                                                options:0
                                                                 format:NULL
                                                                  error:&err];
    if(err)
    {
        fprintf(stderr, "Error: propertyListWithData %s\n", err.description.UTF8String);
        return NULL;
    }
    return d;
}

NSDictionary *readUncompressedFile(NSString *filename)
{
   return [NSDictionary dictionaryWithContentsOfFile:filename];
}

NSDictionary *readFile(NSString *filename)
{
    if([filename hasSuffix:@"bz2"])
    {
        return readCompressedFile(filename);
    }
    return readUncompressedFile(filename);
}

void compareDicts(NSDictionary *referenceDict,NSDictionary *compareDict,FILE *out)
{
    /* phase 1 go through filenames to see which ones are only in one file */
    NSMutableDictionary *jointFileDict       = [[NSMutableDictionary alloc]init];
    NSMutableArray *referenceFileNames       = [[NSMutableArray alloc]init];
    NSMutableArray *compareFileNames         = [[NSMutableArray alloc]init];
    NSMutableArray *onlyInRefFiles           = [[NSMutableArray alloc]init];
    NSMutableArray *onlyInCompareFiles       = [[NSMutableArray alloc]init];
    NSMutableArray *inBothFiles              = [[NSMutableArray alloc]init];

    /* filedata is a dictionary of absolute paths containing arrays of dictionary with relative paths and other info on every file. For now we only take the first block */
    NSDictionary *d1 = referenceDict[@"filedata"];
    NSArray *referenceRoots = [d1 allKeys];
    NSString *root1 = [referenceRoots objectAtIndex:0];
    NSArray *referenceFileEntries = d1[root1];
    
    NSDictionary *d2 = compareDict[@"filedata"];
    NSArray *compareRoots = [d2 allKeys];
    NSString *root2 = [compareRoots objectAtIndex:0];
    NSArray *compareFileEntries = d2[root2];

    if(referenceFileEntries == NULL)
    {
        fprintf(stderr,"Reference file does not have entry for filedata");
        exit(0);
    }
    if(compareFileEntries == NULL)
    {
        fprintf(stderr,"Compare file does not have entry for filedata");
        exit(0);
    }
    
    for(NSDictionary *entry in referenceFileEntries)
    {
        NSString *fnam = entry[@"path"];
        NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
        d[@"ref"]=entry;
        jointFileDict[fnam] = d;
        [referenceFileNames addObject:fnam];
    }
    for(NSDictionary *entry in compareFileEntries)
    {
        NSString *fnam = entry[@"path"];
        NSMutableDictionary *d = jointFileDict[fnam];
        if(d == NULL)
        {
            [onlyInCompareFiles addObject:fnam];
            d = [[NSMutableDictionary alloc]init];
        }
        d[@"cmp"]=entry;
        jointFileDict[fnam] = d;
        [compareFileNames addObject:fnam];
    }
    for(NSString *fnam in referenceFileNames)
    {
        NSMutableDictionary *d = jointFileDict[fnam];
        if(d[@"cmp"] == NULL)
        {
            [onlyInRefFiles addObject:fnam];
        }
        else
        {
            [inBothFiles addObject:fnam];
        }
    }
    fprintf(out,"File Comparison Summary\n");
    fprintf(out,"-----------------------\n");
    fprintf(out,"Files only in Reference: %d\n",(int)[onlyInRefFiles count]);
    fprintf(out,"Files only in Comparision: %d\n",(int)[onlyInCompareFiles count]);
    fprintf(out,"Files in both: %d\n",(int)[inBothFiles count]);
    fprintf(out,"-----------------------\n");
    fprintf(out,"Files in reference but missing in comparison\n");
    for(NSString *fnam in onlyInRefFiles)
    {
        fprintf(out," %s\n",fnam.UTF8String);
    }
    fprintf(out,"-----------------------\n");
    fprintf(out,"Files in comparision missing in reference\n");
    for(NSString *fnam in onlyInCompareFiles)
    {
        fprintf(out," %s\n",fnam.UTF8String);
    }
    fprintf(out,"-----------------------\n");
    for(NSString *path in inBothFiles)
    {
        NSDictionary *common = jointFileDict[path];
        NSDictionary *a = common[@"ref"];
        NSDictionary *b = common[@"cmp"];
        if((a==NULL) || (b==NULL))
        {
            fprintf(out,"somethings oodd");
        }
        compareEntries(a,b,out);
    }
}

void compareEntries(NSDictionary *ref,NSDictionary *cmp,FILE *out)
{
    BOOL sizeDiffer = NO;
    BOOL hashDiffer = NO;
    BOOL modeDiffer = NO;
    BOOL ownerDiffer = NO;
    BOOL groupDiffer = NO;
    BOOL hasHash2   = NO;
    NSString *path1 = ref[@"path"];
    NSString *path2 = ref[@"path"];

    NSData *hash1 = ref[@"sha512"];
    NSData *hash2 = cmp[@"sha512"];
    NSData *hash2b = cmp[@"sha512b"];
    if(hash2b)
    {
        hasHash2=YES;
    }

    long long mode1 = [ref[@"mode"] longLongValue];
    long long mode2 = [cmp[@"mode"] longLongValue];

    long long owner1 = [ref[@"uid"] longLongValue];
    long long owner2 = [cmp[@"uid"] longLongValue];
    
    long long group1 = [ref[@"gid"] longLongValue];
    long long group2 = [cmp[@"gid"] longLongValue];

    long long size1 = [ref[@"size"] longLongValue];
    long long size2 = [cmp[@"size"] longLongValue];
    BOOL isDir1     = [ref[@"size"] boolValue];
    BOOL isDir2     = [cmp[@"size"] boolValue];

    if((!isDir1) && (!isDir2))
    {
        if(![hash1 isEqualToData:hash2])
        {
            hashDiffer=YES;
        }
    }
    if(size1 != size2)
    {
        sizeDiffer=YES;
    }
    if(mode1 != mode2)
    {
        modeDiffer=YES;
    }
    if(owner1 != owner2)
    {
        ownerDiffer=YES;
    }
    if(group1 != group2)
    {
        groupDiffer=YES;
    }

    if(path1 == NULL)
    {
        fprintf(out,"path1==NULL");
    }
    if(path2 == NULL)
    {
        fprintf(out,"path2==NULL");
    }
    if(sizeDiffer || hashDiffer || modeDiffer || ownerDiffer || groupDiffer || hasHash2 )
    {
        if(isDir1 && isDir2)
        {
            fprintf(out," Dir %s:",path1.UTF8String);
        }
        else if(!isDir1 && isDir2)
        {
            fprintf(out," File2Dir %s:",path1.UTF8String);
        }
        else if(isDir1 && !isDir2)
        {
            fprintf(out," Dir2File %s:",path1.UTF8String);
        }
        else
        {
            fprintf(out," File %s:",path1.UTF8String);
        }
        if(sizeDiffer)
        {
            fprintf(out," size-mismatch");
        }
        if(hashDiffer)
        {
            fprintf(out," hash-mismatch");
        }
        if(modeDiffer)
        {
            fprintf(out," mode-mismatch ");
        }
        if(ownerDiffer)
        {
            fprintf(out," owner-mismatch");
        }
        if(groupDiffer)
        {
            fprintf(out," group-mismatch");
        }
        if(hasHash2)
        {
            fprintf(out," apple CC_SHA512 returns different hash value than sha512.c");
        }
        fprintf(out,"\n");
    }
}
