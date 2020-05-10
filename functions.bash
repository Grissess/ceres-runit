# NB: This is bash syntax, but it is NOT an executable script; don't put a
# shebang here.

# The envvars produced by Exherbo's eclectic script eventually end up here; you
# might have to do something else to get your system's variables.
. /etc/environment
# Provide SVDIR explicitly so that it ends up available in (supervised) user
# shells, and sv can use it:
export SVDIR

# A directory in a tmpfs (or other transient store) for our exclusive purposes:
RUNDIR=/run/runit

# Like echo, but make a colorful header (cyan by default)
hdr() {
	echo -ne "\x1b[1;36m* $* \x1b[0m"
}

# Like echo, but write out a phase name (in cyan, with lots of equals signs)
phase() {
	echo -e "\x1b[1;36m====================" "$@" "====================\x1b[0m"
}

# Echo out that the last action was successful (echo "[OK]" in green right now)
ok() {
	echo -e "\x1b[1;32m[OK]\x1b[0m"
}

# do ok, then run hdr on the arguments
hdr_ok() {
	ok
	hdr "$@"
}

# Indicate a critical failure, echoing arguments, then drop into the emergency
# shell (a root shell started directly by init for rescuing a system).
#
# Don't use this in a service!
crit() {
	echo -e "\x1b[1;31m! $*\nDropping into emergency shell...\x1b[0m"
	chpst -P /bin/bash --noprofile --rcfile /root/trusted/bashrc -i
}

# Begin a critical part of startup/shutdown; if an error occurs here, crit is
# automatically invoked.
#
# Critical sections can't be nested; starting and stopping one are idempotent.
begin_crit() {
	trap 'crit "Attempted to exit in critical section"' EXIT
}

# End a critical section.
end_crit() {
	trap - EXIT
}

# Get the parameter name of a service; this is the part of the name past a dash
# (-) in the service directory name by convention.
#
# Most often, these directories are symlinks to hidden directories, set up by
# the instantiate.sh script.
param() {
	pwd | sed -e 's/.*-//'
}

# Output a message with a standardized format, logging the name of the service.
# Depending on whether or not the "standard log" service is on the service's
# stdout/stderr, this might go to that log, or to /dev/console.
log_msg() {
	echo -e "\x1b[1;36m[$(daemon_name)]\x1b[0m" "$@"
}

# Indicate that the service named "$1" is up. This name can be anything, and
# not necessarily related to the runit service name, though $(daemon_name) is a
# reasonable choice.
#
# After indicating this, check_up "$1" will succeed until indicate_down is
# used.
indicate_up() {
	mkdir -p "$RUNDIR"
	touch "$RUNDIR/$1"
}

# Indicate that the service named "$1" is down, the opposite of indicate_up.
#
# After indicating this, check_up "$1" will fail until indicate_up is used.
indicate_down() {
	mkdir -p "$RUNDIR"
	rm "$RUNDIR/$1"
}

# Succeeds if "$1" has been indicate_up'd (and not indicate_down'd meantime),
# fails otherwise.
check_up() {
	[ -f "$RUNDIR/$1" ]
}

# Exits the script with the status of check_up "$1"; useful as a one-liner in
# ./check runit scripts.
check_up_and_exit() {
	if check_up "$@"; then
		exit 0
	else
		exit 1
	fi
}

# Helper for needs/wants; handles actually starting the runit service "$1".
#
# If ./disabled is present in the service directory, this exits with failure.
#
# If ./down is present (indicating runsv shouldn't start it immediately), a
# warning is issued, but it is started.
#
# The default is to wait up to 15 seconds for the service to start. At present,
# this is hardcoded, but easy to find and change.
depends_on() {
	log_msg "Bringing up dependent $1..."
	if [ -e /etc/runit/sv/$1/disabled ]; then
		log_msg "Dependent $1 \x1b[1;31mis disabled.\x1b[0m"
		return 1;
	fi
	if [ -e /etc/runit/sv/$1/down ]; then
		log_msg "Dependent $1 \x1b[1;33mis normally down, but being brought up as a dependent.\x1b[0m"
	fi
	if sv -w 15 u $1; then
		log_msg "Dependent $1 is \x1b[1;32mup\x1b[0m."
		return 0;
	else
		log_msg "Dependent $1 \x1b[1;31mfailed to start!\x1b[0m."
		return 1;
	fi
}

