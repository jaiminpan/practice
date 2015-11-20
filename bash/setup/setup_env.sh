#!/usr/bin/env bash

function ShowEnvVars ()
{
    echo "PYTHON_HOME     = ${PYTHON_HOME}"
    echo "CURL_HOME       = ${CURL_HOME}"
    echo "SPAW_HOME       = ${SPAW_HOME}"
    echo "MEMCACHED_HOME  = ${MEMCACHED_HOME}"
    echo "NGINX_HOME      = ${NGINX_HOME}"
    echo "FREETDS_HOME    = ${FREETDS_HOME}"
    echo "ORACLE_LIB      = ${ORACLE_LIB}"
    echo "R_HOME          = ${R_HOME}"
}

function ErrEnvVars ()
{
    echo "ERROR: $1"

    ShowEnvVars
}

if [ -z "$PYTHON_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$CURL_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$SPAW_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$MEMCACHED_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$NGINX_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$FREETDS_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$ORACLE_LIB" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$R_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

function env_check ()
{
    file_list=("$PYTHON_HOME"
             "$CURL_HOME"
             "$SPAW_HOME"
             "$MEMCACHED_HOME"
             "$NGINX_HOME"
             "$ORACLE_LIB"
             "$R_HOME"
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

function env_install_yum ()
{
    echo "yum install (y|n)"

    while read ANSWER
    do
        if [ "$ANSWER" = "y" ]; then
            break
        fi

        if [ "$ANSWER" = "n" ]; then
            return
        fi

        echo "yum install (y|n)"
    done

    yum -y install lrzsz
    yum -y install gcc gcc-c++
    yum -y install libaio-dev*
    yum -y install libevent-devel
    yum -y install libgfortran
}

function env_generate ()
{
    TMPFILE=`mktemp`
    echo "
export BIGODATA_HOME=$BIGODATA_HOME
export PYTHON_HOME=$PYTHON_HOME
export CURL_HOME=$CURL_HOME
export SPAW_HOME=$SPAW_HOME
export MEMCACHED_HOME=$MEMCACHED_HOME
export NGINX_HOME=$NGINX_HOME
export FREETDS_HOME=$FREETDS_HOME

export ORACLE_LIB=$ORACLE_LIB
export R_HOME=$R_HOME
" >> $TMPFILE

    echo '
PATH=$PYTHON_HOME/bin:$SPAW_HOME/bin:$MEMCACHED_HOME/bin:$NGINX_HOME/sbin:$R_HOME:$PATH
LD_LIBRARY_PATH=$CURL_HOME/lib:$FREETDS_HOME/lib:$ORACLE_LIB:$LD_LIBRARY_PATH

export PATH
export LD_LIBRARY_PATH
' >> $TMPFILE
    chmod 666 $TMPFILE
    echo "please check \"$TMPFILE\" for env"
}

function env_install ()
{
    env_install_yum

    TMPVAR=`cat /etc/security/limits.conf | grep 'bigodata soft nofile'`
    if [ -z "$TMPVAR" ]; then
        echo "bigodata soft nofile 102400" >> /etc/security/limits.conf
        echo "bigodata hard nofile 102400" >> /etc/security/limits.conf
    else
        echo "WARNING: \"$TMPVAR\" already exists"
    fi

    env_generate
}

function env_uninstall ()
{
    sed -i '/bigodata .* nofile/d' /etc/security/limits.conf
}

function env_status ()
{
    echo "Env: "
    TMPVAR=`cat /etc/security/limits.conf | grep 'bigodata * nofile'`
    if [ ! -z "$TMPVAR" ]; then
        echo "$TMPVAR"
    else
        echo "open files handlers not set"
        TMPVAR=`ulimit -a | grep 'open files'`
        echo "default is $TMPVAR"
    fi
}

case $1 in
  install)
        echo -n "install env: "
        env_check
        env_install
        echo "ok"
        ;;
  init)
        echo -n "initilize env: "
        echo "ok"
        ;;
  autostart)
        echo -n "autostart env: "
        echo "ok"
        ;;
  uninstall)
        echo -n "uninstall env: "
        env_uninstall
        echo "ok"
        ;;
  clean)
        echo -n "clean env: "
        echo "ok"
        ;;
  check)
        echo -n "check env: "
        env_check
        echo "ok"
        ;;
  status)
        env_status
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

