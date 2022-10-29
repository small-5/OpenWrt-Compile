CC=gcc

CFLAGS+=$(FLAGS) -Wall -Wextra

OBJS=curl.c

all: curl

curl: $(OBJS)
	$(CC) $(OBJS) $(CFLAGS) -o curl
