#!/bin/bash
localtext_zh_CN() {
	err_U="错误: 检索失败! 可能是脚本尚未支持此BIOS, 也可能是文件损坏或被加密, 亦或者手动指定了错误的BIOS解析模式"
	no_find="尚未安装 UEFIFind 工具, 请前往 https://github.com/LongSoft/UEFITool/releases 下载安装"
	no_ex="尚未安装 UEFIExtract 工具, 请前往 https://github.com/LongSoft/UEFITool/releases 下载安装"
	no_ifr="尚未安装 ifrextract 工具, 请前往 https://github.com/LongSoft/Universal-IFR-Extractor/releases 下载安装"
	finded="共检索到 %d 个项目, 其中 %d 个有效\n"
	need_file="错误: 参数过少, 请选择需要解析的 BIOS 文件"
	need_keyword="错误: 参数过少, 请输入要查询的关键词"
	vid="BIOS结构"
	user="指定模式"
	err_pam="错误: 错误的参数 -- %s , 请输入正确的模式\n\n"
	hp_v1="当前处于惠普模式, 若搜索\"DVMT\"无结果, 可尝试搜索\"Video memory size\"\nBIOS结构隶属"
	hp_v2="当前处于惠普模式, 若搜索\"DVMT\"无结果, 可尝试搜索\"Video memory size\"\n指定解析模式"
}
localtext_en_US() {
	err_U="Error: search failed! Unknown BIOS format, or file is corrupted."
	no_find="\"UEFIFind\" is not installed, see this link: https://github.com/LongSoft/UEFITool/releases"
	no_ex="\"UEFIExtract\" is not installed, see this link: https://github.com/LongSoft/UEFITool/releases"
	no_ifr="\"ifrextract\" is not installed, see this link: https://github.com/LongSoft/Universal-IFR-Extractor/releases"
	finded="%d items found, %d valid\n"
	need_file="Error: please enter the BIOS file path."
	need_keyword="Error: please enter keywords to search."
	vid="Vendor"
	user="Specified"
	err_pam="Error: illegal parameter -- %d\n\n"
	hp_v1="For the HP BIOS, if you want to search for \"DVMT\", please change to \"Video memory size\"\nVendor:"
	hp_v2="For the HP BIOS, if you want to search for \"DVMT\", please change to \"Video memory size\"\nSpecified:"
}
help_zh_CN() {
	echo "此脚本用于从BIOS固件文件中查找包含指定名称的设置项及其各选项的ID值"
	echo "用法: set_dump BIOS文件路径 [关键词(不分大小写)/功能] [解析模式(不填默认为a)]"
	echo "例如: set_dump ROM.fd DVMT"
	echo "功能: L: 列出所有设置项"
	echo "模式: a: 自动探测模式"
	echo "      m: AMI模式"
	echo "      i: Insyde模式"
	echo "      h: 惠普模式"
}
help_en_US() {
	echo "set_dump: find the ID of each setting item and its options from BIOS file"
	echo "usage: set_dump file keyword [mode(Default: a)]"
	echo "modes: a: auto detection"
	echo "       m: AMI mode"
	echo "       i: Insyde mode"
	echo "       h: HP mode"
	echo "e.g. : set_dump ROM.fd DVMT"
	echo "       set_dump ROM.fd L"
	echo "       if keyword is \"L\", the script will list all the settings"
}
search() {
    echo "========================================"
	word=$(printf "${2}"|xxd -ps|sed 's/../&00/g'|sed 's/00$//g')
	chk=$(UEFIExtract "${1}" $GUID -o UExt -m body)
	if [[ x"$chk" =~ "parse:" || x"$chk" =~ "failed with" || ! -e UExt ]];then
		echo $err_U
	else
		body=$(du -h UExt/*|sort -rh|head -n 1|grep -o "UExt.*")
		ifrextract "${body}" UExt/dump.txt >/dev/null
		if [ x"${2}" = x"L" ];then
            
			perl -e 'while (<>){print if (/One Of:/i../End One Of/i);}' UExt/dump.txt > UExt/temp.txt
			cat UExt/temp.txt|grep -Eo "One Of:[^,]+"|sed 's/One Of: //g;s/ /_/g'|tr '_' ' '|sort -u
		else
		perl -e 'while (<>){print if (/One Of:.*'"${2}"'/i../End One Of/i);}' UExt/dump.txt > UExt/temp.txt
		opt=($(cat UExt/temp.txt|grep -Eo "One Of:[^,]+"|sed 's/One Of: //g;s/ /_/g'))
		key=($(cat UExt/temp.txt|grep -Eo "One Of:[^:]+: 0x[^,{}]+, VarStore"|grep -Eo "0x[^,]+"))
		val=($(cat UExt/temp.txt|grep -Eo "One Of Option: [^{]+{|End One Of"|sed 's/One Of Option: //g;s/, Value ([^)]*): /:/g;s/End One Of/@/g;s/ {/\\n___/g;s/ /_/g'|tr -d '\n'|tr '@' '\n'))
		nul=0
		for ii in "${!key[@]}"
		do
        if [ x"${key[$ii]}" = x"0x0" ];then
            let nul++
            continue
        fi
        if [ x"${key[$ii]}" = x"${keyl}" ];then
            let nul++
            keyl="${key[$ii]}"
            continue
        fi
        keyl="${key[$ii]}"
		echo "${opt[$ii]} : ${key[$ii]}"|tr '_' ' '
		echo -e "   ${val[$ii]}"|tr '_' ' '|sort -rh|column -t -s ":"
		echo "========================================"
		done
		printf "$finded" "${#key[@]}" "$((${#key[@]} - $nul))"
		fi
	fi
}
if [ x"$(uname)" = xDarwin ];then
err=0
rm -rf UExt 2>/dev/null
lang=$(osascript -e 'user locale of (get system info)')
if [ x"$lang" = x"zh_CN" ];then
	localtext_zh_CN
	help=help_zh_CN
else
	localtext_en_US
	help=help_en_US
fi
if [ "$(UEFIFind 2>/dev/null;echo $?)" = "127" ];then
	echo $no_find
	err=1
fi
if [ "$(UEFIExtract 2>/dev/null;echo $?)" = "127" ];then
	echo $no_ex
	err=1
fi
if [ "$(ifrextract 2>/dev/null;echo $?)" = "127" ];then
	echo $no_ifr
	err=1
fi
if [ "$err" != "1" ];then
	if [ ! "${1}" ];then
		echo $need_file
		echo
		eval $help
		err=1
	elif [ ! "${2}" ];then
		echo $need_keyword
		echo
		eval $help
		err=1
	else
		if [ ! "${3}" -o x"${3}" = x"a" ];then
			ami=$(UEFIFind "${1}" all count 414D495453455365747570)
			h2o=$(UEFIFind "${1}" all count 49006e0073007900640065)
			if [ 0"$ami" -gt 0 ];then
				GUID="899407D7-99FE-43D8-9A21-79EC328CAC21"
				arch="AMI"
				text=$vid
			elif [ 0"$h2o" -gt 0 ];then
				GUID="FE3542FE-C1D3-4EF8-657C-8048606FF670"
				arch="Insyde"
				text=$vid
			else
				bios=$(UEFIFind "${1}" all count 56006900640065006f0020006d0065006d006f00720079002000730069007a0065)
				if [ 0"$bios" -gt 0 ];then
					GUID=$(UEFIFind "${1}" all list 56006900640065006f0020006d0065006d006f00720079002000730069007a0065|head -n1)
					arch="HP BIOS"
                    if [ $(echo "${2}"|grep -i dvmt|wc -l) -gt 0 ];then
                        text=$hp_v1
                    else
                        text=$vid
                    fi
				else
					GUID=$(UEFIFind "${1}" all list 440056004d0054|head -n 1)
					arch="unkonw"
					text=$vid
					if [ ! "${GUID}" ];then
						echo $err_U
						err=1
					fi
				fi
			fi
		else
			if [ x"${3}" = x"m" ];then
				GUID="899407D7-99FE-43D8-9A21-79EC328CAC21"
				arch="AMI"
				text=$user
			elif [ x"${3}" = x"i" ];then
				GUID="FE3542FE-C1D3-4EF8-657C-8048606FF670"
				arch="Insyde"
				text=$user
			elif [ x"${3}" = x"h" ];then
				GUID=$(UEFIFind "${1}" all list 56006900640065006f0020006d0065006d006f00720079002000730069007a0065|head -n1)
				arch="HP BIOS"
                if [ $(echo "${2}"|grep -i dvmt|wc -l) -gt 0 ];then
                    text=$hp_v2
                else
                    text=$user
                fi
			else
				printf "$err_pam" "${3}"
				eval $help
				err=1
			fi
		fi
	fi
fi
if [ x"$err" != x"1" ];then
	echo -e "${text}: $arch"
	search "${1}" "${2}"
fi
rm -rf UExt 2>/dev/null
else
	echo "请在 macOS 系统中使用此脚本"
	echo "Please run this script on macOS"
fi