#!/bin/bash

echo "Increasing open file limits to 40960..."

# تعديل limits.conf
echo -e "\nroot soft nofile 40960\nroot hard nofile 40960" | sudo tee -a /etc/security/limits.conf

# تحديث PAM
sudo sed -i '/pam_limits.so/d' /etc/pam.d/common-session
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session

sudo sed -i '/pam_limits.so/d' /etc/pam.d/common-session-noninteractive
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive

# تعديل إعدادات systemd
sudo sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
echo "DefaultLimitNOFILE=40960" | sudo tee -a /etc/systemd/system.conf

sudo sed -i '/DefaultLimitNOFILE/d' /etc/systemd/user.conf
echo "DefaultLimitNOFILE=40960" | sudo tee -a /etc/systemd/user.conf

# إعادة تحميل إعدادات systemd
sudo systemctl daemon-reexec

# تعديل إعدادات Nginx
sudo sed -i '/worker_rlimit_nofile/d' /etc/nginx/nginx.conf
echo -e "\nworker_rlimit_nofile 40960;" | sudo tee -a /etc/nginx/nginx.conf

# إصلاح قسم events ومنع التكرارات
sudo sed -i '/events {/,/}/d' /etc/nginx/nginx.conf
sudo sed -i '/http {/i events {\n    worker_connections 4096;\n    multi_accept on;\n}' /etc/nginx/nginx.conf

# إعادة تشغيل Nginx
sudo nginx -t && sudo systemctl restart nginx

# التأكد من التغييرات
echo "New file limits:"
ulimit -n
sudo cat /proc/$(pgrep nginx | head -n 1)/limits | grep "Max open files"

echo "Done! Please reboot the system to apply all changes."
