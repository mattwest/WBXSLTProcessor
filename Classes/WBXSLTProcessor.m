#import "WBXSLTProcessor.h"
#import <libxml/tree.h>
#import <libxslt/xsltutils.h>
#import <libxslt/transform.h>


@interface WBXSLTProcessor ()
- (BOOL)transformInputDoc:(xmlDocPtr)inputDoc templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error;
- (xmlDocPtr)parseFileURL:(NSURL *)xmlFileURL;
@end

@implementation WBXSLTProcessor

#pragma mark API

- (BOOL)transformInputXML:(NSString *)inputXML templateURL:(NSURL *)templateURL result:(NSString **)outResult error:(NSError **)outError {
    xmlDocPtr inputDoc = xmlParseDoc((const xmlChar *)[inputXML UTF8String]);
    if (!inputDoc) {
        if (outError) { // Report error if we were given an NSError
            xmlErrorPtr xmlErr = xmlGetLastError();
            NSString *msg = [NSString stringWithCString:xmlErr->message encoding:NSUTF8StringEncoding];
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot parse the XML input string", NSLocalizedDescriptionKey, msg, @"xmlErrorMessage", inputXML, @"InputXMLString", nil];
            *outError = [NSError errorWithDomain:@"WBXSLTProcessorErrorDomain" code:1 userInfo:errorInfo];
        }
        return NO;
    }
    BOOL success = [self transformInputDoc:inputDoc templateURL:templateURL result:outResult error:outError];
    xmlFreeDoc(inputDoc);
    return success;
}

- (BOOL)transformInputURL:(NSURL *)inputFileURL templateURL:(NSURL *)templateURL result:(NSString **)outResult error:(NSError **)outError {
    xmlDocPtr inputDoc = [self parseFileURL:inputFileURL];
    if (!inputDoc) {
        if (outError) {
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot parse the XML input file", NSLocalizedDescriptionKey, inputFileURL, NSFilePathErrorKey, nil];
            *outError = [NSError errorWithDomain:@"WBXSLTProcessorErrorDomain" code:1 userInfo:errorInfo];
        }
        return NO;
    }
    BOOL success = [self transformInputDoc:inputDoc templateURL:templateURL result:outResult error:outError];
    xmlFreeDoc(inputDoc);
    return success;
}

- (BOOL)transformInputDoc:(xmlDocPtr)inputDoc templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error {
    NSAssert(!(*error), @"Contents of error should be nil when we start: ", error);

    // Housekeeping for using libxml
    xmlSubstituteEntitiesDefault(1);
    xmlLoadExtDtdDefaultValue = 1;

    // Parse the XSL stylesheet file 
    xmlDocPtr templateDoc = [self parseFileURL:templateURL];
    if (!templateDoc) {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot parse the XSL stylesheet file", NSLocalizedDescriptionKey, templateURL, NSFilePathErrorKey, nil];
        *error = [NSError errorWithDomain:@"WBXSLTProcessorErrorDomain" code:2 userInfo:errorInfo];
        return NO;
    }
    xsltStylesheetPtr stylesheet = xsltParseStylesheetDoc(templateDoc);

    // Apply the stylesheet
    xmlDocPtr resultDoc = xsltApplyStylesheet(stylesheet, inputDoc, NULL);
    if (!resultDoc) {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Cannot transform the XML and XSL", NSFilePathErrorKey, templateURL, NSFilePathErrorKey, nil];
        *error = [NSError errorWithDomain:@"WBXSLTProcessorErrorDomain" code:3 userInfo:errorInfo];
        return NO;
    }
    int theLoadedDocSize = 0;
    xmlChar *theLoadedDocChars = nil;
    xsltSaveResultToString(&theLoadedDocChars, &theLoadedDocSize, resultDoc, stylesheet);

    // Free up the memory
    xsltFreeStylesheet(stylesheet);
    xmlFreeDoc(resultDoc);
    xsltCleanupGlobals();
    xmlCleanupParser();
    
    *result = [NSString stringWithCString:(const char *)theLoadedDocChars encoding:NSUTF8StringEncoding];
    free(theLoadedDocChars), theLoadedDocChars = nil;

    return YES;
}


#pragma mark -
#pragma mark Private

- (xmlDocPtr)parseFileURL:(NSURL *)xmlFileURL {
    const char * filePath = [[xmlFileURL path] UTF8String];
    return xmlParseFile(filePath);
}

@end
