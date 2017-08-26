# mysql_backup

docker image for backuping/restoring mysql databases

To backup:

```
docker run --rm -it -v $(pwd)/backup:/backup mysql-backup backup \
      --keep_files 3
      --user test
      --password test123
      --database testdb
      --host 127.0.0.1
      --backup_file testdb.sql
```

To restore:

```
docker run --rm -it -v $(pwd)/backup:/backup mysql-backup restore \
      --user test
      --password test123
      --database testdb
      --host 127.0.0.1
      --backup_file testdb.sql

```
