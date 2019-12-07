GN_Unit(reader 
    Mode  app
	Units reflect sqlitecpp parser
    bFlat
)

target_link_libraries(reader PUBLIC "D:/Source/.libs/vcpkg/installed/x64-windows-static/lib/SQLiteCpp.lib")
target_link_libraries(reader PUBLIC "D:/Source/.libs/vcpkg/installed/x64-windows-static/lib/sqlite3.lib")
