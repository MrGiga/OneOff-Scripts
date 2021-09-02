#Resets mysql root password

#!/bin/bash
echo "Starting MySQL Service"
/etc/init.d/mysql start
ATTEMPTS=0
while [ ! -e /var/run/mysqld/mysqld.sock ]
do
 echo "File not Found After Starting Service"
 sleep 1
 if [ $ATTEMPTS -gt 20 ]
   then
   echo "Could never find the file"
   exit 0
 fi
 ATTEMPTS=$(( $ATTEMPTS + 1 ))
done
echo "Copying mysql socket information"
cp -rp /var/run/mysqld /var/run/mysqld.bak
echo "Stopping MySQL Service"
/etc/init.d/mysql stop
echo "Restoring mysql socket information"
mv /var/run/mysqld.bak /var/run/mysqld
echo "Starting MySqld_Safe"
mysqld_safe --skip-grant-tables --skip-networking &
echo "Waiting for MySQLD to load"
sleep 3
while [ ! -e /var/run/mysqld/mysqld.sock ]
do
 echo "File not Found After Starting mysqld_safe"
 sleep 1
done
echo "Attempting Password Reset"
mysql -uroot -e "FLUSH PRIVILEGES;ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';SHUTDOWN;"
echo "Password Reset Finished"
