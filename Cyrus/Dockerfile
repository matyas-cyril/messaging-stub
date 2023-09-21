FROM debian:11.7-slim

LABEL autor="matyas-cyril"

ENV POSTFIX_RELAY_DOMAINS='email.test'
ENV POSTFIX_RELAY_HOST=''
ENV POSTFIX_MYHOSTNAME='servertest01'
ENV POSTFIX_MYNETWORKS='127.0.0.0/8'
ENV POSTFIX_MAILBOX_SIZE_LIMIT='0'
ENV CYRUS_LOGIN_REALMS='email.test'
ENV CYRUS_AUTOCREATE_QUOTA=0
ENV CPT_USERS_LIST='/tmp/users.list'

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y man-db htop db-util db-upgrade-util locate gettext-base

RUN apt-get install -y sasl2-bin vim vim-common rsyslog rsyslog-doc

# Installation de Postfix
RUN echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections && \
    apt-get install -y --no-install-recommends postfix postfix-cdb postfix-doc postfix-pcre postfix-lmdb \
     postfix-mysql postfix-pgsql postfix-ldap postfix-sqlite

# Installation de Cyrus
RUN echo "cyrus-common cyrus-common/removespools boolean true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends cyrus-admin cyrus-clients cyrus-doc \
        cyrus-murder cyrus-pop3d cyrus-imapd cyrus-common cyrus-caldav

RUN apt-get install -y rlwrap && \
    apt-get autoremove -y

RUN echo "\nif [[ -f /usr/bin/rlwrap && -f /usr/bin/cyradm ]]; then\n\
    alias cyradm='/usr/bin/rlwrap /usr/bin/cyradm'\nfi" >> /etc/bash.bashrc && \
    ln -s /usr/lib/cyrus/bin/imapd /usr/lib/cyrus/bin/proxyd && \
    ln -s /usr/lib/cyrus/bin/lmtpd /usr/lib/cyrus/bin/lmtpproxyd && \
    ln -s /usr/lib/cyrus/bin/pop3d /usr/lib/cyrus/bin/pop3proxyd
    
    
COPY --chown=root:root cyrus.conf imapd.conf imapd-ext.conf /etc/
COPY --chown=root:root main.cf /etc/postfix/
COPY --chown=root:root master.cf /etc/postfix/
COPY --chown=root:root smtpd.conf /etc/postfix/sasl/
COPY --chown=root:root rsyslog.conf /etc/rsyslog.conf
COPY --chown=root:root create_cpt.sh /create_cpt.sh

RUN /usr/sbin/usermod -aG mail postfix
RUN /usr/bin/gpasswd -a postfix sasl

RUN touch /var/lib/cyrus/tls_sessions.db && chown cyrus:mail /var/lib/cyrus/tls_sessions.db && \
    echo "lmtp               24/tcp                       # Local Mail Transfer Protocol" >> /etc/services && \
    echo "mupdate          3905/tcp                       # Murder Cyrus" >> /etc/services

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*

# Prise en compte des variables d'ENV dans Postfix
RUN envsubst '$POSTFIX_RELAY_DOMAINS,$POSTFIX_RELAY_HOST,$POSTFIX_MYHOSTNAME,$POSTFIX_MYNETWORKS,$POSTFIX_MAILBOX_SIZE_LIMIT' < /etc/postfix/main.cf > /etc/postfix/.main.cf && mv -f /etc/postfix/.main.cf /etc/postfix/main.cf

# Prise en compte des variables d'ENV dans Cyrus
RUN envsubst '$CYRUS_LOGIN_REALMS,$CYRUS_AUTOCREATE_QUOTA' < /etc/imapd.conf > /etc/.imapd.conf && mv -f /etc/.imapd.conf /etc/imapd.conf

RUN echo 'while [ 1 ]; do sleep 1 ;done;' > /loop_inf.sh && chmod +x /loop_inf.sh

CMD service rsyslog restart && \
    service cyrus-imapd start && \
    service postfix start && \
    /create_cpt.sh $CPT_USERS_LIST; \
    /loop_inf.sh
