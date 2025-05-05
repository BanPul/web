#!/bin/bash

set -e

echo "📦 Update dan install paket..."
sudo apt update
sudo apt install -y apache2 dnsmasq

echo "🛑 Nonaktifkan systemd-resolved..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf

echo "👤 Membuat user ban dengan password 123..."
if id "ban" &>/dev/null; then
    echo "User 'ban' sudah ada."
else
    sudo useradd -m -s /bin/bash ban
    echo 'ban:123' | sudo chpasswd
    echo "User 'ban' berhasil dibuat."
fi

echo "🌐 Setup direktori web..."
sudo mkdir -p /home/ban/public_html/epul.local
sudo chown -R ban:ban /home/ban/public_html

echo "📄 Membuat file index.html..."
cat <<EOF | sudo tee /home/ban/public_html/epul.local/index.html > /dev/null
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>epul.local - Halaman Utama</title>
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
        <h1>Selamat Datang di epul.local</h1>
        <p>Website ini dikelola oleh user <strong>ban</strong>.</p>
        <p><a href="#">Pelajari lebih lanjut</a></p>
    </div>
</body>
</html>
EOF

echo "🧾 Konfigurasi virtual host Apache..."
sudo tee /etc/apache2/sites-available/epul.local.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName epul.local
    DocumentRoot /home/ban/public_html/epul.local
    <Directory /home/ban/public_html/epul.local>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/epul_error.log
    CustomLog \${APACHE_LOG_DIR}/epul_access.log combined
</VirtualHost>
EOF

sudo a2ensite epul.local.conf
sudo systemctl reload apache2

echo "🔧 Tambahkan konfigurasi dnsmasq..."
if ! grep -q "epul.local" /etc/dnsmasq.conf; then
    echo "address=/epul.local/192.168.20.129" | sudo tee -a /etc/dnsmasq.conf
fi
sudo systemctl restart dnsmasq

echo "✅ Semua selesai! Coba akses http://epul.local di browser."
echo "📌 Jangan lupa ubah DNS client menjadi: 192.168.20.129"
