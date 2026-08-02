#include "CanBusBackend.h"
#include <QDebug>
#include <QThread>
#include <QObject>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <unistd.h>
#include <linux/can.h>
#include <linux/can/raw.h>


