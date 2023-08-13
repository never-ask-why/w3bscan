#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <target_domain>"
    exit 1
fi

target="$1"
output_dir="$1"

# Create output directory
mkdir -p "$output_dir"

# Subdomain Enumeration
echo "Performing subdomain enumeration..."
# Run subfinder in the background
parallel ::: "subfinder -silent -d '$wildcard' -o '$output_dir/subfinder.txt'" \
              "sublist3r -d '$target' -o '$output_dir/sublist3r.txt'" \
              "amass enum -d '$target' -o '$output_dir/amass.txt'"
# Wait for all background processes to finish
echo "Validating Url's!"
cat "$output_dir/sublist3r.txt" "$output_dir/subfinder.txt" "$output_dir/amass.txt" | sort -u > "$output_dir/all_subdomains.txt"

# Check Domain Availability
echo "Checking domain availability..."
while read -r subdomain; do
    whois "$subdomain" | grep -qiE "No match|Not found|AVAILABLE" && echo "$subdomain - Available"
done < "$output_dir/all_subdomains.txt" > "$output_dir/available_subdomains.txt"

# Check if Domains are Alive
echo "Checking if domains are alive..."
httpx -l "$output_dir/available_subdomains.txt" -threads 100 -status-code -o "$output_dir/alive_subdomains.txt"

# Fetch URLs using Gau
echo "Fetching URLs using Gau and hakrawler in parallel..."

parallel ::: "gau -c 100 -subs {} > '$output_dir/gau_{}.txt'" \
              "hakrawler -url {} -plain -threads 100 > '$output_dir/hakrawler_{}.txt'" ::: $(cat "$output_dir/alive_subdomains.txt")

# Combine and sort the fetched URLs
cat "$output_dir/gau_"* "$output_dir/hakrawler_"* > "$output_dir/urls.txt"
sort -u -o "$output_dir/urls.txt" "$output_dir/urls.txt"
# Check if URLs are Working
check_url_status() {
    url="$1"
    status=$(curl -o /dev/null -s -w "%{http_code}" "$url")
    if [[ $status == 200 ]]; then
        echo "$url - Working"
    else
        echo "$url - Not Working (Status: $status)"
    fi
}

export -f check_url_status

# Use parallel to check URL status
cat "$output_dir/urls.txt" | parallel -j 100 check_url_status {} | cut -d " " -f 1  > "$output_dir/working_urls.txt"


# Perform Nuclei Scan
echo "Performing Nuclei scan..."
nuclei -l "$output_dir/working_urls.txt" -t nuclei-templates -o "$output_dir/nuclei_scan.txt"

echo "Bug hunting script completed. Results saved in $output_dir"






