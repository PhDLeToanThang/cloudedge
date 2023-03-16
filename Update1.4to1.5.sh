# Code update 1.4 to 1.5 Guacamole
# Scenarios: Can you describe in detail the steps to upgrade from Guacamole 1.4.0 to Guacamole 1.5.0 ?
# without losing data or without interrupting the user's web service?
#
# 1. Backup your current Guacamole installation and database.
# 2. Download the latest version of Guacamole from the official website.
# 3. Stop the Tomcat service using the following command:

sudo systemctl stop tomcat
#4. Extract the downloaded Guacamole archive and copy guacamole.war to Tomcat's webapps directory:
cd /opt
wget https://dlcdn.apache.org/guacamole/1.5.0/source/guacamole-server-1.5.0.tar.gz
tar -xzf guacamole-1.5.0.war.gz
sudo cp guacamole.war /var/lib/tomcat9/webapps/

#5. Remove old extensions by deleting all files in `/etc/guacamole/extensions` directory:
sudo rm /etc/guacamole/extensions/*

#6. Copy all `.jar` files from `guacamole-1.5.0.war` archive to `/etc/guacamole/extensions/` directory:
sudo mkdir /etc/guacamole/extensions/
sudo cp guacamole-auth-jdbc-mysql-1.5.0.jar /etc/guacamole/extensions/
sudo cp mysql-connector-java-8.x.x.jar /etc/guacamole/extensions/

#7. Update `guacamole.properties` file in `/etc/guacamole/` directory with your previous settings.

#8. Restart Tomcat service:
sudo systemctl start tomcat
