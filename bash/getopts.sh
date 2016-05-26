#!/bin/bash
# 该脚本转自http://www.bsdmap.com/2011/06/28/bash-getopts/, 稍作修改
# 更多参考:
# Small getopts tutorial - http://wiki.bash-hackers.org/howto/getopts_tutorial
# Bash Shell中命令行选项/参数处理 - http://www.cnblogs.com/FrankTan/archive/2010/03/01/1634516.html
# Bash里使用getopts解析非选项参数 - \
# http://blog.yegle.net/2011/04/21/parsing-non-option-argument-bash-getopts/
# 使用getopt传递脚本选项参数 - http://www.linuxfly.org/post/168/

usage() {
    cat << -EOF-
Usage:
$0 -I interface -i ipaddr

-EOF-
    exit 1
}

while getopts “I:i:” opt ; do
    case $opt in
        I)
            interface=$OPTARG
            ;;
        i)
            ip=$OPTARG
            ;;
        ?) usage
            ;;
    esac
done

if [[ -z "$interface" || -z "$ip" ]] ; then
    usage
else
    ifconfig $interface | grep -iE "${ip}\b"
fi

#下面的脚本是Emacs 的Shell-script 模式Optinos loop[C-c C-o] 生成的:
while getopts :"o:t:" OPT; do
    case $OPT in
	"|+")
	    
	    ;;
	o|+o)
	    "$OPTARG"
	    ;;
	t|+t)
	    "$OPTARG"
	    ;;
	"|+")
	    
	    ;;
	*)
	    echo "usage: `basename $0` [+-"o ARG] [+-t ARG] [+-"} [--] ARGS..."
		exit 2
    esac
done
shift `expr $OPTIND - 1`
OPTIND=1
# Optinos loop[C-c C-o] 生成的脚本结束


exit $?
