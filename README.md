Hammerspoon Module Example
--------------------------

The purpose of this example is to describe the process I use for developing Lua modules for use with [Hammerspoon](http://www.hammerspoon.org).  It is by no means the only way, and does not cover all possible variants, but it should give a basic understanding of my process.

This overview assumes that you have XCode or the XCode Command Line utlities installed.  If not, go to https://developer.apple.com or use the App Store application and get it installed -- nothing here will work if you don't do that first.

#### Background
Modules which extend the Lua functionality available can be entirely written in Lua or a hybrid of Lua and a compiled component. For the purposes of this example, I focus on the hybrid module with Objective-C as the compiled component.  Lua has a well developed [C API](http://www.lua.org/manual/5.3/manual.html#4) which will be used in this example and Hammerspoon includes the LuaSkin framework which has been developed in conjunction with Hammerspoon to make this even easier.

This example is of an external hybrid module (sometimes referred to as a 3rd-Party module in the [Hammerspoon group](https://groups.google.com/forum/#!forum/hammerspoon) or [Hammerspoon issues tracker](https://github.com/Hammerspoon/hammerspoon/issues)), separate from the Hammerspoon code available at https://github.com/Hammerspoon/hammerspoon.  This is done for two reasons:  it allows for faster turn around during development, and it is, in my oppinion, easier.  If you believe your module should be considered for inclusion within the Hammerspoon core, it is still easier to code it as a stand alone entity first so people can test it out and discuss how it might best be included.

A brief overview of the individual files is described here.  For more specific implementation details, please examine the comments in the files included in the [templates/](templates) subdirectory.  A specific implementation is included in the [disks/](disks) subdirectory.

*If you've viewed earlier versions of this document, it was presented in the past as a Walkthrough... this proved difficult to maintain and keep current, so I am trying an overview approach where most of the detail is actually in the comments of the relevant files.  Hopefully this will make keeping at least the templates current over time easier.*

#### First things first

The example of a fully working module provided is named `disks`.  Hammerspoon has a tradition of naming its modules in the style of `hs.modulename`, but since this is an external module, its full name can be thought of as `hs._asm.disks`.  The `_asm` can be anything you choose - it's purely orginizational, but by prefacing the module name with `hs._asm` it's clear that this is not a builtin core module.

Note that this naming convention just defines the path where Hammerspoon/Lua can find the necessary support files.  By following this convention and making sure to install the finished module within the search paths (`package.path` and `package.cpath`) used by the `require` command, users can load your module with `require("hs._asm.disks")` (or whatever matches your module name and organizational tag.)

A hybrid module is usually, though not always, composed of 3 or 4 files:
* init.lua - this file contains any logic which can best be handled in Lua, and also includes a reference to the compiled code so that it is loaded and available.
* internal.m - this contains the source code for the compiled portion of the module.
* Makefile - this contains the necessary instructions for building and installing the module in a place where Hammerspoon can find it.
* docs.json - this file contains documentation information about the module which can be used by Hammerspoon's built in documentation server.  This file is completely optional.


##### init.lua
The complexity of this file will vary.  As a general rule of thumb, it is encouraged that anything which *can* be handled in Lua, *is* handled in Lua because a crash or failure here just dumps error messages to the Hammerspoon console.  A crash in the compiled code can cause the entire Hammerspoon application to terminate, and not always with a clear explanation in the Console application as to why or where.

At a minimum, we need the following:
~~~lua
local module = require("hs._asm.disks.internal")
return module
~~~

Traditionally there is more, as described in the [annotated template](templates/init.lua) I usually use.  The implemented version for `hs._asm.disks` can be seen in [disks](disks/init.lua).

##### Makefile

Preferences vary, and you may find that your coding habits are better served by something else, but I usually use something based on [Makefile](template/Makefile).


I use this particular Makefile because it is pretty generic and works without change for most of the modules I have coded.  Change the `MODPATH` line so that it matches your desired location (i.e change _asm to your organizational label of choice).

This Makefile determines the module's name by checking the directory it is in, and can handle any number of lua or objective-c files in the directory.  It will also include the debugging support files (*.dSYM) with the module, so Console can (usually) provide line numbers in the crash log and the documentation file `docs.json` if you create it.

The warnings generated by this Makefile are a little more restrictive than those used within the core application, but mainly with implicit data type conversion.  I've found that I'd rather be explicit so I know where precision may be affected.  In addition, this makefile includes ARC support for the module, which is considered a requirement for anything being submitted for possible inclusion in the Hammerspoon core.

You may also want to adjust the `HS_APPLICATION` line if Hammerspoon is not installed in `/Applications` and the `PREFIX` line if your Hammerspoon configuration is not in `~/.hammerspoon`.  Or you can do so during building, e.g. `PREFIX=xxx HS_APPLICATION=yyy make`.

This makefile supports the expected targets "all", "install", and "uninstall", which will perform as expected.

There are also a few other targets to make note of:

~~~sh
$ make docs
~~~
This will generate a `docs.json` file based on the documentation comments embedded in your source file.

~~~sh
$ VERSION=X.Y make release
~~~
This will create a file named `<dir-name>-vX.Y.tar.gz` which will contain the lua files and compiled code which can be used as a release bundle for people who don't want to manually compile your module.

~~~sh
$ VERSION=X.Y make releaseWithDocs
~~~
Same as above, but also include the `docs.json` file.

~~~sh
$ make markdown
~~~
Creates a file named `README.tmp.md` (which you should rename to `README.md` after editing it) which contains the documentation for the module in a format suitable for inclusion if you save your module's source code at Github.  To use this, you will need to download a support file and edit the `MARKDOWNMAKER` variable in the Makefile -- see the comments in the Makefile itself for the link.

~~~sh
$ make markdownWithTOC
~~~
Same as above, but includes a list of all functions/methods at the top of the file with links so you can jump directly to the documentation for the chosen entry.

Your tastes and requirements may differ, so use what works best for you.

##### internal.m

##### Conclusion

Hope this helps as an introduction to how I write modules for Hammerspoon.  You can always visit the IRC group, Google Group, or Github Issues forum referenced at the [Hammerspoon](http://www.hammerspoon.org) site for questions and more information.
