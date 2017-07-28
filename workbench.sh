# Requires curl >= 7.18.0
# @todo:
#  - Different output formats
#  - Document config file options & format in help
# Table output: https://stackoverflow.com/questions/12768907/bash-output-tables

default_config_location="${HOME}/.workbench-cli.conf"
bold=$(tput bold)
normal=$(tput sgr0)
sf_api_version='v40.0'
sf_client_id='3MVG99OxTyEMCQ3hSjz15qIUWtIhsQynMvhMgcxDgAxS0DRiDsDP2ZLTv_ywkjvbAdeanmHWInQ=='
sf_client_secret='7383101323593261180'

function usage() {
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
  echo;
  echo '  -h'
  echo '    Displays this help message'
  echo
  echo '  -q <SOQL Query>'
  echo '    Runs the SOQL query provided against your org and displays the results'
  echo
}

function alert() {
  echo "${bold}[!]${normal} $1"
}

if [[ "$#" < 2 ]]; then
  usage
  exit 0
fi

while [[ "$#" > 1 ]]; do case $1 in
    -c) config_location="$2";;
    -d) describe="$2";;
    -h) usage; exit 0;;
    -q) query="$2";;
    *) alert "Unrecognised option $1"; usage; exit 1;
  esac; shift; shift
done

if [ ! -f $default_config_location ]; then
  # Do setup
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

if [ ! -z "$config_location" ]; then
  if [ ! -f $config_location ]; then
    alert 'Config file provided does not exist'
    exit 1
  fi
else
  config_location=$default_config_location
fi

source $config_location

oauth2response=`curl https://${sf_instance}.salesforce.com/services/oauth2/token -d "grant_type=password" -d "client_id=${sf_client_id}" -d "client_secret=${sf_client_secret}" -d "username=${sf_username}" -d "password=${sf_password}"`
pattern='"access_token":"([^"]*)"'

if [[ $oauth2response =~ $pattern ]]; then	
    access_token="${BASH_REMATCH[1]}"
else
  alert 'Failed to grab access token from Salesforce'
  echo $oauth2response
  exit 1
fi

if [ ! -z "$query" ]; then
  curl -G --data-urlencode "q=${query}" "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/query" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"
  echo
fi

if [ ! -z "$describe" ]; then
  curl -G "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/sobjects/${describe}/describe/" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"
  echo
fi
