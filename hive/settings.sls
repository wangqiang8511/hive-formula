{% set p = salt['pillar.get']('hive', {}) %}
{% set g = salt['grains.get']('hive', {}) %}

{%- set default_hive_password = 'bigdata' %}
{%- set default_hadoop_fs = '' %}
{%- set default_host_ip = '127.0.0.1' %}

{%- set hive_password = g.get('hive_password', p.get('hive_password', default_hive_password)) %}
{%- set hadoop_fs = g.get('hadoop_fs', p.get('hadoop_fs', default_hadoop_fs)) %}
{%- set host_ip = salt['grains.get']('ip_interfaces', {}).get('eth0', [p.get('host_ip', default_host_ip)])[0] %}

{%- set hive_settings = {} %}

{%- do hive_settings.update({
    'hive_password' : hive_password,
    'hadoop_fs' : hadoop_fs,
    'host_ip' : host_ip,
})%}
