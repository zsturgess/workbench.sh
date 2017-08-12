# Workbench.sh @DEV
# Workbench.sh is a bash script designed to bring some of the power of the Salesforce Workbench to the command-line.

default_config_location="${HOME}/.workbench-cli.conf"
bold=$(tput bold)
normal=$(tput sgr0)
sf_api_version='v40.0'
sf_client_id='3MVG99OxTyEMCQ3hSjz15qIUWtIhsQynMvhMgcxDgAxS0DRiDsDP2ZLTv_ywkjvbAdeanmHWInQ=='
sf_client_secret='7383101323593261180'
format='json'

function usage() {
  echo "Workbench.sh ${bold}@DEV${normal}"
  echo
  echo "${bold}Usage:${normal} workbench.sh [OPTIONS]"
  echo
  echo "${bold}Options:${normal}"
  echo
  echo '  -c <FULL PATH TO CONFIG FILE>'
  echo '    Use an alternative config file. If omitted, the default config file'
  echo '    (at $HOME/.workbench-cli.conf) will be used'
  echo
  echo '  -d <OBJECT NAME>'
  echo '    Describes the attributes, fields, record types, and child'
  echo '    relationships of the object you name'
  echo
  echo '  -f <FORMAT>'
  echo '    Display results in the given format. Valid values are json and xml'
  echo '    You may also specify csv or table as values, although the jq'
  echo '    utility (https://stedolan.github.io/jq/) must be installed'
  echo "    If you don't provide this option, it will default to json"
  echo
  echo '  -h'
  echo '    Displays this help message'
  echo
  echo '  -q <SOQL Query>'
  echo '    Runs the SOQL query provided against your org and displays the results'
  echo
  echo "${bold}Config files:${normal}"
  echo
  echo '  Workbench.sh will help you set up your default config file the first'
  echo '  time you attempt to use it. Config files take the form of bash scripts'
  echo "  that simply define variables e.g. var_name='var_value'"
  echo
  echo '  The full list of options that can be defined in a config file is:'
  echo
  echo '  sf_username'
  echo '    The username to authenticate on the API with'
  echo
  echo '  sf_password'
  echo '    The password (and secret token) to authenticate on the API with'
  echo
  echo '  sf_instance'
  echo '    The instance your org is on (i.e. na5, eu7, cs81)'
  echo
  echo '  sf_api_version'
  echo '    (Optional) The version of the REST API to use'
  echo
  echo '  sf_client_id / sf_client_secret'
  echo '    (Optional) Workbench.sh will use a built-in connected application'
  echo '    to communicate with your org via the API. If you want to use your'
  echo '    own connected application, you will need to create one and put'
  echo '    the oauth client_id and client_secret in your config file.'
  echo '    (http://help.salesforce.com/apex/HTViewHelpDoc?id=connected_app_create.htm&language=en_US)'
  echo
  echo '  format'
  echo '    A default format to use. Valid values are xml or json'
  echo
  echo '  You can use workbench.sh with multiple orgs by keeping each orgs config'
  echo "  in seperate files and using the ${bold}-c${normal} option to pick which config (and"
  echo '  therefore which org) to use'
}

function alert() {
  echo "${bold}[!]${normal} $1"
}

function parseSOQLQueryForFields() {
  shopt -s nocasematch
  local pattern='SELECT (.*) FROM '

  if [[ $1 =~ $pattern ]]; then
    local fields="${BASH_REMATCH[1]}"
  else
    alert 'Invalid SOQL Query'
    echo "Usage: workbench.sh -q 'SELECT Field1, Field2 FROM Object [WHERE Field1 = \"value\"]'"
    exit 1
  fi

  shopt -u nocasematch
  local IFS=','
  local line='------------------------------'

  for item in $fields; do
    item=${item// /}
    headerrow="${headerrow}, \"$item\""
    underlinerow="${underlinerow}, \"${line:(${#line} - ${#item})}\""
    fieldfilter="${fieldfilter}, .${item}"
  done

  headerrow=${headerrow:2}
  underlinerow=${underlinerow:2}
  fieldfilter=${fieldfilter:2}
}

function getAccessToken() {
  # Authenticate with Salesforce
  local oauth2response=`curl -sS https://${sf_instance}.salesforce.com/services/oauth2/token -d "grant_type=password" -d "client_id=${sf_client_id}" -d "client_secret=${sf_client_secret}" -d "username=${sf_username}" -d "password=${sf_password}"`
  local pattern='"access_token":"([^"]*)"'

  if [[ $oauth2response =~ $pattern ]]; then	
    access_token="${BASH_REMATCH[1]}"
  else
    alert 'Failed to grab access token from Salesforce'
    echo $oauth2response
    exit 1
  fi
}

# Parse options
if [[ "$#" < 2 ]]; then
  usage
  exit 1
fi

while [[ "$#" > 1 ]]; do case $1 in
    -c) config_location="$2";;
    -d) describe="$2";;
    -f) format="$2";;
    -h) usage; exit 0;;
    -q) query="$2";;
    *) alert "Unrecognised option $1"; usage; exit 1;
  esac; shift; shift
