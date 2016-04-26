#!/usr/bin/env python
# -*- coding: utf-8 -*-

import threading
import Queue
import time

isExit = False

class Consumer(threading.Thread):

    def __init__(self, tid, name, que, qlock, handler):
        threading.Thread.__init__(self)
        self.tid = tid
        self.name = name
        self.que = que
        self.qlock = qlock
        self.handler = handler
    def run(self):
        print "Starting " + self.name
        main_loop(self.name, self.que, self.qlock, self.handler)
        print "Exiting " + self.name

def main_loop(tname, que, qlock, handler):
    while not isExit:
        data = None
        if not que.empty():
            qlock.acquire()
            if not que.empty():
                data = que.get()
                qlock.release()

                try:
                    handler(tname, data)
                except:
                    print "error"
            else:
                qlock.release()
        else:
            time.sleep(1)

if __name__ == "__main__":

    threadList = ["Thread-1", "Thread-2", "Thread-3"]
    datList = ["One", "Two", "Three", "Four", "Five"]
    idx = 1
    threads = []

    workQueue = Queue.Queue(50)
    queLock = threading.Lock()

    # 创建新线程
    def just_print(name, data):
        print "%s processing %s" % (name, data)

    for tName in threadList:
        thread = Consumer(idx, tName, workQueue, queLock, just_print)
        thread.start()
        threads.append(thread)
        idx += 1

    # 填充队列
    queLock.acquire()
    for word in datList:
        workQueue.put(word)
    queLock.release()

    # 等待队列清空
    while not workQueue.empty():
        time.sleep(1)

    # 通知线程是时候退出
    isExit = True

    # 等待所有线程完成
    for t in threads:
        t.join()
    print "Exiting Main Thread"
