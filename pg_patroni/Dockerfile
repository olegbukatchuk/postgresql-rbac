ARG PG_MAJOR=10
ARG COMPRESS=false
ARG PGHOME=/home/postgres
ARG PGDATA=$PGHOME/data
ARG LC_ALL=C.UTF-8
ARG LANG=C.UTF-8

FROM postgres:$PG_MAJOR as builder

ARG PGHOME
ARG PGDATA
ARG LC_ALL
ARG LANG

ENV ETCDVERSION=2.3.8 CONFDVERSION=0.16.0

RUN set -ex \
    && export DEBIAN_FRONTEND=noninteractive \
    && echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    # postgres:10 is based on debian, which has the patroni package. We will install all required dependencies
    && apt-cache depends patroni | sed -n -e 's/.*Depends: \(python3-.\+\)$/\1/p' \
            | grep -Ev '^python3-(sphinx|etcd|consul|kazoo|kubernetes)' \
            | xargs apt-get install -y net-tools vim curl pgbackrest cron iputils-ping locales sudo \
                            python3-pip busybox \
    && pip3 install dumb-init patroni[consul] \
\
    # Cleanup all locales but en_US.UTF-8
    && find /usr/share/i18n/charmaps/ -type f ! -name UTF-8.gz -delete \
    && find /usr/share/i18n/locales/ -type f ! -name en_US ! -name en_GB ! -name i18n ! -name iso14651_t1 ! -name iso14651_t1_common ! -name 'translit_*' -delete \
    && echo 'en_US.UTF-8 UTF-8' > /usr/share/i18n/SUPPORTED \
\
    # Make sure we have a en_US.UTF-8 locale available
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
\
    # Prepare postgres/patroni/haproxy environment
    && mkdir -p $PGHOME/.config/patroni /patroni \
    && ln -s ../../postgres1.yml $PGHOME/.config/patroni/patronictl.yaml \
    && sed -i "s|/var/lib/postgresql.*|$PGHOME:/bin/bash|" /etc/passwd \
    && chown -R postgres:postgres /var/log \
