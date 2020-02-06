#!/bin/bash

######################################################################################
### constants
######################################################################################
readonly ENV_VAR_DNS_DOMAIN_NAME='DNS_DOMAIN_NAME'
readonly ENV_VAR_UNBOUND_THREADS_NUM='THREADS_NUM'

readonly DEFAULT_UNBOUND_PORT=853
readonly DEFAULT_UNBOUND_SSL_PATH='/etc/unbound/ssl/'
readonly DEFAULT_UNBOUND_THREADS_NUM='2'

readonly PATH_BIN_UNBOUND='/usr/sbin/unbound'
readonly PATH_BIN_WGET='/usr/bin/wget'
readonly PATH_BIN_SED='/bin/sed'
readonly PATH_BIN_UNBOUND_CKECKCONF='/usr/sbin/unbound-checkconf'
readonly PATH_BIN_USERADD='/usr/sbin/useradd'
readonly PATH_BIN_DIG='/usr/bin/dig'
readonly PATH_BIN_NETSTAT='/bin/netstat'

readonly PATH_FILE_ETC_UNBOUND_UNBOUND_CONF='/etc/unbound/unbound.conf'
readonly PATH_FILE_ETC_UNBOUND_ROOT_HISTS='/etc/unbound/root.hints'
readonly PATH_FILE_ETC_UNBOUND_SSL_SERVICE_KEY_KEY='/etc/unbound/ssl/ssl-service-key.key'
readonly PATH_FILE_ETC_UNBOUND_SSL_SERVICE_PEM_PEM='/etc/unbound/ssl/ssl-service-pem.pem'

readonly URL_DOMAIN_NAMED_CACHE='https://www.internic.net/domain/named.cache'


######################################################################################
### string utils
######################################################################################

toupper() {

  echo "$1" | awk '{ print toupper($0) }'
}


######################################################################################
### logging
######################################################################################

log() {

  echo "----> $1"
}

log_warning() {

  log "WARNING: $1"
}

log_error() {

  log ''
  log "ERROR: $1"
  log ''
}

log_header() {

  echo "
==================================================================
      $(toupper "$1")
=================================================================="
}

######################################################################################
### error handling
######################################################################################

bail() {

  log_error "$1"
  exit 1
}

on_failure() {

  # shellcheck disable=SC2181
  if [[ $? -eq 0 ]]; then
    return
  fi

  case "$1" in
    warn)
      log_warning "$2"
      ;;
    stop)
      log_error "$2"
      stop
      ;;
    *)
      bail "$2"
      ;;
  esac
}

######################################################################################
### runtime environment detection
######################################################################################

is_domain_env_set() {
    if [[ -n "$ENV_VAR_DNS_DOMAIN_NAME" ]]; then 
        return 0;
    else
        return 1;
    fi
}

is_threads_num_env_set(){
    if [[ -n "$ENV_VAR_UNBOUND_THREADS_NUM" ]]; then 
        UNBOUND_THREADS_NUM=$DEFAULT_UNBOUND_THREADS_NUM
    else
        UNBOUND_THREADS_NUM=$ENV_VAR_UNBOUND_THREADS_NUM
    fi
}

is_granted_linux_capability() {

  if capsh --print | grep -Eq "^Current: = .*,?${1}(,|$)"; then
    return 0
  fi

  return 1
}

######################################################################################
### runtime configuration assertions
######################################################################################

assert_file_provided() {

  if [[ ! -f "$1" ]]; then
    bail "please provide $1 to the container"
  fi
}

######################################################################################
### initialization
######################################################################################

init_runtime_assertions() {

    if ! is_granted_linux_capability 'cap_sys_admin'; then
        bail 'missing CAP_SYS_ADMIN. be sure to run this image with --cap-add SYS_ADMIN or --privileged'
    fi

    if ! is_domain_env_set; then
        bail 'missing DNS_DOMAIN_NAME. be sure to run this image with -e DNS_DOMAIN_NAME=your_dns_domain_name.'
    fi

    assert_file_provided "$PATH_FILE_ETC_UNBOUND_SSL_SERVICE_KEY_KEY"
    assert_file_provided "$PATH_FILE_ETC_UNBOUND_SSL_SERVICE_PEM_PEM"
    assert_file_provided "$PATH_FILE_ETC_UNBOUND_UNBOUND_CONF"
}

init_unbound_conf_file(){
    log_header "initing unbound configure file ..."
    $PATH_BIN_SED -i "s/your_dns_domain_name/$DNS_DOMAIN_NAME/g" $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF
    on_failure bail "initing unbound configure file failure!"
    log "init unbound configure file success"
}

init_root_hints_file(){
    log_header "initing root hints file ..."
    $PATH_BIN_WGET -c $URL_DOMAIN_NAMED_CACHE -O $PATH_FILE_ETC_UNBOUND_ROOT_HISTS
    on_failure bail "initing root hints file failure!"
    log "init root hints file success!"
}

init_unbound_user(){
    log_header "adding user unbound ..."
    $PATH_BIN_USERADD unbound
    on_failure "add user unbound failure!"
    log "add uesr unbound success!"
}

init_unbound_threads(){
    log_header "set unbound threads num conf ..."
    is_threads_num_env_set
    $PATH_BIN_SED -i "/num-threads:/c \ \ \ \ num-threads: $UNBOUND_THREADS_NUM"  $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF
    on_failure "set unbound threads num conf failure!"
    log "set unbound threads num conf success!"
}

init_trap() {
  trap stop SIGTERM SIGINT
}

######################################################################################
### process control
######################################################################################

term_process() {

  local -r base=$(basename "$1")
  local -r pid=$(pidof "$base")

  if [[ -n $pid ]]; then
    log "terminating $base"
    kill "$pid"
    on_failure warn "unable to terminate $base"
  else
    log "$base was not running"
  fi
}

######################################################################################
### teardown
######################################################################################

stop() {

    log_header 'terminating ...'

    term_process "$PATH_BIN_UNBOUND"

    log_header 'terminated'

    exit 0
}


######################################################################################
### test configure
######################################################################################

unbound_checkconf(){
    log_header "checking unbound configure $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF ..."
    $PATH_BIN_UNBOUND_CKECKCONF 
    on_failure bail "configure file can't pass check!"
    log "no errors in unbound configure file $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF "
}

######################################################################################
### boot
######################################################################################

boot(){
    log_header 'booting unbound ...'
    $PATH_BIN_UNBOUND
    on_failure bail "cann't start unbound!"
    log 'unbound already started!'
}

######################################################################################
### print run status
######################################################################################

print_unbound_status(){
    log_header 'unbound is running ...'
    $PATH_BIN_NETSTAT -ntlp
    $PATH_BIN_DIG google.com @127.0.0.1 -p 853
}

print_unbound_conf(){
    log_header "cat $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF"
    cat $PATH_FILE_ETC_UNBOUND_UNBOUND_CONF
}

######################################################################################
### main routines
######################################################################################

init() {
    log_header 'setting up ...'
    init_runtime_assertions
    init_unbound_conf_file
    init_root_hints_file
    init_unbound_user
    init_unbound_threads
    init_trap
    log 'setup complete'
    print_unbound_conf
}

hangout() {

    log_header 'ready and waiting for client connections'

    # wait forever or until we get SIGTERM or SIGINT
    # https://stackoverflow.com/a/41655546/229920
    # https://stackoverflow.com/a/27694965/229920
    while :; do sleep 2073600 & wait; done
}

main() {

    init
    unbound_checkconf
    boot
    print_unbound_status
    hangout
}

main

