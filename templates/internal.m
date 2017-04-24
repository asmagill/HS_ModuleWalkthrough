
// Note that any line in a lua file which begins with three slashes is considered part of
// the documentation and should follow the general format shown below


@import Cocoa ;
@import LuaSkin ;

static const char * const USERDATA_TAG = "hs._asm.module" ;

// Lua allows storing data in the LUA_REGISTRY, which can be thought of as a "global variable space for compiled code".
// To keep some separation of data, LuaSkin creates a table for each module within this registry and this is where we
// will store our reference to it in the initialization function defined at the end of this file.
static int refTable = LUA_NOREF;

// Used for Objective-C classes like NSObject, NSWindow, etc. or objects you define with @interface/@implmentation
// #define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))

// Used for C type structures passed by reference
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))

// Used for Core Foundation objects (sometimes referred to as CF Objects)
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

// Many editors will use #pragma mark declarations as organizational separators in a function list, if the editor
// provides on.  In general I organize my code into these categories when possible:

#pragma mark - Support Functions and Classes

// This is where I will generally define helper functions and @interface/@implementation blocks for my own
// objects or typedefs for my own structures

// I personally favor storing everything I can in Objective-C objects because LuaSkin can add conversion support
// for these to other modules without them requiring any additional code.

// <moduleType> is used here (and later on in the code) as a place holder... it allows a global find/replace once
// I determine what the object name this module handles is named.  When not representing a specific existing
// Objective-C type, I usually prefix them with HS to make clear that it's a new object or subclass of one.

// @interface <moduleType> : NSObject
//
// ...
//
// @end
//
// @implementation <moduleType>
//
// ...
//
// @end

#pragma mark - Module Functions

// This is where module functions will go.  By convention, documentation for a function precedes the actual
// function itself.

/// hs._asm.new(arg1, ...) -> moduleObject
/// Constructor
/// One line description. The "Constructor" label denotes a function which creates a userdata object for the module.
///
/// Parameters:
///  * arg1 - description (use "* None" if no arguments are expected)
///  * ...
///
/// Returns:
///  * description of return value (use * None if no value is returned)
///
/// Notes:
///  * any notes or examples

// static int module_new(lua_State *L) {
//
//     return 1 ;
// }

/// hs._asm.function(arg1, ...) -> moduleObject
/// Function
/// One line description.
///
/// Parameters:
///  * arg1 - description (use "* None" if no arguments are expected)
///  * ...
///
/// Returns:
///  * description of return value (use * None if no value is returned)
///
/// Notes:
///  * any notes or examples

// static int module_function(lua_State *L) {
//
//     return 1 ;
// }

#pragma mark - Module Methods

// This is where module methods will go.  A module method differs from a function in that it requires a userdata
// object to act on.  Internally, however, they are defined the same, but the first argument will always be the
// userdata itself.

/// hs._asm.method(arg1, ...) -> moduleObject
/// Method
/// One line description.
///
/// Parameters:
///  * arg1 - description (use "* None" if no arguments are expected)
///  * ...
///
/// Returns:
///  * description of return value (use * None if no value is returned)
///
/// Notes:
///  * any notes or examples

// static int module_function(lua_State *L) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,  ..., LS_TBREAK] ;
//
//     <moduleType> *object = get_objectFromUserdata(<moduleType>, L, 1, USERDATA_TAG) ;
// // or, if you register the appropriate support functions defined below
//     <moduleType> *object = [skin toNSObjectAtIndex:idx]  ;
//
//     return 1 ;
// }

#pragma mark - Module Constants

// This is where functions which push a table of constants (array or key-value tables) are defined.  Usually these
// will be invoked in the initialization function below so that they are available in a table when the module is
// loaded.  I generally use functions like this rather than hand coding them in init.lua on the off chance that
// Apple changes the actual value of something in a future update.

// static int push_moduleConstants(lua_State *L) {
//     lua_newtable(L) ;
//     lua_pushXXX(L, XXX) ; lua_setfield(L, -2, "labelForXXX") ;
//     ...
//
//     return 1 ;
// }

#pragma mark - Lua<->NSObject Conversion Functions

// The following are support functions which are registered with LuaSkin to provide automatic conversions of
// any userdata or object types handled by this module so that other modules can use them as well.  This is
// only useful for Objective-C objects (e.g. NSObject, etc.) rather then structures or CF Objects.
//
// The reasoning for this can best be observed with NSColor (provided by hs.drawing.color) or NSImage
// (provided by hs.image).  Other modules can accept the userdata representing these objects without
// having to code in specific support for them by using LuaSkin, and if somebody finds a need to extend
// support for one of the objects (and this has happened multiple times with NSColor), then once
// hs.drawing.color is updated, *all* modules which can use a color as an argument/return value benefit from
// the update without requiring any code changes.

// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

// This function takes a newly created object and creates the userdata wrapper which will represent it in
// Lua.  it's what allows [skin pushNSObject:myObject] to push an Objective-C type onto the Lua stack as
// the appropriate userdata type.

// static int push<moduleType>(lua_State *L, id obj) {
//     <moduleType> *value = obj;
//     void** valuePtr = lua_newuserdata(L, sizeof(<moduleType> *));
//     *valuePtr = (__bridge_retained void *)value;
//     luaL_getmetatable(L, USERDATA_TAG);
//     lua_setmetatable(L, -2);
//     return 1;
// }