\
    # Clean up all useless packages and some files
    && apt-get purge -y --allow-remove-essential python3-pip gzip bzip2 util-linux e2fsprogs \
                libmagic1 bsdmainutils login ncurses-bin libmagic-mgc e2fslibs bsdutils \
                exim4-config gnupg-agent dirmngr libpython2.7-stdlib libpython2.7-minimal \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
        /root/.cache \
        /var/cache/debconf/* \
        /etc/rc?.d \
        /etc/systemd \
        /docker-entrypoint* \
        /sbin/pam* \
        /sbin/swap* \
        /sbin/unix* \
        /usr/local/bin/gosu \
        /usr/sbin/[acgipr]* \
        /usr/sbin/*user* \
        /usr/share/doc* \
        /usr/share/man \
        /usr/share/info \
        /usr/share/i18n/locales/translit_hangul \
        /usr/share/locale/?? \
        /usr/share/locale/??_?? \
        /usr/share/postgresql/*/man \
        /usr/share/postgresql-common/pg_wrapper \
        /usr/share/vim/vim80/doc \
        /usr/share/vim/vim80/lang \
        /usr/share/vim/vim80/tutor \
        /var/lib/dpkg/info/* \
    && find /usr/bin -xtype l -delete \
    && find /var/log -type f -exec truncate --size 0 {} \; \
    && find /usr/lib/python3/dist-packages -name '*test*' | xargs rm -fr \
    && find /lib/x86_64-linux-gnu/security -type f ! -name pam_env.so ! -name pam_permit.so ! -name pam_unix.so -delete

# perform compression if it is necessary
ARG COMPRESS
RUN if [ "$COMPRESS" = "true" ]; then \
        set -ex \
        # Allow certain sudo commands from postgres
        && echo 'postgres ALL=(ALL) NOPASSWD: /bin/tar xpJf /a.tar.xz -C /, /bin/rm /a.tar.xz, /bin/ln -snf dash /bin/sh' >> /etc/sudoers \
        && ln -snf busybox /bin/sh \
        && files="/bin/sh /usr/bin/sudo /usr/lib/sudo/sudoers.so /lib/x86_64-linux-gnu/security/pam_*.so" \
        && libs="$(ldd $files | awk '{print $3;}' | grep '^/' | sort -u) /lib/x86_64-linux-gnu/ld-linux-x86-64.so.* /lib/x86_64-linux-gnu/libnsl.so.* /lib/x86_64-linux-gnu/libnss_compat.so.*" \
        && (echo /var/run $files $libs | tr ' ' '\n' && realpath $files $libs) | sort -u | sed 's/^\///' > /exclude \
        && find /etc/alternatives -xtype l -delete \
        && save_dirs="usr lib var bin sbin etc/ssl etc/init.d etc/alternatives etc/apt" \
        && XZ_OPT=-e9v tar -X /exclude -cpJf a.tar.xz $save_dirs \
        # we call "cat /exclude" to avoid including files from the $save_dirs that are also among
        # the exceptions listed in the /exclude, as "uniq -u" eliminates all non-unique lines.
        # By calling "cat /exclude" a second time we guarantee that there will be at least two lines
        # for each exception and therefore they will be excluded from the output passed to 'rm'.
        && /bin/busybox sh -c "(find $save_dirs -not -type d && cat /exclude /exclude && echo exclude) | sort | uniq -u | xargs /bin/busybox rm" \
        && /bin/busybox --install -s \
        && /bin/busybox sh -c "find $save_dirs -type d -depth -exec rmdir -p {} \; 2> /dev/null"; \
    fi

RUN apt-get update -y && apt-get install -y unzip wget make gcc postgresql-server-dev-10 libc6-dev

ARG POWA=/opt/powa
ARG POWA_VERSION=REL_3_2_0
ARG POWA_UNPACK=powa-archivist-REL_3_2_0
RUN set -ex \
    && mkdir $POWA \
    && wget https://github.com/powa-team/powa-archivist/archive/$POWA_VERSION.zip \
    && unzip /$POWA_VERSION.zip -d $POWA \
    && make --directory=$POWA/$POWA_UNPACK \
    && make --directory=$POWA/$POWA_UNPACK install

ARG PG_QUALSTATS=/opt/pg_qualstats
ARG PG_QUALSTATS_VERSION=1.0.7
ARG PG_QUALSTATS_UNPACK=pg_qualstats-1.0.7
RUN set -ex \
    && mkdir $PG_QUALSTATS \
    && wget https://github.com/powa-team/pg_qualstats/archive/$PG_QUALSTATS_VERSION.zip \
    && unzip /$PG_QUALSTATS_VERSION.zip -d $PG_QUALSTATS \
    && make --directory=$PG_QUALSTATS/$PG_QUALSTATS_UNPACK \
    && make --directory=$PG_QUALSTATS/$PG_QUALSTATS_UNPACK install

ARG PG_STAT_KCACHE=/opt/pg_stat_kcache
ARG PG_STAT_KCACHE_VERSION=REL2_1_1
ARG PG_STAT_KCACHE_UNPACK=pg_stat_kcache-REL2_1_1
RUN set -ex \
    && mkdir $PG_STAT_KCACHE \
    && wget https://github.com/powa-team/pg_stat_kcache/archive/$PG_STAT_KCACHE_VERSION.zip \
    && unzip /$PG_STAT_KCACHE_VERSION.zip -d $PG_STAT_KCACHE \
    && make --directory=$PG_STAT_KCACHE/$PG_STAT_KCACHE_UNPACK \
    && make --directory=$PG_STAT_KCACHE/$PG_STAT_KCACHE_UNPACK install

ARG HYPOPG=/opt/hypopg
ARG HYPOPG_VERSION=1.1.2
ARG HYPOPG_UNPACK=hypopg-1.1.2
RUN set -ex \
    && mkdir $HYPOPG \
    && wget https://github.com/HypoPG/hypopg/archive/$HYPOPG_VERSION.zip \
    && unzip /$HYPOPG_VERSION.zip -d $HYPOPG \
    && make --directory=$HYPOPG/$HYPOPG_UNPACK \
    && make --directory=$HYPOPG/$HYPOPG_UNPACK install

ARG PG_WAIT_SAMLPING=/opt/pg_wait_sampling
ARG PG_WAIT_SAMLPING_VERSION=v1.1
ARG PG_WAIT_SAMLPING_UNPACK=pg_wait_sampling-1.1
RUN set -ex \
    && mkdir $PG_WAIT_SAMLPING \
    && wget https://github.com/postgrespro/pg_wait_sampling/archive/$PG_WAIT_SAMLPING_VERSION.zip \
    && unzip /$PG_WAIT_SAMLPING_VERSION.zip -d $PG_WAIT_SAMLPING \
    && make --directory=$PG_WAIT_SAMLPING/$PG_WAIT_SAMLPING_UNPACK USE_PGXS=1 \
    && make --directory=$PG_WAIT_SAMLPING/$PG_WAIT_SAMLPING_UNPACK USE_PGXS=1 install 

RUN mkdir /etc/pgbackrest \
    && mv /etc/pgbackrest.conf /etc/pgbackrest/ \
    && chown -R postgres:postgres /etc/pgbackrest \
    && mkdir /home/postgres/backup \
    && mkdir /home/postgres/backup/postgres \
    && chown -R postgres:postgres /home/postgres/backup \
    && chmod -R 750 /home/postgres/backup

FROM scratch
COPY --from=builder / /

LABEL maintainer="Vladislav Radin, Oleg Bukatchuk"

ARG PG_MAJOR
ARG COMPRESS
ARG PGHOME
ARG PGDATA
ARG LC_ALL
ARG LANG

ARG PGBIN=/usr/lib/postgresql/$PG_MAJOR/bin

ENV LC_ALL=$LC_ALL LANG=$LANG EDITOR=/usr/bin/editor
ENV PGDATA=$PGDATA PATH=$PATH:$PGBIN

COPY postgres1.yml $PGHOME/
COPY entrypoint.sh /
COPY stanza-init.sh /home/postgres/
RUN chmod +x /home/postgres/stanza-init.sh

WORKDIR $PGHOME

RUN if [ "$COMPRESS" = "true" ]; then chmod u+s /usr/bin/sudo; fi \
    && chmod -R 700 $PGHOME \
    && chown -R postgres:postgres $PGHOME /run

USER postgres

EXPOSE 5432

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
