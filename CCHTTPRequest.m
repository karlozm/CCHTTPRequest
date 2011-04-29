//
//  UVAPIRequest.m
//  PostForm
//
//  Created by karloz on 4/13/11.
//  Copyright 2011 cod3monkey. All rights reserved.
//

#import "CCHTTPRequest.h"

@implementation CCHTTPRequest

@synthesize delegate;

- (id)init {
	self = [super init];
	if (self) {
		responseDataDict = CFDictionaryCreateMutable(
												 kCFAllocatorDefault,
												 0,
												 &kCFTypeDictionaryKeyCallBacks,
												 &kCFTypeDictionaryValueCallBacks);
	}
	
	return self;
}

- (void)dealloc {
	delegate = nil;
	[originalURL release], originalURL = nil;
	CFRelease(responseDataDict);
	
	[super dealloc];
}

#pragma mark - Public Methods

- (void)performGetRequestWithURL:(NSURL *)url parameters:(id)parameters {
	// i'm gonna save a copy of the original requested url to pass it back in the delegate, for identification purposes
	originalURL = [url copy];
	
	NSURL *urlWithParameters = nil;
	
	// build params
	if ([parameters isKindOfClass:[NSString class]]) {
		urlWithParameters = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",
												  [url absoluteString],
												  parameters]];
	}
	
	if ([parameters isKindOfClass:[NSDictionary class]]) {
		NSMutableArray *urlParameters = [NSMutableArray array];
		
		for (NSString *key in parameters) {
			[urlParameters addObject:[NSString stringWithFormat:@"%@=%@", key, [parameters valueForKey:key]]];
		}
		
		urlWithParameters = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",
												  [url absoluteString],
												  [urlParameters componentsJoinedByString:@"&"]]];
	}
	
	// build new URL with given params
	urlRequest = [[NSMutableURLRequest alloc] initWithURL:urlWithParameters];
	[urlRequest setHTTPMethod:@"GET"];
	
	urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	
	// add to dictionary both data & request i'll be passing later on to the delegate
	CFDictionaryAddValue(responseDataDict,
						 urlConnection,
						 [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableData data], @"receivedData", urlRequest, @"urlRequest", nil]);
	
	[urlConnection start];
	[urlConnection release], urlConnection = nil;
}

- (void)performPostRequestWithURL:(NSURL *)url parameters:(id)parameters {
	// i'm gonna save a copy of the original requested url to pass it back in the delegate, for identification purposes
	originalURL = [url copy];

	NSString *postBody = nil;
	
	// build post body
	if ([parameters isKindOfClass:[NSString class]]) {
		postBody = parameters;
	}
	
	if ([parameters isKindOfClass:[NSDictionary class]]) {
		NSMutableArray *urlParameters = [NSMutableArray array];
		
		for (NSString *key in parameters) {
			[urlParameters addObject:[NSString stringWithFormat:@"%@=%@", key, [parameters valueForKey:key]]];
		}
		
		postBody = [urlParameters componentsJoinedByString:@"&"];
	}
	
	// use given url & set post body
	urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[urlRequest setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	
	// add to dictionary both data & request i'll be passing later on to the delegate
	CFDictionaryAddValue(responseDataDict,
						 urlConnection,
						 [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableData data], @"receivedData", urlRequest, @"urlRequest", nil]);

	
	[urlConnection start];
	[urlConnection release], urlConnection = nil;
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSMutableDictionary *connectionInfo = (NSMutableDictionary *)CFDictionaryGetValue(responseDataDict, connection);
	
	[[connectionInfo objectForKey:@"receivedData"] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if ([delegate respondsToSelector:@selector(request:didFinishWithResponseString:)]) {
		NSMutableDictionary *responseDictionary = (NSMutableDictionary *)CFDictionaryGetValue(responseDataDict, connection);
		
		[delegate performSelector:@selector(request:didFinishWithResponseString:)
					   withObject:(NSURLRequest *)[responseDictionary valueForKey:@"urlRequest"]
					   withObject:[[NSString alloc] initWithData:(NSData *)[responseDictionary valueForKey:@"receivedData"] encoding:NSUTF8StringEncoding]];
	}
	
	// no further communications for this connection will take place, so remove the associated dictionary entry
	CFDictionaryRemoveValue(responseDataDict, connection);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[delegate performSelector:@selector(request:didFailWithError:)
					   withObject:urlRequest
					   withObject:error];
	}
}

@end
