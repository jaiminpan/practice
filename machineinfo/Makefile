
CC = gcc
RM = rm

all: getcpu geteth geteth2

getcpu: getcpu.c
	$(CC) -o $@ $^
	
geteth: getmac.c
	$(CC) -o $@ $^

geteth2: getmac2.c
	$(CC) -o $@ $^

clean:
	$(RM) getcpu geteth geteth2
