#!/bin/bash

APP=etcd
GROUP=root
USER=root
HOME=/opt/$APP
SYSD=/etc/systemd/system
ETCDSERV=etcd.service
ETCDKPSERV=etcdkeeper.service

init() {
  egrep "^$GROUP" /etc/group >/dev/null
  if [[ $? -ne 0 ]]; then
    groupadd -r $GROUP
  fi

  egrep "^$USER" /etc/passwd >/dev/null
  if [[ $? -ne 0 ]]; then
    useradd -r -g $GROUP -s /usr/sbin/nologin -M $USER
  fi

  if [[ ! -d $HOME/data ]]; then
    mkdir -p $HOME/data/wal
    chmod 700 $HOME/data
  fi

  chown -R $USER:$GROUP $HOME

  if [[ ! -s $SYSD/$ETCDSERV ]]; then
    ln -s $HOME/setup/$ETCDSERV $SYSD/$ETCDSERV
    systemctl enable $ETCDSERV
    echo "($APP) create symlink: $SYSD/$ETCDSERV --> $HOME/setup/$ETCDSERV"
  fi

  if [[ ! -s $SYSD/$ETCDKPSERV ]]; then
    ln -s $HOME/setup/$ETCDKPSERV $SYSD/$ETCDKPSERV
    systemctl enable $ETCDKPSERV
    echo "($APP) create symlink: $SYSD/$ETCDKPSERV --> $HOME/setup/$ETCDKPSERV"
  fi

  systemctl daemon-reload
}

deinit() {
  if [[ -s $SYSD/$ETCDSERV ]]; then
    systemctl disable $ETCDSERV
    rm -rf $SYSD/$ETCDSERV
    echo "($APP) delete symlink: $SYSD/$ETCDSERV"
  fi

  systemctl daemon-reload
}

start() {
  pgrep -x etcd >/dev/null
  if [[ $? != 0 ]]; then
    systemctl start $ETCDSERV
    echo "($APP) etcd start!"
  fi
  show
}

stop() {
  pgrep -x etcd >/dev/null
  if [[ $? == 0 ]]; then
    systemctl stop $ETCDSERV
    echo "($APP) etcd stop!"
  fi
  show
}

show() {
  ps -ef | grep $APP | grep -v 'grep'
}

case "$1" in
  init) init ;;
  deinit) deinit ;;
  start) start ;;
  stop) stop ;;
  show) show ;;
  *) SCRIPTNAME="${0##*/}"
     echo "Usage: $SCRIPTNAME {init|deinit|start|stop|show}"
     exit 3
     ;;
esac

exit 0

# vim: syntax=sh ts=4 sw=4 sts=4 sr noet
