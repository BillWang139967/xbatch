#!/bin/bash
#########################################################################
# File Name: w.sh
# Author: meetbill
# mail: meetbill@163.com
# Last Time: 2017-10-16 23:30:11
#########################################################################

export LANG=zh_CN.UTF-8
g_DIR_CUR=`S=\`readlink "$0"\`; [ -z "$S"   ] && S=$0; dirname $S`
cd ${g_DIR_CUR}
g_DIR_PACK=${g_DIR_CUR}/Packages
g_DIR_XBATCH=${g_DIR_PACK}/X_batch
g_DIR_SOFT=${g_DIR_PACK}/soft
#{{{Check root 
if [ `id -u` -ne 0 ]
then
	echo "Must be as root install!"
	exit 1
fi
#}}}
echo  "Installing..."
DIR_INSTALL=/opt/X_operations/X_batch
DIR_CONF=/etc/xbatch
#{{{Python版本
function PythonVersion()
{

	cat <<EOFver|python
#coding:utf-8
import sys,time
ver=float(sys.version[:3])
if ver<=2.4:
	print "强烈警告! 您使用的python版本过低,建议升级python版本到2.6以上.\n可以使用yum update python更新"
	time.sleep(3)
EOFver
}
#}}}
#{{{InstallLocalYum
function InstallLocalYum()
{
	cd ${g_DIR_SOFT}
	YUM_BAK=/opt/yum_bak

	if [ -d ${YUM_BAK} ]
	then
		cp -rf /etc/yum.repos.d/* ${YUM_BAK}
	else
		mkdir -p ${YUM_BAK}
		cp -rf /etc/yum.repos.d/* ${YUM_BAK}
	fi
	
	rm -rf /etc/yum.repos.d/*
	cp ./xbatch.repo  /etc/yum.repos.d/
	tar -zxf packages_xbatch.tar.gz -C /opt
	return 0
}
#}}}
#{{{InstallTOOL
#
function InstallTOOL()
{
	rpm  -qa|grep gcc -q
	if  [ $? -ne 0 ]
	then
		yum  install -y gcc
	fi
	rpm  -qa|grep python-devel -q
	if [ $? -ne 0 ]
	then
		echo "install python-devel"
		yum install -y python-devel
	fi
	return 0
}
#}}}
#{{{InstalEnv
function InstalEnv()
{
cat<<EOFcrypto|python
import sys
try:
	import Crypto
except:
	sys.exit(1)
EOFcrypto
	if [ $? -ne 0 ]
	then
		echo "没有crypto，现在需要安装"
		cd ${g_DIR_SOFT}
		tar xf pycrypto-2.6.1.tar.gz
		cd pycrypto-2.6.1
		python setup.py  install
		if  [ $? -ne 0 ]
		then
			echo "安装pycropto失败，请检查系统是否有GCC编译环境,如果没有gcc环境，请安装: yum  install -y gcc "
			exit
		else
			echo "安装pycropto完成"
		fi
	fi
}
#}}}
#{{{RmLocalYum
function RmLocalYum()
{
	YUM_BAK=/opt/yum_bak
	rm -rf /etc/yum.repos.d/*
	cp -rf ${YUM_BAK}/* /etc/yum.repos.d/
	rm -rf ${YUM_BAK}
}
#}}}
#{{{InstallXbatch
function InstallXbatch()
{
	cd ${g_DIR_CUR}
    if [[ -d "/opt/X_operations/X_batch/" ]]
    then
        /bin/rm -rf /opt/X_operations/X_batch/
    fi
	mkdir -p ${DIR_INSTALL}
    mkdir -p ${DIR_CONF}
	cp -fr ./Packages/X_batch/* ${DIR_INSTALL} 2>/dev/null
    [[ ! -f "${DIR_CONF}/hosts" ]] && cp ./Packages/conf/hosts ${DIR_CONF}
    [[ ! -f "${DIR_CONF}/xbatch.conf" ]] && cp ./Packages/conf/xbatch.conf ${DIR_CONF}
    chmod 777 ${DIR_INSTALL}/xbatch.py
    if [[ -f "/usr/bin/xb" ]]
    then
        unlink /usr/bin/xb
        ln -s ${DIR_INSTALL}/xbatch.py /usr/bin/xb
    else
        ln -s ${DIR_INSTALL}/xbatch.py /usr/bin/xb
    fi
	touch ${DIR_INSTALL}/flag/installed
    echo "Install [OK] ,please config the hosts file(/etc/xbatch/hosts)"
	return 0
}
#}}}
# main
function main()
{
	PythonVersion
	InstallLocalYum
	InstallTOOL
	InstalEnv
	RmLocalYum
	InstallXbatch
}

if [ $# == 0 ];then
    echo "$0 --install_all/--install_only_xbatch"
else
    case $1 in
        --install_all)
            main
            ;;
        --install_only_xbatch)
            InstallXbatch
            ;;
        *)
            echo "$0 --install_all/--install_only_xbatch"
            exit 1
            ;;
    esac
fi
