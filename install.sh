#!/bin/bash
cd app
sudo apt update -y

# Check if Node.js version 20 is installed
NODE_VERSION_INSTALLED=$(node --version | grep -E '^v20\.' &> /dev/null && echo "yes" || echo "no")

if [ "$NODE_VERSION_INSTALLED" = "no" ]; then
    # Install Node.js v20.x
    echo "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || { echo "Failed to download Node.js setup"; exit 1; }
    sudo apt-get install -y nodejs || { echo "Failed to install Node.js"; exit 1; }
else
    echo "Node.js version 20 is already installed. Skipping installation..."
fi

# Set up environment variables (adjust them as necessary)
echo "Setting up environment variables..."
echo "PORT=3000" > .env
# Check if OpenAI API key is already set
if grep -q "OPENAI_API_KEY" .env; then
    echo "OpenAI API key is already set. Skipping..."
else
    echo "Please enter your OpenAI API key (input will be hidden for privacy):"
    read -s OPENAI_API_KEY # The -s flag hides API key input for privacy
    echo "OPENAI_API_KEY=${OPENAI_API_KEY}" >> .env
    echo "Thanks. You can edit the key later in the .env file in the /app folder of Document Hero."
fi

# Install your Node.js project dependencies
echo "Installing Node.js dependencies..."
sudo npm install || { echo "Failed to install Node.js dependencies"; exit 1; }

# Ask if the user wants to set up a domain name for nginx
echo "Do you wish to set up a web server and domain with Nginx? (y/n)"
read SETUP_DOMAIN

if [ "$SETUP_DOMAIN" = "y" ]; then
    DOMAIN_SET="no"
    while [ "$DOMAIN_SET" = "no" ]; do
        echo "Enter your desired domain name, e.g. docs.mydomainname.com:"
        read DOMAIN_NAME
        
        # Check if domain is already configured in nginx
        if [ -f "/etc/nginx/sites-available/$DOMAIN_NAME" ]; then
            echo "The domain $DOMAIN_NAME is already configured. Please choose another domain."
        else
            DOMAIN_SET="yes"
            
            # Install nginx
            echo "Installing Nginx..."
            sudo apt install -y nginx || { echo "Failed to install Nginx"; exit 1; }

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
            sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/ || { echo "Failed to enable Nginx site"; exit 1; }

            # Test Nginx configuration and reload if it's okay
            sudo nginx -t && sudo systemctl reload nginx || { echo "Nginx configuration test failed"; exit 1; }

            # Optionally, install certbot and obtain a Let's Encrypt certificate
            echo "Do you wish to install a SSL certificate for your domain? (y/n)"
            read INSTALL_SSL

            if [ "$INSTALL_SSL" = "y" ]; then
                sudo apt install -y certbot python3-certbot-nginx || { echo "Failed to install Certbot"; exit 1; }
                sudo certbot --nginx -d $DOMAIN_NAME || { echo "Certbot SSL certificate setup failed"; exit 1; }
            fi
        fi
    done
else
    echo "Okay, I'm skipping the Nginx configuration..."
fi

echo "Document Hero was installed successfully! Click here to learn how to use it: https://www.localmind.ai/document-hero"