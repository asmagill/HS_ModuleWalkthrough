
-- Note that any line in a lua file which begins with three dashes is considered part of
-- the documentation and should follow the general format shown here


--- === hs._asm.module ===
---
--- Stuff about the module
---
--- More descriptive description of the module and any other notes to put in the documentation
--- header.

local USERDATA_TAG = "hs._asm.module"
local module       = require(USERDATA_TAG..".internal")

--- If the documentation file is provided, register it so hs.docs and hs.docs.hsdocs know
--- about it.  But lack of the file shouldn't cause an error.
local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

-- private variables and methods -----------------------------------------

-- generally things that the module doesn't make public

-- Public interface ------------------------------------------------------

-- generally things that are made members of the `module` table so that they
-- are available if the user captures the return value of `require(...)`

--- hs._asm.function(arg1, ...) -> returnType
--- Function
--- One line description of the function
---
--- Parameters:
---  * arg1 - description (use "* None" if no arguments are expected)
---  * ...
---
--- Returns:
---  * description of return value (use * None if no value is returned)
---
--- Notes:
---  * any notes or examples
module.function = function(arg1, ...)
-- ...
end

-- Return Module Object --------------------------------------------------

return module
