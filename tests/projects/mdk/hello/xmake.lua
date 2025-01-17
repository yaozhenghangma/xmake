add_rules("mode.debug", "mode.release")

target("foo")
    add_rules("mdk.static")
    add_files("src/foo/*.c")

target("hello")
    add_deps("foo")
    add_rules("mdk.console")
    add_files("src/*.c", "src/*.s")
    add_defines("__EVAL", "__MICROLIB")
    add_includedirs("src/lib/cmsis")
