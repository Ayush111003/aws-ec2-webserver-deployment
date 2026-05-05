#!/bin/bash

# Install Apache web server
sudo yum install -y httpd

# Create a custom HTML landing page
sudo bash -c 'cat > /var/www/html/index.html << HTML
<html>
<head><title>ACS730 Assignment 3</title></head>
<body>
  <h1>Hello from apatel638!</h1>
  <p>ACS730 Assignment 3 - Web Server on Amazon EC2</p>
</body>
</html>
HTML'

# Assign ownership of the page to acs730
sudo chown acs730:acs730 /var/www/html/index.html

# Start Apache and enable it to run on boot
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Apache installed and running"
