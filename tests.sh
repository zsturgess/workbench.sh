#!/bin/bash

testErrorsWhenRunWithNoOptions()
{
  assertFalse 'Returns error code when run with no options' ./workbench.sh
}

if [ ! -f shunit2 ]; then
  curl 'https://raw.githubusercontent.com/kward/shunit2/source/2.1.6/src/shunit2' -o shunit2
fi

. shunit2
