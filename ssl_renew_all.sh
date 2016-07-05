# Setup variables for arguments passed
cpUsername=$1
email=$2

LOCKFILE="/var/lock/renew_chooch" # Location to store the lock file
OUTFILE="/tmp/domains.json" # Location to store the API JSON output
debug=0 # Should the script spit out debug output?

# Function for debug output
decho() {
	if [ debug = 1 ]
	then
		echo "[DEBUG] $1"
	fi
}

# Make sure the user actually passed arguments
if [[ -z $2 ]]
then
	echo "Please enter arguments..."
	echo
	echo "Useage ./ssl_renew_all.sh <username> <email>"
	exit 1
fi

# Check if a lock file is present and if so tell the user to fuck off proper
# Ain't no parallelization in this bitch
if [ -d "$LOCKFILE" ]
then
	echo "It looks like another version of the script is still running."
	echo "Please check if this is the case."
	echo "If not then remove $LOCKFILE"
	exit 1
fi

# Set up the commands used to pull the user's domain information
INPUT=$(uapi --user=$cpUsername DomainInfo list_domains --output=json | jq '.result.data.sub_domains')
LENGTH=$(uapi --user=$cpUsername DomainInfo list_domains --output=json | jq -r '.result.data.sub_domains | length')

# Debug junk
decho "The length is: $LENGTH"


# If everything is going swimmingly create a lock file while the script does it's business
mkdir -p $LOCKFILE

# Query cPanel for the user's subdomains and dump the JSON to a file
uapi --user=funited DomainInfo domains_data --output=json | jq ".result.data.sub_domains" > $OUTFILE

# Drop some fire on cPanel (eg: iterate through each of the user's subdomains and renew the SSL cert for it)
for ((i = 0; i < $LENGTH; i++)); do
	subdomain=$(jq ".[$i].domain" /tmp/domains.json) # Grab the name of the subdomain from JSON
	subdomain_path=$(jq ".[$i].documentroot" /tmp/domains.json) # Grab the path of the subdomain from JSON
	decho $subdomain
	decho $subdomain_path
	echo "Running chooch script for $subdomain"
	eval /sysops/scripts/ssl_renew_auto.sh $subdomain $cpUsername $email $subdomain_path # Run the renewal script for this domain
	decho "The thing ran!"
	echo
done


# Finish up, remove the lock file, and remove the JSON output
rm -r $LOCKFILE
rm $OUTFILE
