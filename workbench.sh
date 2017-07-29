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

oauth2response=`curl -sS https://${sf_instance}.salesforce.com/services/oauth2/token -d "grant_type=password" -d "client_id=${sf_client_id}" -d "client_secret=${sf_client_secret}" -d "username=${sf_username}" -d "password=${sf_password}"`
pattern='"access_token":"([^"]*)"'

if [[ $oauth2response =~ $pattern ]]; then	
    access_token="${BASH_REMATCH[1]}"
else
  alert 'Failed to grab access token from Salesforce'
  echo $oauth2response
  exit 1
fi

if [ ! -z "$query" ]; then
  curl -sSG --data-urlencode "q=${query}" "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/query.${format}" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"
  echo
fi

if [ ! -z "$describe" ]; then
  curl -sSG "https://${sf_instance}.salesforce.com/services/data/${sf_api_version}/sobjects/${describe}/describe.${format}" -H "Authorization: Bearer ${access_token}" -H "X-PrettyPrint:1"
  echo
fi
