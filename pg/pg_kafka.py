#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import getopt

import threading, time

import logging, logging.config

import psycopg2 as dbdriver
import psycopg2.extensions as dbext
import json

from kafka.client import KafkaClient
from kafka.consumer import SimpleConsumer

#日志配置文件名
LOG_CONFIG_FILENAME = 'logging.conf'

#日志语句提示信息
LOGIN_LOG_NAME = 'LOGIN'

def log_init(log_config_filename, logname):
	'''
	Function:日志模块初始化函数
	Input：log_config_filename:日志配置文件名
	       lognmae:每条日志前的提示语句
	Output: logger
	author: socrates
	date:2012-02-12
	'''
	logging.config.fileConfig(log_config_filename)
	logger = logging.getLogger(logname)
	return logger

class DBDriver:
	_logger = None
	_conn = None
	_cursor = None
	def __init__(self, logger):
		self._logger = logger

	def connect(self):
		self.close()

		conn = self._conn

		conn = dbdriver.connect('dbname=i200 user=jaimin password=asdf1234')
		# self._conn = dbdriver.connect('dbname=i200 host=192.168.20.122 user=jaimin password=asdf1234')
		conn.set_isolation_level(dbext.ISOLATION_LEVEL_AUTOCOMMIT)

		self._conn = conn

	def close(self):
		if self._conn is not None:
			self._conn.close()
			self._conn = None

	def reconnect(self):
		delay = 2
		while True:
			try:
				self.connect()
				break
			except Exception, ex:
				self._logger.error(ex)
				if delay < 60:
					delay *= 2
				self._logger.info("Wait %s secs to reconnect", delay)
				time.sleep(delay)

	def prepareInsert(self):
		self._cursor = self._conn.cursor()
		self._cursor.execute("prepare loginLogPlan as "
					"INSERT INTO t_log(logtype, operdate, account_user_id, loginfo, logmode, typeid, accountid, loginbrslast) "
					"VALUES($1, $2, $3, $4, $5, $6, $7, $8)")

	def doInsert(self, loginLogObj):
		res = True
		param = (loginLogObj['LogType'], loginLogObj['OperDate'], loginLogObj['Account_user_id'], loginLogObj['LogInfo'], loginLogObj['LogMode'], loginLogObj['TypeID'], loginLogObj['Accountid'], loginLogObj['Loginbrslast'],)

		try:
			self._cursor.execute("execute loginLogPlan (%s, %s, %s, %s, %s, %s, %s, %s)", param)
		except Exception, ex:
			self._logger.error(ex)
			res = False
			
		return res

	def finishPrepareInsert(self):
		self._cursor.close()
		self._cursor = None

	def insert(self, loginLogObj):

		inst_sql = 'INSERT INTO t_log(logtype, operdate, account_user_id, loginfo, logmode, typeid, accountid, loginbrslast) VALUES(%s, %s, %s, %s, %s, %s, %s, %s)'
		param = (loginLogObj['LogType'], loginLogObj['OperDate'], loginLogObj['Account_user_id'], loginLogObj['LogInfo'], loginLogObj['LogMode'], loginLogObj['TypeID'], loginLogObj['Accountid'], loginLogObj['Loginbrslast'],)

		cursor = self._conn.cursor()

		cursor.execute(inst_sql, param)

		# neet commit if not set autocommit
#		conn.commit()

#		for row in cursor.fetchall():
#			print 'result:', row
		cursor.close()

def myusage():
	print sys.argv[0], "-h hostname:port" 

if __name__ == '__main__': 
	host = "192.168.20.83:9092"
	topicName = "mykafka"
	debug = None

	try:
		opts, args = getopt.getopt(sys.argv[1:], "dh:e:t:", ["help", "execute="])
	except getopt.GetoptError:
		myusage()
		sys.exit(2)

	for opt, arg in opts:
		if opt == "--help":
			myusage()
			sys.exit()
		elif opt == "-h":
			host = arg
		elif opt == "-t":
			topicName = arg
		elif opt == "-d":
			debug = True

	if debug is not None:
		print "host : ", host
		print "topic : ", topicName
		sys.exit()

	login_logger = log_init(LOG_CONFIG_FILENAME, LOGIN_LOG_NAME)
	
	client = KafkaClient(host)
	consumer = SimpleConsumer(client, "pg-group", topicName)

	pgdb = DBDriver(login_logger)

	pgdb.connect()
	pgdb.prepareInsert()

	exit = False
	while not exit:
		try:
			for message in consumer:
				login_logger.debug(message)
				row = json.loads(message.message.value)

				while not pgdb.doInsert(row):
					pgdb.reconnect()
					pgdb.prepareInsert()
					# exit = True
					# break

		except Exception, ex:
			msgstr = Exception, ":", ex
			login_logger.error(msgstr)

	pgdb.finishPrepareInsert()
	pgdb.close()
:
