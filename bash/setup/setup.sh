#!/usr/bin/env bash

basepath=$(cd `dirname $0`; pwd)

function inexec ()
{
    sh $1
    ret=$?
    if [ $ret -ne 0 ]; then
        echo "Error $ret: $1"
        exit 1
    fi
}

case $1 in
  install)
        inexec "$basepath/setup_env.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_app.sh $1"
        ;;
  init)
        inexec "$basepath/setup_env.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_app.sh $1"
        ;;
  autostart)
        inexec "$basepath/setup_env.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_app.sh $1"
        ;;
  check)
        inexec "$basepath/setup_env.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_app.sh $1"
        ;;
  uninstall)
        inexec "$basepath/setup_app.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_env.sh $1"
        ;;
  clean)
        inexec "$basepath/setup_app.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_env.sh $1"
        ;;
  status)
        inexec "$basepath/setup_env.sh $1"
        echo
        inexec "$basepath/setup_mysql.sh $1"
        echo
        inexec "$basepath/setup_pg.sh $1"
        echo
        inexec "$basepath/setup_app.sh $1"
        ;;
  verbose)
        inexec "$basepath/setup_env.sh $1"
        inexec "$basepath/setup_mysql.sh $1"
        inexec "$basepath/setup_pg.sh $1"
        inexec "$basepath/setup_app.sh $1"
        ;;
  *)
        # Print help
        echo "Usage: $0 {install|init|autostart|uninstall|clean|check|status|verbose}" 1>&2
        exit 1
        ;;
esac
