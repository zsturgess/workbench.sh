#!/bin/bash
# See http://ssb.stsci.edu/testing/shunit2/shunit2.html

originalpath=''

oneTimeSetUp()
{
  # Backup user's config
  if [ -f ~/.workbench-cli.conf ]; then
    mv ~/.workbench-cli.conf ~/.workbench-cli.conf.bak
  fi

  # Modify path
  originalpath=$PATH
  export PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)/test-files/mocks:$PATH
}

setUp()
{
  if [ -f ~/.workbench-cli.conf ]; then
    rm ~/.workbench-cli.conf
  fi
}

setUpConfigFile()
{
  cp test-files/basic.workbench-cli.conf ~/.workbench-cli.conf
}

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
  setUpConfigFile
  assertFalse 'Returns error code when run with config file that does not exist' './workbench.sh -c bad'
  assertTrue 'Shows error message when passed config file that does not exist' '[[ "`./workbench.sh -c bad`" == *"Config file provided does not exist"* ]]' 
}

testPerformsFirstTimeSetup()
{
  output=`printf 'user\npass\ntoken\ninstance' | ./workbench.sh -d Lead`
  assertTrue 'Inform the user when entering setup' '[[ $output == *"Detected first-time run, entering setup"* ]]'
  assertTrue 'Config file matches expected output' '[[ "`cat ~/.workbench-cli.conf | md5sum`" == "`cat test-files/basic.workbench-cli.conf | md5sum`" ]]'
}

testPerformsFirstTimeSetupWithCustomConfigLocation()
{
  output=`printf 'user\npass\ntoken\ninstance' | ./workbench.sh -d Lead -c ~/.special.workbench.conf`
  assertTrue 'Inform the user when entering setup' '[[ $output == *"Detected first-time run, entering setup"* ]]'
  assertTrue 'Default config file matches expected output' '[[ "`cat ~/.workbench-cli.conf | md5sum`" == "`cat test-files/basic.workbench-cli.conf | md5sum`" ]]'
  assertTrue 'Custom config file matches expected output' '[[ "`cat ~/.special.workbench.conf | md5sum`" == "`cat test-files/basic.workbench-cli.conf | md5sum`" ]]'

  rm ~/.special.workbench.conf
}

testSkipsFirstTimeSetupWhenConfigExists()
{
  setUpConfigFile
  output=`./workbench.sh -d Lead`
  assertFalse 'Inform the user when entering setup' '[[ $output == *"Detected first-time run, entering setup"* ]]'
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

oneTimeTearDown()
{
  # Restore user's config
  rm -f ~/.workbench-cli.conf

  if [ -f ~/.workbench-cli.conf.bak ]; then
    mv ~/.workbench-cli.conf.bak ~/.workbench-cli.conf
  fi

  # Reset path
  export PATH=$originalpath
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
