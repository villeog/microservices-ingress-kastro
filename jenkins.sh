#!/bin/bash
# Update system
sudo apt update -y

# Install dependencies
sudo apt install -y fontconfig openjdk-17-jre-headless wget gnupg2

# Download and add the Jenkins GPG key
wget -O- https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists
sudo apt update -y

# Install Jenkins
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Print status
sudo systemctl status jenkins

