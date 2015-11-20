#!/usr/bin/env bash

function ShowEnvVars ()
{
    echo "MYSQL_HOME     = ${MYSQL_HOME}"
    echo "MYSQL_DATA     = ${MYSQL_DATA}"
    echo "MYSQL_USER     = ${MYSQL_USER}"
}

function ErrEnvVars ()
{
    echo "ERROR: $1"

    ShowEnvVars
}

if [ -z "$MYSQL_HOME" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "$MYSQL_DATA" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "${MYSQL_USER}" ]; then
    MYSQL_USER=mysql
fi

function remove_old_mysql_libs
{
    #查看是否有历史版本：rpm -qa|grep mysql
    #删除以前版本：rpm -e mysql-libs-5.1.71-1.el6.x86_64 --nodeps
    TMPVAR=`rpm -qa|grep mysql`
    if [ ! -z "$TMPVAR" ]; then
        rpm -e $TMPVAR --nodeps
    fi
}

function mysql_check ()
{
    file_list=("$MYSQL_HOME"
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

function mysql_install ()
{
    TMPVAR=/etc/ld.so.conf.d/bigomysql-x86-64.conf
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists "
    else
        touch $TMPVAR
        echo "$MYSQL_HOME/lib" > $TMPVAR
        ldconfig
    fi
}

function mysql_uninstall ()
{
    TMPVAR=/etc/ld.so.conf.d/bigomysql-x86-64.conf
    rm -f $TMPVAR
    ldconfig
}

function mysql_adduser ()
{
    TMPVAR=`cat /etc/passwd | grep $MYSQL_USER`
    if [ ! -z "$TMPVAR" ]; then
        return 0
    fi

    echo "User \"$MYSQL_USER\" not exists"

    echo "Add User \"$MYSQL_USER\" for MySQL (y|n)"

    while read ANSWER
    do
        if [ "$ANSWER" = "y" ]; then
            break
        fi

        if [ "$ANSWER" = "n" ]; then
            exit 1
        fi

        echo "Add User \"$MYSQL_USER\" For MySQL (y|n)"
    done

    adduser $MYSQL_USER
}

function mysql_init ()
{
    mysql_adduser

    if [ -d "$MYSQL_DATA" ]; then
        echo "WARNING: \"$MYSQL_DATA\" already exists "
    else
        mkdir -p $MYSQL_DATA
        cp -rf $MYSQL_HOME/data/* $MYSQL_DATA
        chown -R $MYSQL_USER:$MYSQL_USER $MYSQL_DATA
        chmod 755 $MYSQL_DATA
    fi
}

function mysql_autostart ()
{
    mysql_adduser

    # actual usage
    TMPVAR=$MYSQL_HOME/my.cnf
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists "
    else
        cp -f $MYSQL_HOME/my.cnf.sample $TMPVAR
        sed -i "s:^\(datadir\s*=\).*:\1\"$MYSQL_DATA\":g" $TMPVAR
        chmod 644 $TMPVAR
    fi

    TMPVAR=/etc/init.d/mysql
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists "
    else
        TMPFILE=`mktemp`
        cat $MYSQL_HOME/mysql > $TMPFILE
        sed -i "s:^\(basedir=\).*:\1$MYSQL_HOME:g" $TMPFILE
        sed -i "s:^\(datadir=\).*:\1$MYSQL_DATA:g" $TMPFILE
        sed -i "s:^\(user=\).*:\1$MYSQL_USER:g" $TMPFILE
        chown root:root $TMPFILE
        chmod 755 $TMPFILE
        mv $TMPFILE $TMPVAR
    fi
    chkconfig --add mysql
    chkconfig mysql on
}

function mysql_clean ()
{
    TMPVAR=/etc/init.d/mysql
    if [ -e "$TMPVAR" ]; then
        chkconfig mysql off
        chkconfig --del mysql
        rm -f $TMPVAR
    fi

    if [ -d "$MYSQL_DATA" ]; then
        echo "DELETE $MYSQL_DATA (y|n)"
        while read ANSWER
        do
            if [ "$ANSWER" = "y" ]; then
                rm -rf $MYSQL_DATA
                break
            fi

            if [ "$ANSWER" = "n" ]; then
                break
            fi
            echo "DELETE $MYSQL_DATA (y|n)"
        done
    fi
}

function mysql_status ()
{
    echo -n "MySQL: "

    if [ -d "$MYSQL_DATA" ]; then
        echo "exists \"$MYSQL_DATA\""
    else
        echo "not exists \"$MYSQL_DATA\""
    fi

    TMPVAR=`service mysql status`
    if [ ! -z "$TMPVAR" ]; then
        echo "$TMPVAR"
    fi

    TMPVAR=`chkconfig --list | grep mysql`
    if [ ! -z "$TMPVAR" ]; then
        echo "$TMPVAR"
    fi
}

case $1 in
  install)
        echo -n "install MySQL: "
        mysql_check
        mysql_install
        echo "ok"
        ;;
  init)
        echo -n "initilize MySQL: "
        mysql_init
        echo "ok"
        ;;
  autostart)
        echo -n "autostart MySQL: "
        mysql_autostart
        echo "ok"
        ;;
  uninstall)
        echo -n "uninstall MySQL: "
        mysql_uninstall
        echo "ok"
        ;;
  clean)
        echo -n "clean MySQL: "
        mysql_clean
        echo "ok"
        ;;
  check)
        echo -n "check MySQL: "
        mysql_check
        echo "ok"
        ;;
  status)
        mysql_status
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

