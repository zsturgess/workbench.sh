#!/bin/bash
# See http://ssb.stsci.edu/testing/shunit2/shunit2.html

testErrorsWhenRunWithNoOptions()
{
  assertFalse 'Returns error code when run with no options' ./workbench.sh
}

testRunWithNoOptionsShowsHelp()
{
  assertTrue 'Shows help when run with no options' '[[ "`./workbench.sh`" == *"help message"* ]]'
}

testErrorsWhenPassedUnrecognisedOption()
{
  assertFalse 'Returns error code when run with unrecognised options' './workbench.sh -z bad'
  assertTrue 'Shows error message when passed unrecognised option' '[[ "`./workbench.sh -z bad`" == *"Unrecognised option"* ]]' 
  assertTrue 'Shows help when run with unrecognised options' '[[ "`./workbench.sh -z bad`" == *"help message"* ]]'
}

testErrorsWhenPassedBadConfigFile()
{
  assertFalse 'Returns error code when run with config file that does not exist' './workbench.sh -c bad'
  assertTrue 'Shows error message when passed config file that does not exist' '[[ "`./workbench.sh -c bad`" == *"Config file provided does not exist"* ]]' 
}

testPerformsFirstTimeSetup()
{
  true
}

testPerformsFirstTimeSetupWithCustomConfigLocation()
{
  true
}

testSkipsFirstTimeSetupWhenConfigExists()
{
  true
}

testUsesCustomConfigWhenProvided()
{
  true
}

testHandlesFailureToGrabAccessTokenFromSFDC()
{
  true
}

testHandlesQueries()
{
  true
}

testHandlesDescribes()
{
  true
}

testHandlesQueriesInXML()
{
  true
}

testHandlesDecribesInXML()
{
  true
}

if [ ! -f shunit2 ]; then
  echo 'Fetching testing library...'
  curl 'https://raw.githubusercontent.com/kward/shunit2/source/2.1.6/src/shunit2' -o shunit2
  echo
  echo
fi

echo 'Running tests...'
echo
. shunit2
