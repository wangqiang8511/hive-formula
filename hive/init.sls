{%- from 'hive/settings.sls' import hive_settings with context %}
{%- from 'mysql/settings.sls' import mysql_settings with context %}

include:
  - mysql
  - java


upload_cdh5_repo:
  file:
    - managed
    - name: /etc/yum.repos.d/cdh5.repo
    - source: salt://hive/files/cdh5.repo
    - template: jinja
    - user: root

hive-metastore:
  pkg:
    - installed
    - name: hive-metastore
    - require:
      - file: upload_cdh5_repo

java-connector:
  pkg:
    - installed
    - name: mysql-connector-java
    - require:
      - pkg: hive-metastore
  cmd:
    - wait
    - name: 'ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar'
    - watch:
      - pkg: java-connector

metastore-database:
  mysql_database:
    - present
    - name: metastore
    - connection_user: root
    - connection_pass: {{ mysql_settings.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_user: root

metastore-tables:
  file:
    - managed
    - name: /tmp/hive-schema-0.12.0.mysql.sql
    - source: salt://hive/files/hive-schema-0.12.0.mysql.sql
    - template: jinja
    - user: root
  cmd:
    - run
    - database: metastore
    - name: mysql --user='root' --password='{{ mysql_settings.root_password }}' metastore -e 'SOURCE /tmp/hive-schema-0.12.0.mysql.sql'
    - require:
      - mysql_database: metastore-database

hive_mysql_user:
  mysql_user.present:
    - name: hive
    - host: '%'
    - password: {{ hive_settings.hive_password }}
    - connection_user: root
    - connection_pass: {{ mysql_settings.root_password }}
    - connection_charset: utf8
    - require:
      - mysql_user: root
  mysql_grants.present:
    - grant: all privileges
    - database: metastore.*
    - user: hive
    - host: '%'
    - connection_user: root
    - connection_pass: {{ mysql_settings.root_password }}
    - connection_charset: utf8
    - require:
      - cmd: metastore-tables

hive_config_file:
  file:
    - managed
    - name: /etc/hive/conf/hive-site.xml
    - source: salt://hive/files/hive-site.xml
    - template: jinja
    - user: root
  service: 
    - running
    - name: hive-metastore
    - reload: True
    - require:
      - sls: java
