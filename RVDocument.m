/* Copyright (c) 2009, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "RVDocument.h"

// Models
#import "RVContainer.h"

// Controllers
#import "RVWindowController.h"

// Other Sources
#import "RVFoundationAdditions.h"

NSString *const RVDocumentContainersDidChangeNotification = @"RVDocumentContainersDidChange";

@implementation RVDocument

#pragma mark -RVDocument

- (NSArray *)containers
{
	if(!_containers) {
		NSMutableArray *const containers = [NSMutableArray array];
		for(NSURL *const componentURL in [[self fileURL] RV_componentURLs]) {
			if([componentURL isEqual:[NSURL fileURLWithPath:@"/Volumes/"]]) break;
			RVContainer *const container = [[[RVDirectory alloc] initWithURL:componentURL] autorelease];
			[containers addObject:container];
			[container PG_addObserver:self selector:@selector(containerContentsDidChange:) name:RVContainerContentsDidChangeNotification];
		}
		[containers addObject:[[[RVRootContainer alloc] init] autorelease]];
		_containers = [containers copy];
	}
	return [[_containers copy] autorelease];
}

#pragma mark -

- (BOOL)canOpenURL:(NSURL *)URL
{
	NSParameterAssert(URL);
	return [URL RV_isFolder];
}

#pragma mark -

- (void)containerContentsDidChange:(NSNotification *)aNotif
{
	[self PG_postNotificationName:RVDocumentContainersDidChangeNotification];
}

#pragma mark -NSDocument

- (void)setFileURL:(NSURL *)absoluteURL
{
	[super setFileURL:absoluteURL];
	for(RVContainer *const container in _containers) [container PG_removeObserver:self name:RVContainerContentsDidChangeNotification];
	[_containers release];
	_containers = nil;
	[self PG_postNotificationName:RVDocumentContainersDidChangeNotification];
}
- (void)makeWindowControllers
{
	[self addWindowController:[[[RVWindowController alloc] init] autorelease]];
}
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	*outError = nil;
	return YES;
}
- (NSString *)displayName
{
	return [[[[self containers] objectEnumerator] nextObject] name];
}

#pragma mark -NSObject

- (void)dealloc
{
	[self PG_removeObserver];
	[_containers release];
	[super dealloc];
}

@end
