#!/usr/bin/bash

yum makecache fast
yum install -t -y aide
yum install -t -y open-vm-tools

cat << EOF > /etc/cron.d/aide-check
# /etc/cron.d/aide-check
      ## Check database of 0515 each day
      ## modified by:rlj on 4/15/19
      15 5 * * * /usr/sbin/aide > /opt/admin/aide_checks/aide_out_20180221.txt
EOF

cat << EOF >> /etc/aide.conf
All = p+i+n+u+g+s+m+S+sha512+acl+xattrs
EOF