
#### Example
```
archive_command = 'test ! -f $pgpath/backup_in_progress || (test ! -f $pgpath/archive/%f && cp %p $pgpath/archive/%f)'

archive_command = 'test ! -f $pgpath/archive_active || cp %p $pgpath/%f'

archive_command = 'mkdir -p $pgpath/xlog_archive/$(date +%Y%m%d) && test ! -f $pgpath/xlog_archive/$(date +%Y%m%d)/%f.zip && zip -r $pgpath/xlog/_archive/$(date +%Y%m%d)/%f.zip %p'
```

#### Compressed Archive Logs
You will then need to use gunzip and pg_decompresslog during recovery:

```
archive_command = 'pg_compresslog %p - | gzip > /var/lib/pgsql/archive/%f'

restore_command = 'gunzip < /mnt/server/archivedir/%f | pg_decompresslog - %p'
```
