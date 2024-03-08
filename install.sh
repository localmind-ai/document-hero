#!/bin/bash
sudo apt update -y

# Install Node.js v20.x
echo "Installing Node.js version 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || { echo "Failed to download Node.js setup"; exit 1; }
sudo apt-get install -y nodejs || { echo "Failed to install Node.js"; exit 1; }

# Install nginx
echo "Installing Nginx..."
sudo apt install -y nginx || { echo "Failed to install Nginx"; exit 1; }

# Set up environment variables (adjust them as necessary)
echo "Setting up environment variables..."
echo "PORT=3000" > .env
echo "Please enter your OpenAI API key (input will be hidden for privacy):"
read -s OPENAI_API_KEY # The -s flag hides API key input for privacy
echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env

# Install your Node.js project dependencies
echo "Installing Node.js dependencies..."
sudo npm install || { echo "Failed to install Node.js dependencies"; exit 1; }

# Configure and start your Node.js application
# Consider using pm2 or another process manager for a production environment
echo "Starting Node.js application..."
nohup node server.js & || { echo "Failed to start Node.js application"; exit 1; }

# Ask if the user wants to set up a domain name for nginx
echo "Do you wish to set up a domain name for Nginx? (y/n)"
read SETUP_DOMAIN

if [ "$SETUP_DOMAIN" = "y" ]; then
    # Ask for the domain name
    echo "Enter your domain name:"
    read DOMAIN_NAME

    # Set up Nginx server block
    echo "Configuring Nginx..."
    SERVER_BLOCK="/etc/nginx/sites-available/$DOMAIN_NAME"
    sudo touch "$SERVER_BLOCK"
    sudo tee "$SERVER_BLOCK" <<EOF
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
    sudo ln -s /etc/nginx/sites-available/"$DOMAIN_NAME" /etc/nginx/sites-enabled/ || { echo "Failed to enable Nginx site"; exit 1; }

    # Test Nginx configuration and reload if it's okay
    sudo nginx -t && sudo systemctl reload nginx || { echo "Nginx configuration test failed"; exit 1; }

    # Optionally, install certbot and obtain a Let's Encrypt certificate
    echo "Do you wish to install a SSL certificate for your domain? (y/n)"
    read INSTALL_SSL

    if [ "$INSTALL_SSL" = "y" ]; then
        sudo apt install -y certbot python3-certbot-nginx || { echo "Failed to install Certbot"; exit 1; }
        sudo certbot --nginx -d "$DOMAIN_NAME" || { echo "Certbot SSL certificate setup failed"; exit 1; }
    fi
else
    echo "Skipping Nginx configuration..."
fi

echo "Deployment completed successfully!"
