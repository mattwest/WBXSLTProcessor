#import "WBXSLTProcessor.h"
#import <libxml/tree.h>
#import <libxslt/xsltutils.h>
#import <libxslt/transform.h>


@interface WBXSLTProcessor ()
- (BOOL)transformInputDoc:(xmlDocPtr)inputDoc templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error;
- (xmlDocPtr)parseFileURL:(NSURL *)xmlFileURL;
- (NSError *)lastErrorWithTitle:(NSString *)title;
@end

@implementation WBXSLTProcessor

#pragma mark API

- (BOOL)transformInputXML:(NSString *)inputXML templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error
{
    xmlDocPtr inputDoc = xmlParseDoc((const xmlChar *)[inputXML UTF8String]);
    if (!inputDoc)
    {
        if (error)
        {
            *error = [self lastErrorWithTitle:@"Cannot parse the XML input string"];
        }
        return NO;
    }
    BOOL success = [self transformInputDoc:inputDoc templateURL:templateURL result:result error:error];
    xmlFreeDoc(inputDoc);
    return success;
}

- (BOOL)transformInputURL:(NSURL *)inputFileURL templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error
{
    xmlDocPtr inputDoc = [self parseFileURL:inputFileURL];
    if (!inputDoc)
    {
        if (error)
        {
            *error = [self lastErrorWithTitle:@"Cannot parse the XML input file"];
        }
        return NO;
    }
    BOOL success = [self transformInputDoc:inputDoc templateURL:templateURL result:result error:error];
    xmlFreeDoc(inputDoc);
    return success;
}

- (BOOL)transformInputDoc:(xmlDocPtr)inputDoc templateURL:(NSURL *)templateURL result:(NSString **)result error:(NSError **)error
{
    NSAssert(!(*error), @"Contents of error should be nil when we start: ", error);

    // Housekeeping for using libxml
    xmlSubstituteEntitiesDefault(1); // Tell libxml2 parser to substitute entities as it parses
    xmlLoadExtDtdDefaultValue = 1; // tells libxml to load external entity subsets

    // Parse the XSL stylesheet file 
    xmlDocPtr templateDoc = [self parseFileURL:templateURL];
    if (!templateDoc)
    {
        if (error)
        {
            *error = [self lastErrorWithTitle:@"Cannot parse the XSL stylesheet file"];
        }
        return NO;
    }
    xsltStylesheetPtr stylesheet = xsltParseStylesheetDoc(templateDoc);

    // Apply the stylesheet
    xmlDocPtr resultDoc = xsltApplyStylesheet(stylesheet, inputDoc, NULL);
    if (!resultDoc)
    {
        if (error)
        {
            *error = [self lastErrorWithTitle:@"Cannot transform the XML and XSL"];
        }
        return NO;
    }
    int theLoadedDocSize = 0;
    xmlChar *theLoadedDocChars = nil;
    xsltSaveResultToString(&theLoadedDocChars, &theLoadedDocSize, resultDoc, stylesheet);

    // Free up the memory
    xsltFreeStylesheet(stylesheet);
    xmlFreeDoc(resultDoc);
//    xmlFreeDoc(inputDoc);
    xsltCleanupGlobals();
    xmlCleanupParser();
    
    *result = [NSString stringWithCString:(const char *)theLoadedDocChars encoding:NSUTF8StringEncoding];
    free(theLoadedDocChars), theLoadedDocChars = nil;

    return YES;
}


#pragma mark -
#pragma mark Private

- (xmlDocPtr)parseFileURL:(NSURL *)xmlFileURL
{
    const char * filePath = [[xmlFileURL path] UTF8String];
    xmlDocPtr result = xmlParseFile(filePath);

    return result;
}

- (NSError *)lastErrorWithTitle:(NSString *)title
{
    xmlErrorPtr theError = xmlGetLastError();
    NSString *message = [NSString stringWithFormat:@"%@: %s", title, theError->message];
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message",
                               [NSString stringWithFormat:@"%d", theError->domain], @"xmlErrorDomain",
                               [NSString stringWithFormat:@"%d", theError->code], @"xmlErrorCode",
                               [NSString stringWithFormat:@"%d", theError->level], @"xmlErrorLevel",
                               nil]; // TODO expand userInfo with more stuff in theError struct.
    NSError *result = [NSError errorWithDomain:@"WBXSLTProcessorErrorDomain" code:theError->code userInfo:errorInfo];
    return result;
}

@end
