sudo apt install parallel -y
sudo apt install sublist3r -y
sudo apt install amass -y
sudo apt install subfinder -y
#!/bin/bash

# Install subfinder
GO111MODULE=off go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder

# Install sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r && pip install -r requirements.txt

# Install amass
export GO111MODULE=on
go get -v github.com/OWASP/Amass/v3/...

# Install httpx
GO111MODULE=off go get -v github.com/projectdiscovery/httpx/cmd/httpx

# Install gau
GO111MODULE=on go get -u -v github.com/lc/gau

# Install hakrawler
GO111MODULE=on go get -v github.com/hakluke/hakrawler

# Install Nuclei
GO111MODULE=on go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei

echo "Requirements installation completed."
