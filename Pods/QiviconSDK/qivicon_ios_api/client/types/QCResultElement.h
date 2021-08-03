/*
 * (C) Copyright 2011-2013 by Deutsche Telekom AG.
 *
 * This software is property of Deutsche Telekom AG and has
 * been developed for QIVICON platform.
 *
 * See also http://www.qivicon.com
 *
 * DO NOT DISTRIBUTE OR COPY THIS SOFTWARE OR PARTS OF THE SOFTWARE
 * TO UNAUTHORIZED PERSONS OUTSIDE THE DEUTSCHE TELEKOM ORGANIZATION.
 *
 * VIOLATIONS WILL BE PURSUED!
 */

//
//  QCBatchResultElement.h
//  qivicon_ios_api
//
//  Created by Alexander v. Below on 25.03.13.
//

#import <Foundation/Foundation.h>

/**
 * A JSON-RPC batch result element. All JSON-RPC batch call return an array of
 * these elements with the following result structure.
 * <p>
 *
 * <pre>
 * {"jsonrpc":"2.0","id":1,"result":"xxxxxxx"}
 * </pre>
 *
 * If an error occurred, the structure contains an error element instead of a
 * result element:
 * <p>
 *
 * <pre>
 * {"jsonrpc":"2.0","id":1,"error":{"code":xxxxxx,"message":"xxxxxx"}}
 * </pre>
 *
 * The contained id identifies the result element of the method called with the
 * same id. Result elements of batch calls can be returned in any order,
 * therefore the id element must be used to match the result element with the
 * methods called. A typical batch result looks like this:
 * <p>
 *
 * <pre>
 * [
 *      {"jsonrpc":"2.0","id":1,"result":"xxxxxxx"},
 *      {"jsonrpc":"2.0","id":4,"result":"xxxxxxx"},
 *      {"jsonrpc":"2.0","id":2,"error":{"code":xxxxxx,"message":"xxxxxx"}},
 *      {"jsonrpc":"2.0","id":3,"result":"xxxxxxx"}
 * ]
 * </pre>
 *
 * The above example returns the result of a batch call with 4 methods. The call
 * of the second method (id=2) failed.
 */
@interface QCResultElement : NSObject

/**
 * Creates an empty <code>BatchResultElement</code>.
 */
- (id)init;

/**
 * Creates a <code>BatchResultElement</code>.
 *
 * @param Id
 *      The Id of the result element
 * @param result
 *            object to be set as result
 */
- (id) initWithId:(int)Id result:(id)result;

+ (QCResultElement *) batchResultElementWithJSONDictionary:(NSDictionary *)jsonElement;

/**
 * Get the content of the <code>id</code> element.
 *
 * @return Id
 */
@property (readonly) int Id;

/**
 * Get the error object or <code>null</code>, if no error occurred.
 *
 * @return error code
 */
@property (readonly) NSError *error;

/**
 * Get the content of the <code>result</code> element.
 *
 * @return result
 */
@property (readonly) id result;

/**
 * Checks, whether an error occurred.
 *
 * @return <code>true</code> if an error occurred
 */
@property (readonly) BOOL hasError;


@end
