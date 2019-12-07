GN_vcpkg_install(sqlite3)
GN_vcpkg_install(sqlitecpp)
find_package(sqlite3   CONFIG REQUIRED)
find_package(SQLiteCpp CONFIG REQUIRED)

GN_Unit(sqlitecpp
    bFlat
    )
