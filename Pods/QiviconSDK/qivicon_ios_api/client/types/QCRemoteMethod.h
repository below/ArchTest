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

#import <Foundation/Foundation.h>

/**
 * The format to specify a method to be executed. To create batch calls, several
 * elements of this class is used. Make sure, that each element contains an
 * <code>id</code> that is different from each other to identify the associated
 * result from the result set {@link QCResultElement}.
 *
 * @see QCBatchResultElement
 */
@interface QCRemoteMethod : NSObject

@property int ID;
@property (strong) NSString *method;
@property (strong) NSArray *params;

/**
 * Create a method call with parameters.
 *
 * @param ID
 *            the id of the method call. If methods are used in a batch, the
 *            id is returned with the result to identify the appropriate
 *            result. For non-batch calls, id is set to 1.
 * @param method
 *            method to call
 * @param params
 *            array of method parameters
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id) initWithId:(int)ID method:(NSString *)method
   parameterArray:(NSArray *)params
__attribute__((deprecated("Deprecated: Use initWithMethod:parameterArray: instead")));;

/**
 * Create a method call without parameters. The id is set to 1.
 *
 * @param method
 *            method to call
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id) initWithMethod:(NSString *)method;

/**
 * Create a method call with parameters. The id is set to 1.
 *
 * @param method
 *            method to call
 * @param params
 *            array of method parameters
 * @return initialized object
 * @throws Exception
 *             Thrown on argument errors.
 */
- (id) initWithMethod:(NSString *)method parameterArray:(NSArray *)params;

/**
 * Convenience method for creating a method call without parameters. The id is set to 1.
 *
 * @param methodName
 *            method to call
 * @return remote method object
 * @throws Exception
 *             Thrown on argument errors.
 */
+ (QCRemoteMethod *) remoteMethodWithName:(NSString *)methodName;

/**
 * Convenience method for creating a method call with parameters. 
 * The id is set to 1.
 *
 * @param method
 *            name of the method to call
 * @param firstParam
 *            list of method parameters
 * @return remote method object
 * @throws Exception
 *             Thrown on argument errors.
 */
+ (QCRemoteMethod *) remoteMethodWithName:(NSString *)method parameters:(id)firstParam, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Convenience method for creating a method call with parameters.
 *
 * @param identifer
 *            the id of the method call. If methods are used in a batch, the
 *            id is returned with the result to identify the appropriate
 *            result. For non-batch calls, id is set to 1.
 * @param method
 *            method to call
 * @param firstParam
 *            list of method parameters
 * @return remote method object
 * @throws Exception
 *             Thrown on argument errors.
 */
+ (QCRemoteMethod *) remoteMethodWithId:(int)identifer
                                 method:(NSString *)method
                             parameters:(id)firstParam, ... NS_REQUIRES_NIL_TERMINATION
__attribute__((deprecated("Deprecated: Use remoteMethodWithName:parameters: instead")));
@end
