# This is a script to automatically update ssl certificates for websites on a cPanel server

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


# Start and ask the user for information regarding the domain
echo
echo "LetsEncrypt cPanel Auto Updater v1.0 by JRod"
echo "Please answer all questions truthfully, you are under oath."
echo
read -p "Domain: " domain
read -p "cPanel Username: " cpUsername
read -p "Email: " email
echo
echo "Thanks mate."

# Debug junk
echo
decho "You entered $domain for the domain."
decho "You entered $cpUsername for the cPanel username."
decho "You entered $email for the email."
echo

# Setup the LetsEncrypt script
echo "Retrieving SSL information..."
lcmd="$le --text --agree-tos --email $email certonly --renew-by-default --webroot --webroot-path /home/$cpUsername/public_html -d $domain"
echo
echo "The command is '$lcmd'"
# Check with the user to ensure they are OK with the command being run
read -p "Are you OK with this (y/n)? " -n 1 -r
echo
# Check the user's answer
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo "Exiting..."
	exit 1
fi

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
