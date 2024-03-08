#!/bin/bash

# Update packages and install necessary software
sudo apt update && sudo apt upgrade -y

# Install Node.js v20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install nginx
sudo apt install -y nginx

# Clone your project repository
cd /var/www
echo "Please enter your git repository URL:"
read GIT_REPO_URL
sudo git clone $GIT_REPO_URL document-hero
cd document-hero

# Set up environment variables (adjust them as necessary)
echo "Setting up environment variables..."
echo "PORT=3000" > .env
echo "Please enter your OpenAI API key:"
read -s OPENAI_API_KEY # The -s flag hides API key input for privacy
echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env

# Install your Node.js project dependencies
echo "Installing Node.js dependencies..."
sudo npm install

# Configure and start your Node.js application
# Consider using pm2 or another process manager for a production environment
echo "Starting Node.js application..."
nohup node server.js &

# Ask if the user wants to set up a domain name for nginx
echo "Do you wish to set up a domain name for Nginx? (y/n)"
read SETUP_DOMAIN

if [ "$SETUP_DOMAIN" = "y" ]; then
    # Ask for the domain name
    read -p "Enter your domain name: " DOMAIN_NAME

    # Set up Nginx server block
    echo "Configuring Nginx..."
    SERVER_BLOCK="/etc/nginx/sites-available/$DOMAIN_NAME"
    sudo touch $SERVER_BLOCK
    sudo tee $SERVER_BLOCK <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    # Enable the Nginx server block
    sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

    # Test Nginx configuration and reload if it's okay
    sudo nginx -t && sudo systemctl reload nginx

    # Optionally, install certbot and obtain a Let's Encrypt certificate
    echo "Do you wish to install a SSL certificate for your domain? (y/n)"
    read INSTALL_SSL

    if [ "$INSTALL_SSL" = "y" ]; then
        sudo apt install -y certbot python3-certbot-nginx
        sudo certbot --nginx -d $DOMAIN_NAME
    fi
else
    echo "Skipping Nginx configuration..."
fi

echo "Deployment completed successfully!"