# Runs depends_on "$1"; if it fails, brings down this service.
needs() {
	if ! depends_on "$@" ; then
		log_msg "\x1b[1;31mDown for dependency failure.\x1b[0m"
		printf 'd' > supervise/control
	fi
}

# Runs depends_on "$1"; if it fails, prints a warning, but continues.
wants() {
	if ! depends_on "$@" ; then
		log_msg "\x1b[1;33mWanted service failed, but continuing.\x1b[0m"
	fi
}

# Much like depends_on "$1", but brings down a conflicting runit service by
# name.
#
# Like depends_on, this has a hard-coded 15 second wait timeout.
conflicts_with() {
	log_msg "Stopping conflicting service $1..."
	if sv -w 15 d $1; then
		log_msg "Conflicter $1 is \x1b[1;31mdown\x1b[m."
		return 0;
	else
		log_msg "Conflicter $1 \x1b[1;31mcould not be brought down.\x1b[m."
		return 1;
	fi
}

# Like needs, runs conflicts_with "$1"; if it fails, brings this service down.
conflicts() {
	if ! conflicts_with "$@"; then
		log_msg "\x1b[1;31mDown for dependency failure.\x1b[m"
		printf 'd' > supervise/control
	fi
}

# Like wants, runs conflicts_with "$1"; if it fails, warns but continues.
wants_down() {
	if ! conflicts_with "$@"; then
		log_msg "\x1b[1;33mWanted down service failed, but continuing.\x1b[m"
	fi
}

# Guess if we're running in a daemon context by looking at our working
# directory; succeeds if our best guess is that this is a daemon.
is_daemon() {
	case $(pwd) in
		/etc/runit/sv/*/log) true ;;
		/etc/runit/sv/*) true ;;
		*) false ;;
	esac
}

# The name of the runit service for which we are supposedly a daemon.
#
# This is likely the name of one of the service directories, or a service
# directory with "/log" appended for the logging service.
#
# If we can't find out if we're in service context, this is just the full
# working directory name.
#
# Prints the name to stdout, often to capture in $().
daemon_name() {
	case $(pwd) in
		/etc/runit/sv/*/log) echo "$(basename $(dirname $(pwd)))/log" ;;
		/etc/runit/sv/*) basename $(pwd) ;;
		*) pwd ;;
	esac
}

# Determines if, within the context of /etc/runit/3, we will reboot or shutdown
# at the end of stage 3, using the same logic as runit.
is_rebooting() {
	[ -x /etc/runit/reboot ]
}

# Sets whether or not to reboot or shutdown at the end of stage 3. This is
# likely to be overwritten by the init tool, but can be used from within stage
# 3, for example; runit checks only once 3 exits.
set_rebooting() {
	touch /etc/runit/reboot
	chmod 100 /etc/runit/reboot
}

# Shutdown instead of rebooting. See above.
set_not_rebooting() {
	touch /tec/runit/reboot
	chmod 0 /etc/runit/reboot
}

# Begin either a shutdown or reboot, terminating stage 2. This will eventually
# terminate all services.
trigger_stage_3() {
	touch /etc/runit/stopit
	chmod 100 /etc/runit/stopit
	kill -CONT 1
}

# As root, shut down the system. Effectively init 0.
do_shutdown() {
	set_not_rebooting
	trigger_stage_3
}

# As root, reboot. Effectively init 6.
do_restart() {
	set_rebooting
	trigger_stage_3
}

# Since we're loaded in virtually all daemon ./run scripts, this is a good time
# to announce our presence to the loggers:
if is_daemon; then
	log_msg "Starting..."
fi
