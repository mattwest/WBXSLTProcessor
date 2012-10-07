/**
 * Simple Objective-C wrapper for using the lovely libxml2 and libxslt libraries.
 *
 * Author: Matt West. matt@westbright.co.uk
 */
@interface WBXSLTProcessor : NSObject

/**
 * Transforms the given input XML with an XSL template at the given path.
 * If successful, the result is stored in the given result pointer.
 * If failed, the error will be stored at the error pointer.
 *
 * @param inputXML the input in XML.
 * @param templateURL the file URL of the XSL template.
 * @param outResult a pointer to the result string.
 * @param outError a pointer to the error if a failure occurs.
 * @return YES if the transform succeeds, or NO if the transfom fails.
 */
- (BOOL)transformInputXML:(NSString *)inputXML templateURL:(NSURL *)templateURL result:(NSString **)outResult error:(NSError **)outError;

/**
 * Transforms some input XML at the given file URL with an XSL template at the given path.
 * If successful, the result is stored in the given result pointer.
 * If failed, the error will be stored at the error pointer.
 *
 * @param inputFileURL the file URL of the input XML.
 * @param templateURL the file URL of the XSL template.
 * @param outResult a pointer to the result string.
 * @param outError a pointer to the error if a failure occurs.
 * @return YES if the transform succeeds, or NO if the transfom fails.
 */
- (BOOL)transformInputURL:(NSURL *)inputFileURL templateURL:(NSURL *)templateURL result:(NSString **)outResult error:(NSError **)outError;

@end
