#!/bin/sh

if test $# -ne 3;
then
 echo "実行するには引数（domain_name, mysql_root_password, mysql_password）が必要です。"
 exit 1
fi
DOMAIN_NAME=$1
MYSQL_ROOT_PASSWORD=$2
MYSQL_PASSWORD=$3

#yum install -y git
#yum install -y vim
yum install -y curl

sed -i -e "s/-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT/-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT/g" /etc/sysconfig/iptables

service iptables restart

rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum repolist
yum -y groupinstall "Development Tools"
yum -y install openssl-devel readline-devel zlib-devel curl-devel libyaml-devel
yum -y install mysql-server mysql-devel
yum -y install httpd httpd-devel
yum -y install ImageMagick ImageMagick-devel ipa-pgothic-fonts

curl -O http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p481.tar.gz

tar zxvf ruby-2.0.0-p481.tar.gz 
cd ruby-2.0.0-p481
./configure --disable-install-doc
make
make install
cd ..

rm ruby-2.0.0-p481.tar.gz 
rm -rf ruby-2.0.0-p481

gem install bundler --no-rdoc --no-ri

sed -i -e "s/symbolic-links=0/symbolic-links=0\n\ncharacter-set-server=utf8/g" /etc/my.cnf
sed -i -e "s/mysqld.pid/mysqld.pid\n\n[mysql]\ndefault-character-set=utf8/g" /etc/my.cnf

service mysqld start
chkconfig mysqld on

mysql_secure_installation



echo "create database db_redmine default character set utf8;" >> mysql_create_table
echo "grant all on db_redmine.* to user_redmine@localhost identified by \""$MYSQL_PASSWORD"\";" >> mysql_create_table
echo "flush privileges;" >> mysql_create_table

mysql -u root -p$MYSQL_ROOT_PASSWORD < mysql_create_table
rm mysql_create_table

curl -O http://www.redmine.org/releases/redmine-2.5.1.tar.gz
tar xvf redmine-2.5.1.tar.gz
mv redmine-2.5.1 /var/lib/redmine
rm redmine-2.5.1.tar.gz

echo "production:" >> database.yml
echo "  adapter: mysql2" >> database.yml
echo "  database: db_redmine" >> database.yml
echo "  host: localhost" >> database.yml
echo "  username: user_redmine" >> database.yml
echo "  password: "$MYSQL_PASSWORD"" >> database.yml
echo "  encoding: utf8">> database.yml

mv database.yml /var/lib/redmine/config/database.yml

echo "production:" >> configuration.yml
echo "  email_delivery:" >> configuration.yml
echo "    delivery_method: :smtp" >> configuration.yml
echo "    smtp_settings:" >> configuration.yml
echo "      address: \"localhost\"" >> configuration.yml
echo "      port: 25" >> configuration.yml
echo "      domain: '"$DOMAIN_NAME"'" >> configuration.yml
echo "" >> configuration.yml
echo "  rmagick_font_path: /usr/share/fonts/ipa-pgothic/ipagp.ttf" >> configuration.yml

mv configuration.yml /var/lib/redmine/config/configuration.yml

cd /var/lib/redmine/
bundle install --without development test
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
gem install passenger --no-rdoc --no-ri

passenger-install-apache2-module

passenger-install-apache2-module --snippet >> /etc/httpd/conf.d/passenger.conf
echo "Header always unset \"X-Powered-By\"" >> /etc/httpd/conf.d/passenger.conf
echo "Header always unset \"X-Rack-Cache\"" >> /etc/httpd/conf.d/passenger.conf
echo "Header always unset \"X-Content-Digest\"" >> /etc/httpd/conf.d/passenger.conf
echo "Header always unset \"X-Runtime\"" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerMaxPoolSize 20" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerMaxInstancesPerApp 4" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerPoolIdleTime 3600" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerHighPerformance on" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerStatThrottleRate 10" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerSpawnMethod smart" >> /etc/httpd/conf.d/passenger.conf
echo "RailsAppSpawnerIdleTime 86400" >> /etc/httpd/conf.d/passenger.conf
echo "PassengerMaxPreloaderIdleTime 0" >> /etc/httpd/conf.d/passenger.conf

service httpd start
chkconfig httpd on
chown -R apache:apache /var/lib/redmine

sed -i -e "s/DocumentRoot \"\/var\/www\/html\"/DocumentRoot \"\/var\/lib\/redmine\/public\"/g" /etc/httpd/conf/httpd.conf

/etc/init.d/httpd configtest
/etc/init.d/httpd graceful

