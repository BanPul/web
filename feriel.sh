#!/bin/bash

set -e

echo "📦 Update dan install paket..."
sudo apt update
sudo apt install -y apache2 dnsmasq

echo "🛑 Nonaktifkan systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

echo "👤 Membuat user feriel dengan password 123..."
if id "feriel" &>/dev/null; then
    echo "User 'feriel' sudah ada."
else
    sudo useradd -m -s /bin/bash feriel
    echo 'feriel:123' | sudo chpasswd
    echo "User 'feriel' berhasil dibuat."
fi

echo "🌐 Setup direktori web..."
sudo mkdir -p /home/feriel/public_html/feriel.local
sudo chown -R feriel:feriel /home/feriel/public_html

echo "📄 Membuat file index.html..."
cat <<EOF | sudo tee /home/feriel/public_html/feriel.local/index.html > /dev/null
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>feriel.local - Halaman Utama</title>
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
        .card {
            background-color: rgba(255, 255, 255, 0.9);
            border-radius: 16px;
            padding: 30px;
            max-width: 600px;
            margin: auto;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        a {
            color: #007BFF;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>Selamat Datang di feriel.local</h1>
        <p>Website ini dikelola oleh user <strong>feriel</strong>.</p>
        <p><a href="#">Pelajari lebih lanjut</a></p>
    </div>
</body>
</html>
EOF

echo "🧾 Konfigurasi virtual host Apache..."
sudo tee /etc/apache2/sites-available/feriel.local.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName feriel.local
    DocumentRoot /home/feriel/public_html/feriel.local
    <Directory /home/feriel/public_html/feriel.local>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/feriel_error.log
    CustomLog \${APACHE_LOG_DIR}/feriel_access.log combined
</VirtualHost>
EOF

sudo a2ensite feriel.local.conf
sudo systemctl reload apache2

echo "🔧 Tambahkan konfigurasi dnsmasq..."
sudo sed -i '/\.local/d' /etc/dnsmasq.conf
echo "address=/feriel.local/192.168.5.129" | sudo tee -a /etc/dnsmasq.conf > /dev/null
sudo systemctl restart dnsmasq

echo "✅ Selesai! Akses http://feriel.local di browser. Pastikan DNS device diarahkan ke 192.168.5.129"