// This function takes a userdata on the stack and converts it into an Objective-C type for our object.
// It's what allows [skin toNSObjectAtIndex:idx] to convert a userdata on the Lua stack into our object

// id to<moduleType>FromLua(lua_State *L, int idx) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     <moduleType> *value ;
//     if (luaL_testudata(L, idx, USERDATA_TAG)) {
//         value = get_objectFromUserdata(__bridge <moduleType>, L, idx, USERDATA_TAG) ;
//     } else {
//         [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
//                                                    lua_typename(L, lua_type(L, idx))]] ;
//     }
//     return value ;
// }

#pragma mark - Hammerspoon/Lua Infrastructure

// These functions and data structures provide some basic housekeeping that Lua requires (or at least makes
// things friendlier/easier)

// This method returns the string representation you get from `tostring(object)` of the userdata object.  This
// method is optional but recommended since the string representation will just be "userdata" if you don't
// provide it and this can make debugging more difficult if you don't know exactly what object type you're
// working with.

// static int userdata_tostring(lua_State* L) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     <moduleType> *obj = [skin luaObjectAtIndex:1 toClass:"<moduleType>"] ;
//     NSString *title = ... ;
//     [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
//     return 1 ;
// }

// This method is used to determine equality between two userdata objects (i.e. do they represent the same thing?)
// This is strictly optional, but generally pretty easy to add.

// static int userdata_eq(lua_State* L) {
// // can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// // so use luaL_testudata before the macro causes a lua error
//     if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
//         LuaSkin *skin = [LuaSkin shared] ;
//         <moduleType> *obj1 = [skin luaObjectAtIndex:1 toClass:"<moduleType>"] ;
//         <moduleType> *obj2 = [skin luaObjectAtIndex:2 toClass:"<moduleType>"] ;
//         lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
//     } else {
//         lua_pushboolean(L, NO) ;
//     }
//     return 1 ;
// }

// This method is used when the userdata object is collected during garbage collection.  This method is generally
// required and is where any tear down or cleanup should occur when the object goes out of scope.  Any objects which
// you have stored in the LUA_REGISTRY (for example callback functions) should also be cleared here; otherwise they
// will not be collected.

// static int userdata_gc(lua_State* L) {
//     LuaSkin *skin = [LuaSkin shared] ;
//     <moduleType> *obj = get_objectFromUserdata(__bridge_transfer <moduleType>, L, 1, USERDATA_TAG) ;
//     if (obj) {
//           obj.callbackRef = [skin luaUnRef:refTable ref:obj.callbackRef] ;
//     }
//     obj = nil ;
//     // Remove the Metatable so future use of the variable in Lua won't think its valid
//     lua_pushnil(L) ;
//     lua_setmetatable(L, 1) ;
//     return 0 ;
// }

// This is a garbage collection function for the entire module itself; generally it will only be invoked when
// Hammerspoon is being restarted (reloaded) or exiting.  Most modules don't require this.

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// This array lists the methods which are attached to userdata objects.  The string at the beginning of
// line corresponds to the method name as it appears in lua.

// // Metatable for userdata objects
// static const luaL_Reg userdata_metaLib[] = {
//     {"method",     module_method},
//
//     {"__tostring", userdata_tostring},
//     {"__eq",       userdata_eq},
//     {"__gc",       userdata_gc},
//     {NULL,         NULL}
// };

// This array lists the functions and constructors this module provides when loaded.

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
//     {"constructor", module_constructor},
//     {"function",    module_function},

    {NULL, NULL}
};

// This is the metatable for the module itself.  If you use meta_gc above, you will need to uncomment this

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// This is the initialization function for the module. This will be executed when the module is *first*
// loaded by "require" in lua.  Until Hammerspoon is restarted or exited and relaunched, all subsequent
// requests to load the module will just cause the table which contains the module's functions to be
// returned without re-executing this function.  The name *must* match luaopen_<USERDATA_TAG>_internal
// where the periods in USERDATA_TAG are replaced with underscores (e.g. `hs._asm.disks` becomes
// luaopen_hs__asm_disks_internal)

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_module_internal(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared] ;

// User only one of the following:

// Use this if your module doesn't have a module specific userdata object that it returns.
   refTable = [skin registerLibrary:moduleLib metaFunctions:nil] ; // or module_metaLib

// Use this some of your functions return or act on a specific object unique to this module
//     refTable = [skin registerLibraryWithObject:USERDATA_TAG
//                                      functions:moduleLib
//                                  metaFunctions:nil    // or module_metaLib
//                                objectFunctions:userdata_metaLib];

// If you defined functions to allow LuaSkin to automatically convert your Objective-C objects to/from
// userdata, use one or more of the following:

// The following adds support for [skin pushNSObject:object]
//     [skin registerPushNSHelper:push<moduleType>         forClass:"<moduleType>"];


// The following add support for [skin toNSObjectAt:idx] or [skin luaObjectAtIndex:idx toClass:className]
//
// this version allows conversion even if userdata is in a table (NSArray or NSDictionary)
//     [skin registerLuaObjectHelper:to<moduleType>FromLua forClass:"<moduleType>"
//                                              withUserdataMapping:USERDATA_TAG];

// this version will only work for directly index references
//     [skin registerLuaObjectHelper:to<moduleType>FromLua forClass:"<moduleType>"];

    return 1;
}
