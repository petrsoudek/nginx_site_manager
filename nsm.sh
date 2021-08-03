#!/bin/bash
NGINX_CONF_FILE="$(awk -F= -v RS=' ' '/conf-path/ {print $2}' <<< $(nginx -V 2>&1))"
NGINX_CONF_DIR="${NGINX_CONF_FILE%/*}"
NGINX_SITES_AVAILABLE="$NGINX_CONF_DIR/sites-available"
NGINX_SITES_ENABLED="$NGINX_CONF_DIR/sites-enabled"
SELECTED_SITE="$2"

nginx_ensite() {
    [[ ! "$SELECTED_SITE" ]] &&
        ngx_select_site "not_enabled"

    [[ ! -e "$NGINX_SITES_AVAILABLE/$SELECTED_SITE" ]] && 
        ngx_error "Site does not appear to exist."
    [[ -e "$NGINX_SITES_ENABLED/$SELECTED_SITE" ]] &&
        ngx_error "Site appears to already be enabled"

    ln -sf "$NGINX_SITES_AVAILABLE/$SELECTED_SITE" -T "$NGINX_SITES_ENABLED/$SELECTED_SITE"
    ngx_reload
}

nginx_dissite() {
    [[ ! "$SELECTED_SITE" ]] &&
        ngx_select_site "is_enabled"

    [[ ! -e "$NGINX_SITES_AVAILABLE/$SELECTED_SITE" ]] &&
        ngx_error "Site does not appear to be \'available\'. - Not Removing"
    [[ ! -e "$NGINX_SITES_ENABLED/$SELECTED_SITE" ]] &&
        ngx_error "Site does not appear to be enabled."

    rm -f "$NGINX_SITES_ENABLED/$SELECTED_SITE"
    ngx_reload
}

ngx_list_site() {
    echo "Available sites:"
    ngx_sites "available"
    echo "Enabled Sites"
    ngx_sites "enabled"
}

ngx_select_site() {
    sites_avail=($NGINX_SITES_AVAILABLE/*)
    sa="${sites_avail[@]##*/}"
    sites_en=($NGINX_SITES_ENABLED/*)
    se="${sites_en[@]##*/}"

    case "$1" in
        not_enabled) sites=$(comm -13 <(printf "%s\n" $se) <(printf "%s\n" $sa));;
        is_enabled) sites=$(comm -12 <(printf "%s\n" $se) <(printf "%s\n" $sa));;
    esac

    ngx_prompt "$sites"
}

ngx_prompt() {
    sites=($1)
    i=0

    echo "SELECT A WEBSITE:"
    for site in ${sites[@]}; do
        echo -e "$i:\t${sites[$i]}"
        ((i++))
    done

    read -p "Enter number for website: " i
    SELECTED_SITE="${sites[$i]}"
}

ngx_sites() {
    case "$1" in
        available) dir="$NGINX_SITES_AVAILABLE";;
        enabled) dir="$NGINX_SITES_ENABLED";;
    esac

    for file in $dir/*; do
        echo -e "\t${file#*$dir/}"
    done
}

ngx_reload() {
    read -p "Would you like to reload the Nginx configuration now? (Y/n) " reload
    [[ "$reload" != "n" && "$reload" != "N" ]] && invoke-rc.d nginx reload
}

ngx_error() {
    echo -e "${0##*/}: ERROR: $1"
    [[ "$2" ]] && ngx_help
    exit 1
}

ngx_help() {
    echo "Usage: ${0##*/} [options]"
    echo "Options:"
    echo -e "\t<-e|--enable> <site>\tEnable site"
    echo -e "\t<-d|--disable> <site>\tDisable site"
    echo -e "\t<-l|--list>\t\tList sites"
    echo -e "\t<-h|--help>\t\tDisplay help"
    echo -e "\n\tIf <site> is left out a selection of options will be presented."
    echo -e "\tIt is assumed you are using the default sites-enabled and"
    echo -e "\tsites-disabled located at $NGINX_CONF_DIR."
}

case "$1" in
    -e|--enable)    nginx_ensite;;
    -d|--disable)   nginx_dissite;;
    -l|--list)  ngx_list_site;;
    -h|--help)  ngx_help;;
    *)      ngx_error "No Options Selected" 1; ngx_help;;
esac
