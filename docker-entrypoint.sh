#! /bin/bash 
umask 000
su tusd -c \
'/usr/local/bin/tusd -behind-proxy -unix-sock /hs_tmp/tusd.sock \
     -upload-dir /tmp/tusd \ -hooks-dir /srv/tusd-hooks \
     -hooks-enabled-events pre-finish,post-finish -base-path /upload/'
