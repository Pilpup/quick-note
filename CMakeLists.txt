cmake_minimum_required(VERSION 3.16)
project(QuickNotePlugin VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)

qt_add_qml_module(
    quicknote
    URI My.QuickNote
    VERSION 0.1
    QML_FILES
    SOURCES src/quicknote.h src/quicknote.cpp
)

target_link_libraries(quicknote PRIVATE Qt6::Core Qt6::Qml Qt6::Quick)
target_include_directories(quicknote PRIVATE src)
