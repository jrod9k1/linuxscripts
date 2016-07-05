# This is a script to automatically update ssl certificates for websites on a cPanel server
# Note that this script will also install a script to a website/account if none previosly exists

# The location of the LetsEncrypt binary
le="/root/letsencrypt/letsencrypt-auto"
# Set this to 0 to disable debug output or 1 to enable
debug=0

# Function for debug output
decho () {
	if [ $debug = 1 ]; then
		echo "[DEBUG] $1"
	fi
}

# Setup the variables that the user has passed
domain=$1
cpUsername=$2
email=$3
path=$4

# Check if the user has passed 3 variables
if [[ -z "$3" ]]
then
	echo "Please enter arguments..."
	echo
	echo "Usgage: ./ssl_renew_auto.sh <domain> <username> <contact email> <documentroot (optional)>"
	exit 1
fi

# Check if the user passed the document root param, if not default back
if [[ -z $path ]]
then
	path=/home/$cpUsername/public_html
fi

# Start and get all of the information organized
echo
echo "LetsEncrypt cPanel Auto Updater v1.0 by JRod"

# Debug junk
echo
decho "I received $domain for the domain."
decho "I received $cpUsername for the cPanel username."
decho "I received $email for the email."
decho "I received $path for the path"
echo

# Setup the LetsEncrypt script
echo "Retrieving SSL information..."
lcmd="$le --text --agree-tos --email $email certonly --renew-by-default --webroot --webroot-path $path -d $domain"
echo
echo "The command is '$lcmd'"
echo "Running..."
echo

# User has accepted, run the command
eval $lcmd


# Header setup jawn
hash=$(cat /root/.accesshash)
# Remove those pesky carriage returns, new line characters, and spaces
hash=$(echo $hash | tr -d '\r')
hash=$(echo $hash | tr -d '\n')
hash=$(echo $hash | tr -d ' ')
decho "The hash is currently $hash"


# Set the locations of our newly generated cert info
cert=$(cat /etc/letsencrypt/live/$domain/cert.pem)
key=$(cat /etc/letsencrypt/live/$domain/privkey.pem)
chain=$(cat /etc/letsencrypt/live/$domain/chain.pem)

# Setup the API query we will use to add/update the ssl certificate
header="Authorization: WHM root:$hash"

decho "Your header is $header"

# Remove all of the stupid junk from the cert params
cert=$(python -c "import urllib; print urllib.quote('''$cert''')")
key=$(python -c "import urllib; print urllib.quote('''$key''')")
chain=$(python -c "import urllib; print urllib.quote('''$chain''')")

# Setup the final query
query="https://127.0.0.1:2087/json-api/installssl?api.version=1&domain=$domain&crt=$cert&key=$key&cab=$chain&ip=$ip"
decho "Your query is now $query"

# Bust some moves on the cPanel API
curl --header "$header" $query --insecure

# Not even close babbbyyy
echo
echo "Done!"
