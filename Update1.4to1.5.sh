# Code update 1.4 to 1.5 Guacamole
# Scenarios: Can you describe in detail the steps to upgrade from Guacamole 1.4.0 to Guacamole 1.5.0 ?
# without losing data or without interrupting the user's web service?
#
# Step 1. Backup your current Guacamole installation and database.
# Step 2. Download the latest version of Guacamole from the official website.
# Step 3. Stop the Tomcat service using the following command:

sudo systemctl stop tomcat
# Step 4. Extract the downloaded Guacamole archive and copy guacamole.war to Tomcat's webapps directory:
cd /opt
wget https://dlcdn.apache.org/guacamole/1.5.0/source/guacamole-server-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/source/guacamole-client-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-duo-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-header-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-jdbc-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-json-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-ldap-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-quickconnect-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-sso-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-auth-totp-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-history-recording-storage-1.5.0.tar.gz
wget https://dlcdn.apache.org/guacamole/1.5.0/binary/guacamole-vault-1.5.0.tar.gz
tar -xzf guacamole-1.5.0.war.gz
sudo cp /var/lib/tomcat9/webapps/guacamole.war /var/lib/tomcat9/webapps/guacamole145war
sudo rm /var/lib/tomcat9/webapps/guacamole.war
sudo cp guacamole.war /var/lib/tomcat9/webapps/

# Step 5. Remove old extensions by deleting all files in `/etc/guacamole/extensions` directory:
tar -xzf guacamole-client-1.5.0.tar.gz
tar -xzf guacamole-auth-duo-1.5.0.tar.gz
tar -xzf guacamole-auth-header-1.5.0.tar.gz
tar -xzf guacamole-auth-jdbc-1.5.0.tar.gz
tar -xzf guacamole-auth-json-1.5.0.tar.gz
tar -xzf guacamole-auth-ldap-1.5.0.tar.gz
tar -xzf guacamole-auth-quickconnect-1.5.0.tar.gz
tar -xzf guacamole-auth-sso-1.5.0.tar.gz
tar -xzf guacamole-auth-totp-1.5.0.tar.gz
tar -xzf guacamole-history-recording-storage-1.5.0.tar.gz
tar -xzf uacamole-vault-1.5.0.tar.gz

sudo rm /etc/guacamole/extensions/*

# Step 6. Copy all `.jar` files from `guacamole-1.5.0.war` archive to `/etc/guacamole/extensions/` directory:
sudo mkdir /etc/guacamole/extensions/
sudo cp guacamole-auth-jdbc-mysql-1.5.0.jar /etc/guacamole/extensions/
sudo cp mysql-connector-java-8.x.x.jar /etc/guacamole/extensions/

#7. Update `guacamole.properties` file in `/etc/guacamole/` directory with your previous settings.

#8. Restart Tomcat service:
sudo systemctl start tomcat
