Hammerspoon Module Walkthrough
------------------------------

The purpose of this walkthrough is to describe the process I use for developing Lua modules for use with [Hammerspoon](http://www.hammerspoon.org).  It is by no means the only way, and does not cover all possible variants, but it should give a basic understanding of my process.

#### Background
Modules which extend the Lua functionality available can be entirely written in Lua or a hybrid of Lua and a compiled component. For the purposes of this walk through, I focus on the hybrid module with Objective-C as the compiled component.  Lua has a well developed [C API](http://www.lua.org/manual/5.3/manual.html#4) which will be used in this example.

For this example, we will be coding this as an external module (sometimes referred to as a 3rd-Party module in the [Hammerspoon group](https://groups.google.com/forum/#!forum/hammerspoon) or [Hammerspoon issues tracker](https://github.com/Hammerspoon/hammerspoon/issues)), separate from the Hammerspoon code available at https://github.com/Hammerspoon/hammerspoon.  This is done for two reasons:  it allows for faster turn around during testing, and it is, in my oppinion, easier.  If you believe your module should be considered for inclusion within the Hammerspoon core, it is still easiest to code it as a stand alone entity first so people can test it out and discuss how it might best be included.

For the purposes of this example, we want to develop a module which will allow us to register a callback function that will be invoked everytime a disk is mounted or unmounted from the system.  To do this, we will be using the shared NSWorkspace instance.

#### First things first

For our module, we want to call it `disks`.  Hammerspoon has a tradition of naming its modules in the style of `hs.modulename`, but since we're still testing this, this example will go with `hs._asm.disks`.  The `_asm` can be anything you choose - it's purely orginizational, but by prefacing the module name with `hs._asm` it's clear that this is not a builtin core module.

Note that this naming convention just defines the path where Hammerspoon/Lua can find the necessary support files.  As we'll see towards the end, when using a module, you can give it any name that makes sense in your code at the time you use it.

A hybrid module is usually, though not always, composed of 3 files:
* init.lua - this file contains any logic which can best be handled in Lua, and also includes a reference to the compiled code so that it is loaded and available.
* internal.m - this contains the source code for the compiled portion of the module.
* Makefile - this contains the necessary instructions for building and installing the module in a place where Hammerspoon can find it.

So, make a folder with the name you want to call your module (in this cases `disks`) and lets get started.

##### init.lua
The complexity of this file will vary.  As a general rule of thumb, it is encouraged that anything which *can* be handled in Lua, *is* handled in Lua because a crash or failure here just dumps error messages to the Hammerspoon console.  A crash in the compiled code can cause the entire Hammerspoon application to terminate.

At a minimum, we need the following:
~~~lua
local module = require("hs._asm.disks.internal")
return module
~~~

Traditionally there is more, and for a module which is entirely based upon compiled code, this isn't strictly necessary, but we may decide later that some code can be handled more easily in Lua or that we want to add documentation information (Not discussed here... I think the existing samples at the Hammerspoon github site are still mostly valid, and the process for adding 3rd party documentation still needs to be fleshed out... look for an update or supplement to this), and its easier to do this in Lua than in compiled code.

##### Makefile

Preferences vary, and you may find that your coding habits are better served by something else, but the following is my usual Makefile:

~~~make
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

MODULE := $(current_dir)
PREFIX ?= ~/.hammerspoon/hs/_asm

OBJCFILE = ${wildcard *.m}
LUAFILE  = ${wildcard *.lua}
SOFILE  := $(OBJCFILE:.m=.so)
DEBUG_CFLAGS ?= -g

# special vars for uninstall
space :=
space +=
comma := ,
ALLFILES := $(LUAFILE)
ALLFILES += $(SOFILE)

.SUFFIXES: .m .so

CC=clang
EXTRA_CFLAGS ?= -Wconversion -Wdeprecated -F/Library/Frameworks
CFLAGS  += $(DEBUG_CFLAGS) -fobjc-arc -DHS_EXTERNAL_MODULE -Wall -Wextra $(EXTRA_CFLAGS)
LDFLAGS += -dynamiclib -undefined dynamic_lookup $(EXTRA_LDFLAGS)

all: verify $(SOFILE)

.m.so:
	$(CC) $< $(CFLAGS) $(LDFLAGS) -o $@

install: install-objc install-lua

verify: $(LUAFILE)
	luac-5.3 -p $(LUAFILE) && echo "Passed" || echo "Failed"

install-objc: $(SOFILE)
	mkdir -p $(PREFIX)/$(MODULE)
	install -m 0644 $(SOFILE) $(PREFIX)/$(MODULE)
	cp -vpR $(OBJCFILE:.m=.so.dSYM) $(PREFIX)/$(MODULE)

install-lua: $(LUAFILE)
	mkdir -p $(PREFIX)/$(MODULE)
	install -m 0644 $(LUAFILE) $(PREFIX)/$(MODULE)

clean:
	rm -v -rf $(SOFILE) *.dSYM $(DOC_FILE)

uninstall:
	rm -v -f $(PREFIX)/$(MODULE)/{$(subst $(space),$(comma),$(ALLFILES))}
	(pushd $(PREFIX)/$(MODULE)/ ; rm -v -fr $(OBJCFILE:.m=.so.dSYM) ; popd)
	rmdir -p $(PREFIX)/$(MODULE) ; exit 0

.PHONY: all clean uninstall verify install install-objc install-lua
~~~

I use this particular Makefile because it is pretty generic and works without change for almost all of the modules I have coded.  Change the `PREFIX` line so that it matches your desired location (i.e change _asm to your organizational label of choice).

This Makefile determines the modules name (disks) by checking the directory it is in, and can handle any number of lua or objective-c files in the directory.  It will also include the debugging support files (*.dSYM) with the module, so Console can provide line numbers in the crash log.

The warnings generated by this module are a little more restrictive than those used within the core application, but mainly with implicit data type conversion.  I've found that I'd rather be explicit so I know where precision may be affected.  In addition, this makefile includes ARC support for the module, which is considered a requirement for anything being submitted for possible inclusion in the Hammerspoon core.

As stated above, your tastes and requirements may differ, so use what works best for you.

##### internal.m

Before we get started, a couple of things to consider... There are some useful definitions and short code snippits in a file named `hammerspoon.h` which is included in the core application.  To take advantage of this file, perform the following in your modules directory: `ln -s /Applications/Hammerspoon.app/Contents/Resources/hammerspoon.h` (Note that this requirement is necessary for any module you create.  Also, there is discussion on moving this information into the LuaSkin framework or into its own framework, so this step may go away.)

There is also a LuaSkin framework provided with Hammerspoon which simplifies some of the code necessary to interface with Hammerspoon.  It is highly recommended, but not required, for a 3rd-party module to utilize this class.  It is required, if you want your module to be considered for inclusion in the core.  To utilize this framework, perform the following (it only needs to be done once): `sudo ln -s /Applications/Hammerspoon.app/Contents/Frameworks/LuaSkin.framework /Library/Frameworks/LuaSkin.framework`

You will be prompted for your password, and the framework will be linked where it can be found by the compiler.

##### internal.m - a breakdown of parts

Here is a breakdown of the skeleton I use.  It will be followed with the specific examples for this module (hs._asm.disks)

Some basic header stuff.  Note the #define USERDATA_TAG... this should be uncommented and set to a specific string which Lua will use to tag any data object (userdata) this module sends back to Lua/Hammerspoon with.  Think of it as the "type" of data this module works with and since only this module can understand it, it needs a unique type name.  If your module doesn't have a specific data object that it will be passing back and forth (i.e. it relies on the basic number, string, and table types only), you can leave this commented out.

~~~objC
#import <Cocoa/Cocoa.h>
#import <LuaSkin/LuaSkin.h>
#import "hammerspoon.h"

// #define USERDATA_TAG        "hs._asm.module"
int refTable ;
~~~

A reminder that this is where the main module functions are expected to be defined.  Note that any function which is to be called as a Lua function or method should have the signature specified in the code below and return an integer containing the number of results pushed onto the stack (note that if the result is a table, no matter how many items the table contains, it is still considered 1 returned value -- the table):

~~~objC
// this is where the core functionality should go
//
// static int moduleFunction(lua_State *L) {
//  ... code here ...
//   return 1 ;
// }
~~~

Some support functions and data for the public "interface" to this module.  They are commented out because not all modules will require them.

This provides a more type specific representation of the userdata object if it is accessed directly in the Hammerspoon console.  By default, userdata would appear as: `userdata: 0x600000652bc8`

~~~objC
// static int userdata_tostring(lua_State* L) {
// }
~~~

Specific cleanup when a specific userdata instance is garbage collected (goes out of scope).

~~~objC
// static int userdata_gc(lua_State* L) {
//     return 0 ;
// }
~~~

Specific cleanup when the entire module goes out of scope. Usually this only occurs when your Hammerspoon configuration is reloaded or the Hammerspoon application is quit.

~~~objC
// static int meta_gc(lua_State* __unused L) {
//     [hsimageReferences removeAllIndexes];
//     hsimageReferences = nil;
//     return 0 ;
// }
~~~

The metadata table which contains the methods which will be available to act directly on the userdata object returned for this module.  It is a array of arrays where each inner array contains 2 elements: a string representing the method name, and a c-function representing the c function which contains the code to execute.

~~~objC
// Metatable for userdata objects
// static const luaL_Reg userdata_metaLib[] = {
//     {"__tostring", userdata_tostring},
//     {"__gc",       userdata_gc},
//     {NULL,         NULL}
// };
~~~

The list of functions which are directly available as functions in this module.  These functions are available to be called directly and do not rely on the presence of a userdata - in fact, one or more of them are usually required to create the userdata object necessary to access the above methods.  The format is the same as described above.

~~~objC
// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {NULL, NULL}
};
~~~

The metatable for the module itself.  I seldom actually use this unless a module wide garbage collection function is required.

~~~objC
// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };
~~~

The `luaopen` function:  Traditionally the last function in the file, it is invoked via Lua when this portion of the module is loaded via the require statement in our `init.lua` file above.  It must be named as `luaopen_path` where path is the path specified in the require statement with each period (.) changed to an underscore (_).  For our example of `hs._asm.disks.internal`, this would be `luaopen_hs__asm_disks_internal`.

~~~objC
// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_module_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared];
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil // or module_metaLib
                               objectFunctions:nil // or userdata_metaLib];

    return 1;
}
~~~

##### internal.m (the real deal)

Here is the final code for this example.  Note that this code uses the LuaSkin framework.  Specific examples of differences if you don't use the framework will follow.

~~~objC
#import <Cocoa/Cocoa.h>
#import <LuaSkin/LuaSkin.h>
#import "hammerspoon.h"

#define USERDATA_TAG        "hs._asm.disks"
int refTable ;

@interface HSDiskWatcherClass : NSObject
    @property int fn;
@end

@implementation HSDiskWatcherClass
    - (void) _heard:(id)note {
// make sure we perform this on the main thread... Hammerspoon crashes when lua code
// executes on any other thread.
        [self performSelectorOnMainThread:@selector(heard:)
                                            withObject:note
                                            waitUntilDone:YES];
    }

    - (void) heard:(NSNotification*)note {
        if (self.fn != LUA_NOREF) {
            lua_State *_L = [[LuaSkin shared] L];
            lua_rawgeti(_L, LUA_REGISTRYINDEX, self.fn);
            lua_pushstring(_L, [[note name] UTF8String]);

            lua_newtable(_L) ;
            for (id key in note.userInfo) {
                lua_pushstring(_L, [[[note.userInfo objectForKey:key] description] UTF8String]) ;
                lua_setfield(_L, -2, [key UTF8String]) ;
            }

            if (![[LuaSkin shared] protectedCallAndTraceback:2 nresults:0]) {
                const char *errorMsg = lua_tostring(_L, -1);
                showError(_L, (char *)errorMsg);
            }
        }
    }
@end

static int newObserver(lua_State* L) {
    luaL_checktype(L, 1, LUA_TFUNCTION);

    HSDiskWatcherClass* listener = [[HSDiskWatcherClass alloc] init];

    lua_pushvalue(L, 1);
    listener.fn               = luaL_ref(L, LUA_REGISTRYINDEX) ;

    void** ud = lua_newuserdata(L, sizeof(id*)) ;
    *ud = (__bridge_retained void*)listener ;

    luaL_getmetatable(L, USERDATA_TAG) ;
    lua_setmetatable(L, -2) ;

    return 1;
}

static int startObserver(lua_State* L) {
    HSDiskWatcherClass* listener = (__bridge HSDiskWatcherClass*)(*(void**)luaL_checkudata(L, 1, USERDATA_TAG));
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter] ;

    [center addObserver:listener
               selector:@selector(_heard:)
                   name:NSWorkspaceDidMountNotification
                 object:nil];
    [center addObserver:listener
               selector:@selector(_heard:)
                   name:NSWorkspaceWillUnmountNotification
                 object:nil];
    [center addObserver:listener
               selector:@selector(_heard:)
                   name:NSWorkspaceDidUnmountNotification
                 object:nil];
    lua_settop(L,1);
    return 1;
}

static int stopObserver(lua_State* L) {
    HSDiskWatcherClass* listener = (__bridge HSDiskWatcherClass*)(*(void**)luaL_checkudata(L, 1, USERDATA_TAG));
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter] ;

    [center removeObserver:listener
                      name:NSWorkspaceDidMountNotification
                    object:nil];
    [center removeObserver:listener
                      name:NSWorkspaceWillUnmountNotification
                    object:nil];
    [center removeObserver:listener
                      name:NSWorkspaceDidUnmountNotification
                    object:nil];
    lua_settop(L,1);
    return 1;
}

