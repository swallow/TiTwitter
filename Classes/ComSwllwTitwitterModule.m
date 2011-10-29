/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "ComSwllwTitwitterModule.h"
#import "TiBase.h"
#import "TiBlob.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "KrollCallback.h"
#import "SBJSON.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@implementation ComSwllwTitwitterModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
    return @"a72495a8-362c-40d6-878d-c90cd0255f9c";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
    return @"com.swllw.titwitter";
}

-(NSString*)convertParams:(NSMutableDictionary*)params
{
    NSString* httpMethod = nil;
    for (NSString* key in [params allKeys]) {
        id param = [params objectForKey:key];
        if ([param isKindOfClass:[TiFile class]]) {
            TiFile* file = (TiFile*)param;
            if ([file size] > 0) {
                param = [file toBlob:nil];
            } else {
                param = [[[TiBlob alloc] initWithData:[NSData data] mimetype:@"text/plain"] autorelease];
            }
        }

        if ([param isKindOfClass:[TiBlob class]]) {
            httpMethod = @"POST";
            TiBlob* blob = (TiBlob*)param;
            if ([[blob mimeType] hasPrefix:@"image/"]) {
                UIImage* image = [blob image];
                [params setObject:image forKey:key];
            } else {
                NSData* data = [blob data];
                [params setObject:data forKey:key];
            }
        } else if (![param isKindOfClass:[NSString class]]) {
            NSString* json_value = [SBJSON stringify:param];
            if (json_value == nil) {
                [params setObject:@"" forKey:key];
                continue;
            }
            [params setObject:json_value forKey:key];
        }
    }
    return httpMethod;
}

#pragma mark Lifecycle

-(void)startup
{
    // this method is called when the module is first loaded
    // you *must* call the superclass
    [super startup];

    NSLog(@"[INFO] %@ loaded", self);
}

-(void)shutdown:(id)sender
{
    // this method is called when the module is being unloaded
    // typically this is during shutdown. make sure you don't do too
    // much processing here or the app will be quit forceably

    // you *must* call the superclass
    [super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
    // release any resources that have been retained by the module
    [super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
    // optionally release any resources that can be dynamically
    // reloaded once memory is available - such as caches
    [super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString*)type count:(int)count
{
    if (count == 1 && [type isEqualToString:@"my_event"]) {
        // the first (of potentially many) listener is being added
        // for event named 'my_event'
    }
}

-(void)_listenerRemoved:(NSString*)type count:(int)count
{
    if (count == 0 && [type isEqualToString:@"my_event"]) {
        // the last listener called for event named 'my_event' has
        // been removed, we can optionally clean up any resources
        // since no body is listening at this point for that event
    }
}

#pragma Public APIs

-(id)canTweetStatus
{
    return NUMBOOL([TWTweetComposeViewController canSendTweet]);
}

-(void)send:(id)args
{
    ENSURE_ARG_COUNT(args, 4);

    NSString* path = [NSString stringWithFormat:@"http://api.twitter.com/1/%@.json", [args objectAtIndex:0]];

    NSString* httpMethod = [args objectAtIndex:1];
    TWRequestMethod method = TWRequestMethodGET;
    if ([[httpMethod uppercaseString] isEqualToString:@"GET"]) {
        method = TWRequestMethodGET;
    } else if ([[httpMethod uppercaseString] isEqualToString:@"POST"]) {
        method = TWRequestMethodPOST;
    } else if ([[httpMethod uppercaseString] isEqualToString:@"DELETE"]) {
        method = TWRequestMethodDELETE;
    }

    NSMutableDictionary* params = [args objectAtIndex:2];
    httpMethod = [self convertParams:params];
    if ([[httpMethod uppercaseString] isEqualToString:@"POST"]) {
        method = TWRequestMethodPOST;
    }

    KrollCallback* callback = [args objectAtIndex:3];

    NSMutableDictionary* event = [NSMutableDictionary dictionary];
    ACAccountStore* accountStore = [[ACAccountStore alloc] init];
    ACAccountType* accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError* error)
                  {
                      if (granted) {
                          NSArray* accountsArray = [accountStore accountsWithAccountType:accountType];
                          if ([accountsArray count] > 0) {
                              ACAccount* twitterAccount = [accountsArray objectAtIndex:0];

                              TWRequest* postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:path] parameters:params requestMethod:method];
                              [postRequest setAccount:twitterAccount];
                              [postRequest performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error)
                                           {
                                               [event setObject:NUMINT([urlResponse statusCode]) forKey:@"status"];
                                               if (!error && [urlResponse statusCode] == 200) {
                                                   [event setObject:NUMBOOL(YES) forKey:@"success"];
                                                   [event setObject:NUMBOOL(NO) forKey:@"error"];
                                                   NSError* error = nil;
                                                   NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                                                   [event setObject:dict forKey:@"data"];
                                               } else {
                                                   [event setObject:NUMBOOL(NO) forKey:@"success"];
                                                   [event setObject:NUMBOOL(YES) forKey:@"error"];
                                               }
                                               [self _fireEventToListener:@"twitter" withObject:event listener:callback thisObject:nil];
                                           }];
                          }
                      }
                  }];
}

@end
