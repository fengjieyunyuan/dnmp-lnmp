#!/bin/sh

set timeout 60

read -p "📂文件夹名称:" FileName
read -p "🌐网站域名:" HostName
read -p "📖网站备注:" Remark

# ----------------------------------- PHP版本 ------------------------------------
# 配置基础目录
configPath='/Users/fengxiansheng/workspace/docker/dnmp/services/nginx/conf.d/php'

# 获取运行的PHP容器
list=$(docker ps --format "table {{.Names}}" --filter name=php)

# 获取容器名称
index=0
versionStr=''
phpVersion=()
for item in ${list[@]}
    do
      # 如果名称中存在 「 php 」,并且存在「 Nginx 」配置文件
      if [[ $item =~ 'php' && -f "$configPath/$item.conf" ]]; then
        versionStr="${versionStr} ${index}. ${item} \n"
        phpVersion+=($item)
        index=${index+1}
      fi
    done

echo "🐘PHP版本:
${versionStr}"
read -p "请输入版本对应数字 [0-${index}]:" version
if [[ $version -gt $index || $version -lt '0' ]]; then
  echo '版本错误'
  exit
fi
# ------------------------------------------------------------------------------

# 创建网站目录
if [ ! -d "/Users/fengxiansheng/workspace/web/$FileName" ];then
  mkdir /Users/fengxiansheng/workspace/web/$FileName
  echo "📂文件夹创建成功"
else
  echo "📂文件夹已经存在"
  exit
fi

# 创建 Nginx 配置
cd /Users/fengxiansheng/workspace/docker/dnmp/services/nginx/conf.d
cp ./default.conf.sample ./$HostName.conf
# 替换配置 这里的空双引号是为了避开命令的强制备份逻辑
sed -i "" "s/default.host/$HostName/g" $HostName.conf
sed -i "" "s/default.file/$FileName/g" $HostName.conf
sed -i "" "s/default.error/$HostName.error/g" $HostName.conf
sed -i "" "s/php.version/${phpVersion[version]}/g" $HostName.conf

# 如果hosts中不存在该域名，就将域名追加写入到Hosts文件
if ! cat '/etc/hosts' | grep "$HostName" >> /dev/null
then
  echo "127.0.0.1 $HostName #$Remark \n" >> /etc/hosts
else
  echo 'host中已存在相同域名,请注意清理'
fi
# 重启Docker NGINX 容器
cd /Users/fengxiansheng/workspace/docker/dnmp
docker-compose restart nginx

echo "🎉🎉🎉网站创建成功🎉🎉🎉"