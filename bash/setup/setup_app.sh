#!/usr/bin/env bash

function ShowEnvVars ()
{
    echo "PYTHON_HOME     = ${PYTHON_HOME}"
    echo "MYSQL_HOME      = ${MYSQL_HOME}"
    echo "BIGODATA_HOME   = ${BIGODATA_HOME}"
}

function ErrEnvVars ()
{
    echo "ERROR: $1"

    ShowEnvVars
}

if [ -z "$PYTHON_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit
fi

if [ -z "$MYSQL_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit
fi

if [ -z "$BIGODATA_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit
fi

function app_check ()
{
    file_list=("$BIGODATA_HOME/tg_bigodata"
             "$BIGODATA_HOME/bigodata_cmd"
             )

    declare -a nofiles
    for item in ${file_list[@]}; do
        if [ ! -d "$item" ]; then
            nofiles[${#nofiles[@]}]=$item
        fi
    done

    if [ ${#nofiles[@]} -ne 0 ]; then
        echo "ERROR: following ${#nofiles[@]} directorys not exists"
        for item in ${nofiles[@]}; do
            echo "$item"
        done
        exit 1
    fi
}

function app_install ()
{
    TMPVAR=/usr/bin/python2.7
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists"
    else
        ln -s $PYTHON_HOME/bin/python2.7 $TMPVAR
    fi

    TMPVAR=/usr/lib64/libmysqlclient.so.18
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists"
    else
        ln -s $MYSQL_HOME/lib/libmysqlclient.so.18 $TMPVAR
    fi
}

function app_uninstall ()
{
    TMPVAR=/usr/bin/python2.7
    if [ -e "$TMPVAR" ]; then
        echo "\"$TMPVAR\" exists, please check if it should remove"
    fi

    TMPVAR=/usr/lib64/libmysqlclient.so.18
    if [ -e "$TMPVAR" ]; then
        echo "\"$TMPVAR\" exists, please check if it should remove"
    fi
}

function app_autostart ()
{
    $PYTHON_HOME/bin/supervisord -c $BIGODATA_HOME/tg_bigodata/conf/supervisord.conf

    TMPVAR=`cat /etc/rc.d/rc.local | grep 'bigodata_cmd/init_soft'`
    if [ -z "$TMPVAR" ]; then
        echo "sh $BIGODATA_HOME/bigodata_cmd/init_soft.sh" >> /etc/rc.d/rc.local
    else
        echo "WARNING: \"$TMPVAR\" already exists"
    fi
}

function app_clean ()
{
    sed -i '/bigodata_cmd[/]init_soft.sh/d' /etc/rc.d/rc.local
}

function app_status ()
{
    echo "APP: "
    TMPVAR=`cat /etc/rc.d/rc.local | grep 'bigodata_cmd/init_soft'`
    if [ -z "$TMPVAR" ]; then
        echo "autostart not set"
   else
        echo "autostart already set"
    fi
}

case $1 in
  install)
        echo -n "install app: "
        app_check
        app_install
        echo "ok"
        ;;
  init)
        echo -n "initilize app: "
        echo "ok"
        ;;
  autostart)
        echo -n "autostart app: "
        app_autostart
        echo "ok"
        ;;
  uninstall)
        echo -n "uninstall app: "
        app_uninstall
        echo "ok"
        ;;
  clean)
        echo -n "clean app: "
        app_clean
        echo "ok"
        ;;
  check)
        echo -n "check app: "
        app_check
        echo "ok"
        ;;
  status)
        app_status
        ;;
  verbose)
        ShowEnvVars
        ;;
  *)
        # Print help
        echo "Usage: $0 {install|init|autostart|uninstall|clean|check|status|verbose}" 1>&2
        exit 1
        ;;
esac
