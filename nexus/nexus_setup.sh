#!/bin/bash

# Import the Corretto GPG key to verify the integrity of downloaded packages.
wget -O - https://apt.corretto.aws/corretto.key | sudo gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | sudo tee /etc/apt/sources.list.d/corretto.list

# Install Amazon Corretto JDK 17 (Java 17) and wget.
sudo apt-get update; sudo apt-get install -y java-17-amazon-corretto-jdk wget

# Create directories for Nexus installation and temporary storage.
sudo mkdir -p /opt/nexus/   # Permanent location for Nexus
sudo mkdir -p /tmp/nexus/   # Temporary directory for installation

# Navigate to the temporary Nexus directory.
cd /tmp/nexus/

# Define the Nexus download URL.
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"

# Download the Nexus repository manager archive.
wget $NEXUSURL -O nexus.tar.gz

# Pause for 10 seconds to ensure the download completes.
sleep 10

# Extract the downloaded Nexus archive and store the extracted directory name.
EXTOUT=`tar xzvf nexus.tar.gz`
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`

# Pause for 5 seconds before proceeding.
sleep 5

# Remove the downloaded tar file to save space.
sudo rm -rf /tmp/nexus/nexus.tar.gz

# Move the extracted files to the permanent Nexus installation directory.
sudo cp -r /tmp/nexus/* /opt/nexus/

# Pause for 5 seconds to allow file operations to complete.
sleep 5

# Grant ownership of the Nexus installation directory to the current user.
sudo chown -R $(whoami):$(whoami) /opt/nexus 

# Create a systemd service file for managing Nexus as a service.
cat <<EOT | sudo tee /etc/systemd/system/nexus.service
[Unit]                                                                          
Description=Nexus Repository Manager                                            
After=network.target                                                            

[Service]                                                                       
Type=forking                                                                    
LimitNOFILE=65536                                                               
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start                                  
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop                                    
User=$(whoami)                                                                  
Restart=on-abort                                                                

[Install]                                                                       
WantedBy=multi-user.target                                                      
EOT

# Reload the systemd daemon to recognize the new Nexus service.
sudo systemctl daemon-reload

# Start the Nexus service.
sudo systemctl start nexus

# Enable Nexus to start automatically on system boot.
sudo systemctl enable nexus
