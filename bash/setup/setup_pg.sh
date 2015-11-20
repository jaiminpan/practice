#!/usr/bin/env bash

function ShowEnvVars ()
{
    echo "PGSQL_HOME     = ${PGSQL_HOME}"
    echo "PGDATA         = ${PGDATA}"
    echo "PGUSER         = ${PGUSER}"
}

function ErrEnvVars ()
{
    echo "ERROR: $1"

    ShowEnvVars
}

if [ -z "${PGSQL_HOME}" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi

if [ -z "${PGDATA}" ]; then
    ErrEnvVars 'undefined variables'
    exit 1
fi


if [ -z "${PGUSER}" ]; then
    PGUSER=bigodata
fi


function pg_check ()
{
    file_list=("$PGSQL_HOME"
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

function pg_install ()
{
    TMPVAR=/etc/ld.so.conf.d/bigopg-x86-64.conf
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists "
    else
        touch $TMPVAR
        echo "$PGSQL_HOME/lib" > $TMPVAR
        ldconfig
    fi
}

function pg_uninstall ()
{
    TMPVAR=/etc/ld.so.conf.d/bigopg-x86-64.conf
    rm -f $TMPVAR
    ldconfig
}

function pg_adduser ()
{
    TMPVAR=`cat /etc/passwd | grep $PGUSER`
    if [ ! -z "$TMPVAR" ]; then
        return 0
    fi

    echo "User \"$PGUSER\" not exists"

    echo "Add User \"$PGUSER\" for PostgreSQL (y|n)"

    while read ANSWER
    do
        if [ "$ANSWER" = "y" ]; then
            break
        fi

        if [ "$ANSWER" = "n" ]; then
            exit 1
        fi

        echo "Add User \"$PGUSER\" for PostgreSQL (y|n)"
    done

    adduser $PGUSER
}

function pg_init ()
{
    pg_adduser

    if [ -d "$PGDATA" ]; then
        echo "WARNING: \"$PGDATA\" already exists "
    else
        mkdir -p $PGDATA
        cp -rf $PGSQL_HOME/data/postgres/* $PGDATA
        chown -R $PGUSER:$PGUSER $PGDATA
        chmod -R go-rwx $PGDATA
    fi
}

function pg_autostart ()
{
    pg_adduser

    TMPVAR=/etc/init.d/postgresql
    if [ -e "$TMPVAR" ]; then
        echo "WARNING: \"$TMPVAR\" already exists "
    else
        TMPFILE=`mktemp`
        cat $PGSQL_HOME/postgresql > $TMPFILE
        sed -i "s:^\(prefix=\).*:\1$PGSQL_HOME:g" $TMPFILE
        sed -i "s:^\(PGDATA=\).*:\1\"$PGDATA\":g" $TMPFILE
        sed -i "s:^\(PGUSER=\).*:\1$PGUSER:g" $TMPFILE
        # append PATH
        # sed -i '/^PATH=/a\PATH=$prefix/bin:$PATH' $TMPFILE
        chown root:root $TMPFILE
        chmod 755 $TMPFILE
        mv $TMPFILE $TMPVAR
    fi
    chkconfig --add postgresql
    chkconfig postgresql on
}

function pg_clean ()
{
    TMPVAR=/etc/init.d/postgresql
    if [ -e "$TMPVAR" ]; then
        chkconfig postgresql off
        chkconfig --del postgresql
        rm -f $TMPVAR
    fi

    if [ -d "$PGDATA" ]; then
        echo "DELETE $PGDATA (y|n)"
        while read ANSWER
        do
            if [ "$ANSWER" = "y" ]; then
                rm -rf $PGDATA
                break
            fi

            if [ "$ANSWER" = "n" ]; then
                break
            fi
            echo "DELETE $PGDATA (y|n)"
        done
    fi
}

function pg_status ()
{
    echo -n "PostgreSQL: "

    if [ -d "$PGDATA" ]; then
        echo "exists \"$PGDATA\""
    else
        echo "not exists \"$PGDATA\""
    fi

    TMPVAR=`service postgresql status`
    if [ ! -z "$TMPVAR" ]; then
        echo "$TMPVAR"
    fi

    TMPVAR=`chkconfig --list | grep postgresql`
    if [ ! -z "$TMPVAR" ]; then
        echo "$TMPVAR"
    fi
}

case $1 in
  install)
        echo -n "install PostgreSQL: "
        pg_check
        pg_install
        echo "ok"
        ;;
  init)
        echo -n "initilize PostgreSQL: "
        pg_init
        echo "ok"
        ;;
  autostart)
        echo -n "autostart PostgreSQL: "
        pg_autostart
        echo "ok"
        ;;
  uninstall)
        echo -n "uninstall PostgreSQL: "
        pg_uninstall
        echo "ok"
        ;;
  clean)
        echo -n "clean PostgreSQL: "
        pg_clean
        echo "ok"
        ;;
  check)
        echo -n "check PostgreSQL: "
        pg_check
        echo "ok"
        ;;
  status)
        pg_status
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
