IFNDEF ERRNO_H
DEFINE ERRNO_H

DEFC EPERM        =  1 ; Operation not permitted.
DEFC ENOENT       =  2 ; No such file or directory.
DEFC EINTR        =  3 ; Interrupted system call.
DEFC EIO          =  4 ; Input/output error.
DEFC ENXIO        =  5 ; No such device or address.
DEFC EBADF        =  6 ; Bad file descriptor.
DEFC ENOMEM       =  7 ; Cannot allocate memory.
DEFC EACCES       =  8 ; Permission denied.
DEFC EFAULT       =  9 ; Bad address.
DEFC ENOTBLK      = 10 ; Block device required.
DEFC EBUSY        = 11 ; Device or resource busy.
DEFC EEXIST       = 12 ; File exists.
DEFC ENODEV       = 13 ; No such device.
DEFC ENOTDIR      = 14 ; Not a directory.
DEFC EISDIR       = 15 ; Is a directory.
DEFC EINVAL       = 16 ; Invalid argument.
DEFC EMFILE       = 17 ; Too many open files.
DEFC ENFILE       = 18 ; Too many open files in system.
DEFC ENOTTY       = 19 ; Inappropriate ioctl for device.
DEFC EFBIG        = 20 ; File too large.
DEFC ENOSPC       = 21 ; No space left on device.
DEFC ESPIPE       = 22 ; Illegal seek.
DEFC EROFS        = 23 ; Read-only file system.
DEFC EDOM         = 24 ; Numerical argument out of domain.
DEFC ERANGE       = 25 ; Numerical result out of range.
DEFC EAGAIN       = 26 ; Resource temporarily unavailable.
DEFC EWOULDBLOCK  = 27 ; Operation would block.
DEFC EINPROGRESS  = 28 ; Operation now in progress.
DEFC EALREADY     = 29 ; Operation already in progress.
DEFC ENAMETOOLONG = 30 ; File name too long.
DEFC ENOTEMPTY    = 31 ; Directory not empty.
DEFC EFTYPE       = 32 ; Inappropriate file type or format.
DEFC ENOSYS       = 33 ; Function not implemented.
DEFC ENOTSUP      = 34 ; Not supported.
DEFC ENOMSG       = 35 ; No message of desired type.
DEFC EOVERFLOW    = 36 ; Value too large for defined data type.
DEFC ETIME        = 37 ; Timer expired.
DEFC ECANCELED    = 38 ; Operation canceled.
DEFC EBADFD       = 39 ; File descriptor in bad state.

ENDIF