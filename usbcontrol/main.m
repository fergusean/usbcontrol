//
//  main.m
//  usbcontrol
//
//  Created by Sean Ferguson on 12/1/14.
//  Copyright (c) 2014 Signal24. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>

#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

enum CommandAction {
    ACTION_LIST,
    ACTION_RESUME,
    ACTION_SUSPEND
};

int usage(const char *binary) {
    NSString *binaryString = [NSString stringWithCString:binary encoding:NSUTF8StringEncoding];
    NSString *binaryName = [binaryString lastPathComponent];
    NSLog(@"Usage: %@ list|suspend|resume [--vid=0x1234] [--pid=0x5678] [--location=0x123456789]", binaryName);
    NSLog(@" ");
    NSLog(@"Lists, suspends, or resumes USB devices. Suspend & resume require a filter.");
    NSLog(@"VID and PID must be used together. Location can be used with or without VID+PID.");
    return -1;
}

int perform(enum CommandAction action, NSDictionary *filter) {
    CFMutableDictionaryRef matchingDict;
    io_iterator_t iterator;
    io_object_t object;
    SInt32 score;
    IOCFPlugInInterface **pluginInterface;
    IOUSBDeviceInterface245 **usbDeviceInterface;
    UInt32 matchLocationID;
    
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    
    if (filter[@"vid"]) {
        SInt32 vendorID = [(NSNumber *)filter[@"vid"] intValue];
        CFDictionaryAddValue(matchingDict, CFSTR(kUSBVendorID), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &vendorID));
    }
    
    if (filter[@"pid"]) {
        SInt32 productID = [(NSNumber *)filter[@"pid"] intValue];
        CFDictionaryAddValue(matchingDict, CFSTR(kUSBProductID), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &productID));
    }
    
    matchLocationID = filter[@"location"] ? [(NSNumber *)filter[@"location"] unsignedIntValue] : 0;
    
    IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator);
    
    while ((object = IOIteratorNext(iterator))) {
        IOCreatePlugInInterfaceForService(object, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
        (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID245), (LPVOID)&usbDeviceInterface);
        IODestroyPlugInInterface(pluginInterface);
        pluginInterface = NULL;
        
        UInt32 locationID;
        (*usbDeviceInterface)->GetLocationID(usbDeviceInterface, &locationID);
        
        if (matchLocationID != 0 && matchLocationID != locationID) {
            (*usbDeviceInterface)->Release(usbDeviceInterface);
            IOObjectRelease(object);
            continue;
        }
        
        if (action == ACTION_LIST) {
            CFMutableDictionaryRef propsRef;
            IORegistryEntryCreateCFProperties(object, &propsRef, kCFAllocatorDefault, kNilOptions);
            NSDictionary *props = (__bridge NSDictionary *)propsRef;
            NSLog(@"vid=0x%04x pid=0x%04x release=0x%04x location=0x%x vendor=\"%@\" product=\"%@\" serial=\"%@\"", [props[@kUSBVendorID] intValue], [props[@kUSBProductID] intValue], [props[@kUSBDeviceReleaseNumber] intValue], locationID, props[@kUSBVendorString], props[@kUSBProductString], props[@kUSBSerialNumberString]);
        }
        
        else if (action == ACTION_RESUME || action == ACTION_SUSPEND) {
            IOReturn ret = (*usbDeviceInterface)->USBDeviceOpenSeize(usbDeviceInterface);
            if (ret == kIOReturnExclusiveAccess) {
                usleep(100000);
                ret = (*usbDeviceInterface)->USBDeviceOpenSeize(usbDeviceInterface);
            }
            
            if (ret == kIOReturnSuccess) {
                if (action == ACTION_SUSPEND) {
                    ret = (*usbDeviceInterface)->USBDeviceSuspend(usbDeviceInterface, true);
                    if (ret != kIOReturnSuccess) {
                        NSLog(@"Error: Unable to suspend device at location 0x%04x.", locationID);
                    }
                    else {
                        NSLog(@"Success: Suspended device at location 0x%04x.", locationID);
                    }
                }
                
                else {
                    ret = (*usbDeviceInterface)->USBDeviceSuspend(usbDeviceInterface, false);
                    if (ret == kIOReturnSuccess) {
                        ret = (*usbDeviceInterface)->USBDeviceReEnumerate(usbDeviceInterface, 0);
                        if (ret == kIOReturnSuccess) {
                            NSLog(@"Success: Resumed device at location 0x%04x.", locationID);
                        }
                        else {
                            NSLog(@"Error: Unable to re-enumerate device at location 0x%04x.", locationID);
                        }
                    }
                    else {
                        NSLog(@"Error: Unable to resume device at location 0x%04x.", locationID);
                    }
                }
                
                (*usbDeviceInterface)->USBDeviceClose(usbDeviceInterface);
            }
            
            else if (ret == kIOReturnExclusiveAccess) {
                NSLog(@"Error: Device at location 0x%04x is locked for exclusive access.", locationID);
            }
            
            else {
                NSLog(@"Error: Device at location 0x%04x could not be opened.", locationID);
            }
        }
        
        (*usbDeviceInterface)->Release(usbDeviceInterface);
        IOObjectRelease(object);
    }
    
    IOObjectRelease(iterator);
    
    return 0;
}

NSDictionary *getParams(int argc, const char * argv[]) {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (int index = 2; index < argc; index++) {
        NSString *param = [NSString stringWithCString:argv[index] encoding:NSUTF8StringEncoding];
        if ([param length] > 3 && [@"--" isEqualToString:[param substringToIndex:2]]) {
            param = [param substringFromIndex:2];
            NSArray *paramPieces = [param componentsSeparatedByString:@"="];
            if ([paramPieces count] == 2) {
                unsigned int outVal;
                NSScanner *scanner = [NSScanner scannerWithString:paramPieces[1]];
                [scanner scanHexInt:&outVal];
                [params setObject:@(outVal) forKey:paramPieces[0]];
            }
            else {
                [params setObject:@YES forKey:paramPieces[0]];
            }
            continue;
        }
        [params setObject:@YES forKey:param];
    }
    return params;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc == 1)
            return usage(argv[0]);
        
        NSString *action = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSDictionary *params = getParams(argc, argv);
        
        NSSet *providedParamKeys = [NSSet setWithArray:[params allKeys]];
        if (providedParamKeys.count > 0) {
            NSSet *validParamKeys = [NSSet setWithArray:@[ @"vid", @"pid", @"location" ]];
            if (![providedParamKeys isSubsetOfSet:validParamKeys])
                return usage(argv[0]);
        }
        
        if ([action isEqualToString:@"list"])
            return perform(ACTION_LIST, params);
        
        BOOL isResumeCmd = [action isEqualToString:@"resume"];
        BOOL isSuspendCmd = !isResumeCmd && [action isEqualToString:@"suspend"];
        if (isResumeCmd || isSuspendCmd) {
            if (providedParamKeys.count == 0)
                return usage(argv[0]);
            return perform(isResumeCmd ? ACTION_RESUME : ACTION_SUSPEND, params);
        }
        
        return usage(argv[0]);
    }
}