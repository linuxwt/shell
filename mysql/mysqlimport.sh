#!/bin/bash

# 变量设定
dbname="$1"
Host="$2"
port="$3"
username2="$4"
password2="$5"
container_name="$6"
yingshe_dir="$7"


# 获取mysql安全目录
secure_dir=$(docker exec ${container_name} mysql -u${username2} -p${password2} -e "show variables like '%secure%';" | grep 'priv' | awk '{print $2}')

# 获取要导入的表名
table_name=$(ls ${yingshe_dir}/${dbname} | grep txt$ | awk -F '.' '{print $1}')

# 创建导入日志
touch ${yingshe_dir}/${dbname}/import.log
LOG="${yingshe_dir}/${dbname}/import.log"
# 导入开始时间
TIME1=$(date +%Y%m%d_%R)

# 循环导入每一个表的结构和数据
table_array=(${table_name})
for table in ${table_array[@]}
do
# 导入表结构
mysql -u ${username2} -h ${Host}  -p${password2} -P ${port} ${dbname} <  ${yingshe_dir}/${dbname}/${table}.sql
# 导入表数据
docker exec ${container_name} mysql -u${username2} -p${password2} -e "use ${dbname};LOAD DATA INFILE '${secure_dir}/${dbname}/${table}.txt' INTO TABLE ${table} FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'  LINES TERMINATED BY '\n';"
done

# 导入时间计算
if [ $? -eq  0 ];then
    TIME2=$(date +%Y%m%d_%R)

    echo " ${TIME1} start to import.   Mysql database import Success at ${TIME2} " >> $LOG
else
    TIME2=$(date +%Y%m%d_%R)
    echo " ${TIME1} start to import.   Mysql database import Fail.Please check it. time: ${TIME2} " >>$LOG
    exit 1;
fi