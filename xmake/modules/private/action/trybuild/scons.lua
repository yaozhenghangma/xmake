--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        scons.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_file")
import("lib.detect.find_tool")

-- detect build-system and configuration file
function detect()
    return find_file("SConstruct", os.curdir())
end

-- do clean
function clean()
    local scons = assert(find_tool("scons"), "scons not found!")
    os.vexecv(scons.program, {"-c"})
end

-- do build
function build()

    -- only support the current subsystem host platform now!
    assert(is_subhost(config.plat()), "scons: %s not supported!", config.plat())

    -- do build
    local scons = assert(find_tool("scons"), "scons not found!")
    os.vexec(scons.program)
    cprint("${color.success}build ok!")
end