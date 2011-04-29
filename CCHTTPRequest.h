//
//  UVAPIRequest.h
//  PostForm
//
//  Created by karloz on 4/13/11.
//  Copyright 2011 cod3monkey. All rights reserved.
//

/**
 *	History
 *
 *	16/apr/11
 *	0.0.2	+ Multiple request handling
 *
 *	15/apr/11
 *	0.0.1	Initial Release
 *
 */


#import <Foundation/Foundation.h>

@protocol CCHTTPRequestDelegate <NSObject>

@optional

- (void)request:(NSURLRequest *)request didFinishWithResponseString:(NSString *)response;
- (void)request:(NSURLRequest *)request didFailWithError:(NSError *)error;

@end


@interface CCHTTPRequest : NSObject {
@private
	NSURL *originalURL;
	NSMutableURLRequest *urlRequest;
	NSURLConnection *urlConnection;
	CFMutableDictionaryRef responseDataDict;
	
	id <CCHTTPRequestDelegate> delegate;
}

- (void)performGetRequestWithURL:(NSURL *)url parameters:(id)parameters;
- (void)performPostRequestWithURL:(NSURL *)url parameters:(id)parameters;

@property (nonatomic, assign) id <CCHTTPRequestDelegate> delegate;

@end
