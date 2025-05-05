#!/bin/bash

# Update dan Install Paket yang Diperlukan
echo "📦 Mengupdate dan menginstal paket..."
sudo apt update
sudo apt install -y apache2 dnsmasq

# Nonaktifkan systemd-resolved
echo "🛑 Nonaktifkan systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf

# Membuat Direktori Web untuk epul.test
echo "🌐 Membuat direktori untuk epul.test dan menambahkan file index.html..."
sudo mkdir -p /home/ban/public_html/epul.test
sudo chown -R ban:ban /home/ban/public_html

# Menambahkan file index.html dengan konten dasar
cat <<EOF | sudo tee /home/ban/public_html/epul.test/index.html > /dev/null
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>epul.test - Halaman Utama</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(to right, #74ebd5, #9face6);
            color: #333;
            text-align: center;
            padding: 50px;
            margin: 0;
        }
        h1 {
            font-size: 48px;
            color: #ffffff;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        p {
            font-size: 20px;
            color: #f5f5f5;
        }
    </style>
</head>
<body>
    <h1>Selamat Datang di epul.test</h1>
    <p>Website ini dikelola oleh user <strong>ban</strong>.</p>
</body>
</html>
EOF

# Konfigurasi VirtualHost di Apache untuk epul.test
echo "🌐 Mengonfigurasi VirtualHost di Apache untuk epul.test..."
sudo tee /etc/apache2/sites-available/epul.test.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName epul.test
    DocumentRoot /home/ban/public_html/epul.test
    <Directory /home/ban/public_html/epul.test>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/epul_error.log
    CustomLog \${APACHE_LOG_DIR}/epul_access.log combined
</VirtualHost>
EOF

# Aktifkan VirtualHost dan restart Apache
echo "🔧 Mengaktifkan VirtualHost dan me-restart Apache..."
sudo a2ensite epul.test.conf
sudo systemctl reload apache2

# Mengonfigurasi dnsmasq untuk epul.test
echo "🔧 Mengonfigurasi dnsmasq untuk epul.test..."
echo "address=/epul.test/192.168.20.129" | sudo tee -a /etc/dnsmasq.conf > /dev/null

# Restart dnsmasq
sudo systemctl restart dnsmasq

# Menambahkan entri untuk epul.test di /etc/hosts
echo "📂 Menambahkan entri untuk epul.test ke /etc/hosts..."
echo "192.168.20.129 epul.test" | sudo tee -a /etc/hosts > /dev/null

# Restart layanan DNS dan Apache untuk memastikan semuanya berjalan
echo "🔄 Restart layanan untuk memastikan konfigurasi berjalan..."
sudo systemctl restart systemd-resolved

# Membuka port HTTP di firewall jika diperlukan
echo "⚙️ Membuka port HTTP di firewall..."
sudo ufw allow 80/tcp

# Selesai!
echo "✅ Konfigurasi selesai! Sekarang coba akses http://epul.test di browser."
