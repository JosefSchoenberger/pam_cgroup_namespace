#define _GNU_SOURCE
#include <sched.h>
#include <syslog.h>
#include <sys/mount.h>

#include <security/pam_modules.h>
#include <security/pam_ext.h>

#define LOG_NAME "pam_cgroup_namespace: "

int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
        (void)flags, (void)argc, (void)argv;
        if (unshare(CLONE_NEWNS | CLONE_NEWCGROUP)) {
                pam_syslog(pamh, LOG_ERR, LOG_NAME "could not unshare mount an cgroup namespace: %m");
                return PAM_SESSION_ERR;
        }

        // need to overmount with tmp-fs first, as the mount below will return EBUSY otherwise.
        if (mount("cgroup-tmp", "/sys/fs/cgroup", "tmpfs", 0, NULL)) {
                pam_syslog(pamh, LOG_ERR, LOG_NAME "could not overmount /sys/fs/cgroup with tmpfs: %m");
                return PAM_SESSION_ERR;
        }
        if (mount("cgroup2", "/sys/fs/cgroup", "cgroup2", 0, NULL)) {
                pam_syslog(pamh, LOG_ERR, LOG_NAME "could not remount /sys/fs/cgroup: %m");
                return PAM_SESSION_ERR;
        }
        return PAM_SUCCESS;
}
