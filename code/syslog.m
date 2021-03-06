extern CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();

#import <sys/socket.h>
#import <sys/un.h>

#import <unistd.h>
#import <fcntl.h>
#import <poll.h>

#define SOCKET_PATH "/var/run/lockdown/syslog.sock"

size_t atomicio(ssize_t (*f) (int, void *, size_t), int fd, void *_s, size_t n)
{
  char *s = _s;
  size_t pos = 0;
  ssize_t res;
  struct pollfd pfd;

  pfd.fd = fd;
  pfd.events = f == read ? POLLIN : POLLOUT;
  while (n > pos) {
    res = (f) (fd, s + pos, n - pos);
    switch (res) {
    case -1:
      if (errno == EINTR)
        continue;
      if ((errno == EAGAIN) || (errno == ENOBUFS)) {
        (void)poll(&pfd, 1, -1);
        continue;
      }
      return 0;
    case 0:
      errno = EPIPE;
      return pos;
    default:
      pos += (size_t)res;
    }
  }
  return (pos);
}

int unix_connect(char* path) {
  struct sockaddr_un sun;
  int s;

  if ((s = socket(AF_UNIX, SOCK_STREAM, 0)) < 0)
    return (-1);
  (void)fcntl(s, F_SETFD, 1);

  memset(&sun, 0, sizeof(struct sockaddr_un));
  sun.sun_family = AF_UNIX;

  if (strlcpy(sun.sun_path, path, sizeof(sun.sun_path)) >= sizeof(sun.sun_path)) {
    close(s);
    errno = ENAMETOOLONG;
    return (-1);
  }
  if (connect(s, (struct sockaddr *)&sun, SUN_LEN(&sun)) < 0) {
    close(s);
    return (-1);
  }

  return (s);
}

ssize_t write_colored(int fd, void* buffer, size_t len) {
  char *escapedBuffer = malloc(len + 1);
  memcpy(escapedBuffer, buffer, len);
  escapedBuffer[len] = '\0';

  NSString *str = [NSString stringWithUTF8String:escapedBuffer];

  NSDictionary *original = @{@"message":str};
  CFDictionaryRef dict = (__bridge CFDictionaryRef)original;
  CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
                                       CFSTR("com.syslogWindow.syslogMethodCallback"),
                                       NULL,dict,YES);

  free(escapedBuffer);
  return len;
}


int startTheSyslogThingy() {

  int nfd = unix_connect(SOCKET_PATH);

  // write "watch" command to socket to begin receiving messages
  write(nfd, "watch\n", 6);

  struct pollfd pfd[2];
  unsigned char buf[16384];
  int n = fileno(stdin);
  int lfd = fileno(stdout);
  int plen = 16384;

  pfd[0].fd = nfd;
  pfd[0].events = POLLIN;

  while (pfd[0].fd != -1) {

    if ((n = poll(pfd, 1, -1)) < 0) {
      close(nfd);
      perror("polling error");
      exit(1);
    }

    if (pfd[0].revents & POLLIN) {
      if ((n = read(nfd, buf, plen)) < 0)
        perror("read error"), exit(1); /* possibly not an error, just disconnection */
      else if (n == 0) {
        shutdown(nfd, SHUT_RD);
        pfd[0].fd = -1;
        pfd[0].events = 0;
      } else {
        if (atomicio(write_colored, lfd, buf, n) != n)
          perror("atomicio failure"), exit(1);
      }
    }
  }

  return 0;
}