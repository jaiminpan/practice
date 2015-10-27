#!/usr/bin/env python
# -*- coding: utf-8 -*-

import urllib
import urllib2
import time
import hashlib

import sys, datetime
import logging, logging.config

import psycopg2 as dbdriver
import psycopg2.extensions as dbext

baseurl = "http://requestb.in/1h3wlup1?"

appkey = ""
SecretKey = ""
accid = 0

def RetriveInfo(baseurl, barcode):

	values = {'code' : barcode}
	data = urllib.urlencode(values)

	timestamp = time.time()

	url = baseurl + data

	key = appkey + str(timestamp) + str(accid) + SecretKey
	signature = hashlib.md5(key).hexdigest()

	headers = {'appkey' : appkey,
				'timestamp' : timestamp,
				'accid' : accid,
				'signature' : signature
			}
	req = urllib2.Request(url, None, headers)
	response = urllib2.urlopen(req)
	return response.read()

def usage(cmd):
	print cmd + "SQL Filter Clause"
	print "example: "
	print "Python %s 'id BETWEEN 1 and 10'" % cmd

if __name__ == '__main__':

	if len(sys.argv) != 2:
		usage(sys.argv[0])

		sys.exit(0)

	logging.config.fileConfig("logging.conf")
	logger = logging.getLogger()

	logger.info("===============START==================") 

	baseSrcStr = "select gid, accid, gbarcode from barcode2 where "

	sourceStr = baseSrcStr + sys.argv[1] + ";"
	logger.info(sourceStr)

	conn = dbdriver.connect('dbname=barcode user=jaimin password=asdf1234')
	conn.set_isolation_level(dbext.ISOLATION_LEVEL_AUTOCOMMIT)
	cursor = conn.cursor()
	cursor.execute(sourceStr)

	conn2 = dbdriver.connect('dbname=barcode user=jaimin password=asdf1234')
	conn2.set_isolation_level(dbext.ISOLATION_LEVEL_AUTOCOMMIT)
	cursor2 = conn2.cursor()
	#inst_sql = "INSERT INTO standardcode(gid, accid, barcode, content) VALUES(%s, %s, %s, %s)"
	inst_sql = "SELECT goodinsert(%s, %s, %s, %s)"
	for row in cursor.fetchall():
		gid, accid, code = row

		try:
			page = RetriveInfo(baseurl, code)
		except Exception, ex:
			logger.error(("%s, %s, %s") % (gid, accid, code))
			logger.error(ex)
			continue
#		print page
		strpage = (gid, accid, code, str(page))
		cursor2.execute(inst_sql, strpage)
		time.sleep(0.2)

	cursor.close()
	cursor2.close()

	logger.info("==================END==================") 

"""
CREATE OR REPLACE FUNCTION goodinsert(fgid int, faccid int, fbarcode text, fcontent text) RETURNS INT AS 
$$
BEGIN
	if (EXISTS(SELECT * FROM standardcode WHERE gid=fgid)) THEN
		RETURN 0;
	ELSE
		INSERT INTO standardcode(gid, accid, barcode, content) VALUES (fgid, faccid, fbarcode, fcontent);
		RETURN 1; 
	END IF;
END;
$$ LANGUAGE PLPGSQL;

"""
