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

useTokenBearingCurlMock()
{
  rm test-files/mocks/curl
  ln -s token-bearing-curl test-files/mocks/curl
}

useFullCurlMock()
{
  rm test-files/mocks/curl
  ln -s full-mock-curl test-files/mocks/curl
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
  setUpConfigFile
  output=`./workbench.sh -c test-files/basic2.workbench-cli.conf -d Lead`
  assertTrue 'Made call to instance from custom config' '[[ $output == *"curl -sS https://instance2.salesforce.com/services/oauth2/token"* ]]'
}

testErrorsOnInvalidOutputFormat()
{
  setUpConfigFile
  assertFalse 'Returns error code when run with unrecognised output format' './workbench.sh -d Lead -f potato'
  assertTrue 'Shows error message when run with unrecognised output format' '[[ "`./workbench.sh -d Lead -f potato`" == *"Unknown format potato given"* ]]'
}

testErrorsOnFailureToGrabAccessTokenFromSFDC()
{
  setUpConfigFile
  assertFalse 'Returns error code when unable to grab access token from SFDC' './workbench.sh -d Lead'
}

testHandlesFailureToGrabAccessTokenFromSFDC()
{
  setUpConfigFile
  output=`./workbench.sh -d Lead`
  assertTrue 'Shows user error message when unable to grab access token from SFDC' '[[ $output == *"Failed to grab access token from Salesforce"* ]]'
}

testHandlesQueries()
{
  setUpConfigFile
  useTokenBearingCurlMock
  output=`./workbench.sh -q 'SELECT Id FROM Lead LIMIT 1' -f json`
  assertTrue 'Made query call to SFDC API' '[[ $output == *"curl -sSG --data-urlencode q=SELECT Id FROM Lead LIMIT 1 https://instance.salesforce.com/services/data/v40.0/query.json -H Authorization: Bearer BaT!vuMJgDaaVAj -H X-PrettyPrint:1"* ]]'
}

testHandlesDescribes()
{
  setUpConfigFile
  useTokenBearingCurlMock
  output=`./workbench.sh -d Lead -f json`
  assertTrue 'Made describe call to SFDC API' '[[ $output == *"curl -sSG https://instance.salesforce.com/services/data/v40.0/sobjects/Lead/describe.json -H Authorization: Bearer BaT!vuMJgDaaVAj -H X-PrettyPrint:1"* ]]'
}

testHandlesQueriesInXML()
{
  setUpConfigFile
  useTokenBearingCurlMock
  output=`./workbench.sh -q 'SELECT Id FROM Lead LIMIT 1' -f xml`
  assertTrue 'Made query call to SFDC API' '[[ $output == *"curl -sSG --data-urlencode q=SELECT Id FROM Lead LIMIT 1 https://instance.salesforce.com/services/data/v40.0/query.xml -H Authorization: Bearer BaT!vuMJgDaaVAj -H X-PrettyPrint:1"* ]]'
}

testHandlesDecribesInXML()
{
  setUpConfigFile
  useTokenBearingCurlMock
  output=`./workbench.sh -d Lead -f xml`
  assertTrue 'Made describe call to SFDC API' '[[ $output == *"curl -sSG https://instance.salesforce.com/services/data/v40.0/sobjects/Lead/describe.xml -H Authorization: Bearer BaT!vuMJgDaaVAj -H X-PrettyPrint:1"* ]]'
}

testFormatQueriesInCSV()
{
  which jq > /dev/null || startSkipping 
  setUpConfigFile
  useFullCurlMock
  output=`./workbench.sh -q 'SELECT Id, Country, LastModifiedDate, LastActivityDate FROM Lead LIMIT 5' -f csv`
  assertTrue 'Has CSV Headers' '[[ $(echo "$output"|head -n1) == "\"Id\",\"Country\",\"LastModifiedDate\",\"LastActivityDate\"" ]]'
  assertTrue 'Handles null in line 1 correctly' '[[ $(echo "$output" | head -n2 | tail -n1) == "\"00Q2000000r9HEbEAM\",,\"2016-07-04T15:52:54.000+0000\",\"2016-07-04\"" ]]'
  assertTrue 'Handles country in last line correctly' '[[ $(echo "$output" | tail -n1) == "\"00Q2000000stl6uEAA\",\"France\",\"2016-09-25T16:24:17.000+0000\",\"2016-11-11\"" ]]'
}

testFormatQueriesInTables()
{
  which jq > /dev/null || startSkipping 
  false
}

testFormatDescribesInCSV()
{
  setUpConfigFile
  assertFalse 'Returns error code when trying to run a describe in csv' './workbench.sh -d Lead -f csv'
  assertTrue 'Shows error message when trying to run a describe in csv' '[[ "`./workbench.sh -d Lead -f csv`" == *"CSV format is not supported for describe operation"* ]]' 
}

testFormatDescribesInTables()
{
  which jq > /dev/null || startSkipping 
  false
}

testFormatTablesWithNoJq()
{
  which jq > /dev/null && startSkipping
  setUpConfigFile
  useFullCurlMock
  assertFalse 'Returns error code when requesting tables without jq' './workbench.sh -d Lead -f table'
  assertTrue 'Shows error message when requesting tables without jq' '[[ "`./workbench.sh -d Lead -f table`" == *"jq must be installed and available on your $PATH for the csv or table output formats"* ]]'
}

tearDown()
{
  # Reset mocks
  rm test-files/mocks/curl
  ln -s echo-mock test-files/mocks/curl 
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