done

format=$(echo $format | awk '{print tolower($0)}')

# Detect first-time run and perform setup
if [ ! -f $default_config_location ]; then
  alert 'Detected first-time run, entering setup...'
  
  read -p "Please enter your Salesforce username (and press ENTER): " sf_username 
  read -s -p "Please enter your Salesforce password (and press ENTER): " sf_password_only 
  echo
  read -s -p "Please enter your Salesforce security token (and press ENTER):" sf_security_token
  echo
  read -p "Please enter your Salesforce instance (i.e. na5) (and press ENTER): " sf_instance 
  echo

  sf_password="${sf_password_only}${sf_security_token}"

  echo "sf_username='${sf_username}'" >> $default_config_location
  echo "sf_password='${sf_password}'" >> $default_config_location
  echo "sf_instance='${sf_instance}'" >> $default_config_location

  if [ ! -z "$config_location" ]; then
    cp $default_config_location $config_location
  fi
fi

# Check for existance of custom config, if supplied
if [ ! -z "$config_location" ]; then
  if [ ! -f $config_location ]; then
    alert 'Config file provided does not exist'
    exit 1
  fi
else
  config_location=$default_config_location
fi

# Read config (custom or default)
source $config_location

# Check format
case $format in
  json|xml)
    ;;
  csv|table)
    which jq > /dev/null || alert 'jq must be installed and available on your $PATH for the csv or table output formats' && echo 'Install jq as instructed at https://stedolan.github.io/jq/download/ and try again' && exit 1 
    ;;
  *)
    alert "Unknown format $format given"
    usage
    exit 1
    ;;
esac

# Handle SOQL Queries
if [ ! -z "$query" ]; then
  if [[ $format == "csv" ]] || [[ $format == "table" ]]; then
    parseSOQLQueryForFields "$query"

    originalformat=$format
    format='json'
  fi

  getAccessToken
  output=`curl -sSG --data-urlencode "q=${query}" "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/query.${format}" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"`

  if [[ $originalformat == "csv" ]]; then
    echo "$output" | jq -r "[$headerrow], (.records[] | [$fieldfilter]) | @csv"
  elif [[ $originalformat == "table" ]]; then
    echo "$output" | jq -r "[$headerrow], [$underlinerow], (.records[] | [$fieldfilter]) | @csv" | sed 's/","/~/g' | sed 's/"//g' | column -t -s~
  else
    echo "$output"
  fi

  echo
fi

# Handle describe calls
if [ ! -z "$describe" ]; then
  if [[ $format == "csv" ]]; then
    alert 'CSV format is not supported for describe operations'
    exit 1
  elif [[ $format == "table" ]]; then
    originalformat=$format
    format='json'
  fi

  getAccessToken
  output=`curl -sSG "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/sobjects/${describe}/describe.${format}" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"`
  
  if [[ $originalformat == "table" ]]; then
    echo "${bold}Properties${normal}"
    echo "=========="
    echo "$output" | jq -r 'del(.[]|iterables) | del(.[]|nulls) | to_entries[] | [.key, .value] | @csv' | sed 's/true/"\xE2\x9C\x93"/' | sed 's/false/"\xE2\xA8\xAF"/' | sed 's/"//g' | column -t -s,
    echo
    echo "${bold}Child Relationships${normal}"
    echo "==================="
    echo "$output" | jq -r '["Field", "Object", "Relationship Name", "Deprecated", "Cascades Deletes", "Restricts Deletes"], ["-----", "------", "-----------------", "----------", "----------------", "-----------------"], (.childRelationships[] | [.field, .childSObject, .relationshipName, .deprecatedAndHidden, .cascadeDelete, .restrictedDelete]) | @csv' | sed 's/,,/," ",/g' | sed 's/true/"\xE2\x9C\x93"/g' | sed 's/false/"\xE2\xA8\xAF"/g' | sed 's/"//g' | column -t -s,
    echo
    echo "${bold}Fields${normal}"
    echo "======"
    echo "$output" | jq -r '["Label", "Name", "Type", "Unique", "Updatable"], ["-----", "----", "----", "------", "---------"], (.fields[] | [.label, .name, .type, .unique, .updateable]) | @csv' | sed 's/,,/," ",/g' | sed 's/true/"\xE2\x9C\x93"/g' | sed 's/false/"\xE2\xA8\xAF"/g' | sed 's/"//g' | column -t -s,
  else
    echo "$output"
  fi

  echo
fi
