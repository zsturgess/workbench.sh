#!/bin/bash
# See http://ssb.stsci.edu/testing/shunit2/shunit2.html

testErrorsWhenRunWithNoOptions()
{
  assertFalse 'Returns error code when run with no options' ./workbench.sh
}

if [ ! -f shunit2 ]; then
  echo 'Fetching testing library...'
  curl 'https://raw.githubusercontent.com/kward/shunit2/source/2.1.6/src/shunit2' -o shunit2
  echo
  echo
fi

echo 'Running tests'
echo
. shunit2
