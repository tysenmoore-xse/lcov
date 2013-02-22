#!/bin/sh

LCOV_PATH="../src/lcov.lua"

echo lua $LCOV_PATH -gen $1 $2 -exe ./lcov_test.lua
eval lua $LCOV_PATH -gen $1 $2 -exe ./lcov_test.lua