// Not that useful, but at least we know what type of userdata it is, instead of just "userdata".
static int userdata_tostring(lua_State* L) {
    lua_pushstring(L, [[NSString stringWithFormat:@"%s: (%p)", USERDATA_TAG, lua_topointer(L, 1)] UTF8String]) ;
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    // stop observer, if running, and clean up after ourselves.

    stopObserver(L) ;
    HSDiskWatcherClass* listener = (__bridge_transfer HSDiskWatcherClass*)(*(void**)luaL_checkudata(L, 1, USERDATA_TAG));
    listener.fn = [[LuaSkin shared] luaUnref:refTable ref:listener.fn];
    listener = nil ;
    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     [hsimageReferences removeAllIndexes];
//     hsimageReferences = nil;
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"start",      startObserver},
    {"stop",       stopObserver},
    {"__tostring", userdata_tostring},
    {"__gc",       userdata_gc},
    {NULL,         NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new", newObserver},
    {NULL,  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

// NOTE: ** Make sure to change luaopen_..._internal **
int luaopen_hs__asm_disks_internal(lua_State* __unused L) {
    LuaSkin *skin = [LuaSkin shared];
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil // nil or module_metaLib
                               objectFunctions:userdata_metaLib ]; // nil or userdata_metaLib

    return 1;
}
~~~

##### Example of use

To test out the module, first install it with `make install` in the disks directory.

Now, open up the Hammerspoon console and type in the following:

~~~lua
disks = require("hs._asm.disks")
a = function(type, keys) print(type..": "..hs.inspect(keys):gsub("%s+"," ")) end
b = disks.new(a):start()
~~~

To test out the module, I mounted and unmounted the EFI partition of my primary hard drive from the command line in Terminal:

~~~sh
$ diskutil mount disk0s1
$ diskutil unmount disk0s1
~~~

The results in the Hammerspoon console:

~~~
NSWorkspaceDidMountNotification: { NSDevicePath = "/Volumes/EFI", NSWorkspaceVolumeLocalizedNameKey = "EFI", NSWorkspaceVolumeURLKey = "file:///Volumes/EFI/" }
NSWorkspaceWillUnmountNotification: { NSDevicePath = "/Volumes/EFI", NSWorkspaceVolumeLocalizedNameKey = "EFI", NSWorkspaceVolumeURLKey = "file:///Volumes/EFI/" }
NSWorkspaceDidUnmountNotification: { NSDevicePath = "/Volumes/EFI", NSWorkspaceVolumeLocalizedNameKey = "EFI", NSWorkspaceVolumeURLKey = "file:///Volumes/EFI/" }
~~~

Mission accomplished!

##### Without the LuaSkin Framework and Hammerspoon.h

For those more familiar with the core Lua C API, this will also work, but makes the code a little more complicated.  First off, the HSDiskWatcherClass would have to have a property to hold the LuaState, but this is relatively minor.

The luaopen function might look something like this:

~~~objC
int luaopen_{F_PATH}_{MODULE}_internal(lua_State* L) {
    luaL_newlib(L, userdata_metaLib);
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index");
        lua_setfield(L, LUA_REGISTRYINDEX, USERDATA_TAG);

// Create table for luaopen
    luaL_newlib(L, moduleLib);
//        luaL_newlib(L, module_metaLib);
//        lua_setmetatable(L, -2);

    return 1;
}
~~~

The heard: selector in HSDiskWatcherClass might look something like this:

~~~objC
    - (void) heard:(NSNotification*)note {
        if (self.fn != LUA_NOREF) {
            lua_State *_L = self.L;
            lua_getglobal(_L, "debug");
            lua_getfield(_L, -1, "traceback");
            lua_remove(_L, -2);
            lua_rawgeti(_L, LUA_REGISTRYINDEX, self.fn);
            lua_pushstring(_L, [[note name] UTF8String]);
            lua_newtable(_L) ;
            for (id key in note.userInfo) {
                lua_pushstring(_L, [[[note.userInfo objectForKey:key] description] UTF8String]) ;
                lua_setfield(_L, -2, [key UTF8String]) ;
            }

            if (lua_pcall(_L, 2, 0, -4) != LUA_OK) {
                lua_getglobal(L, "hs");
                lua_getfield(L, -1, "showError");
                lua_remove(L, -2);
                lua_pushvalue(L, -2);
                lua_pcall(L, 1, 0, 0);
            }
        }
    }
~~~

The userdata_gc function might look something like this:

~~~objC
static int userdata_gc(lua_State* L) {
    // stop observer, if running, and clean up after ourselves.

    stopObserver(L) ;
    HSDiskWatcherClass* listener = (__bridge_transfer HSDiskWatcherClass*)(*(void**)luaL_checkudata(L, 1, USERDATA_TAG));
    if (listener.fn != LUA_NOREF) {
        luaL_unref(L, LUA_REGISTRYINDEX, listener.fn);
        listener.fn = LUA_NOREF ;
    }
    listener = nil ;
    return 0 ;
}
~~~

As you can see, not too difficult, but a little longer and (in my oppinion) less clear.  An added benefit of using the LuaSkin framework is that the stored references to functions, etc. in the Lua registry for this module are isolated from other modules... properly coded, this shouldn't be a concern, but in tracking down bugs, it can be easier to realize you have a problem when getting a value of nil or LUA_NOREF rather than something else's data and not realizing it.

##### Conclusion

Hope this helps as an introduction to how I write modules for Hammerspoon.  You can always visit the IRC group, Google Group, or Github Issues forum referenced at the [Hammerspoon](http://www.hammerspoon.org) site for questions and more information.
