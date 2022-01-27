#!/usr/bin/env bash

function scala_charts () {
    P="/Users/ewoutvonk/Projects/sdu/devops/sdu-helm-charts/charts" ; grep -l -e 'docker-logger.xml' -e 'startup.conf' -e 'include "application.conf"' ${P}/*/templates/*deployment*.yaml ${P}/*/templates/*configmap*.yaml | xargs -n1 -I{} dirname {} | xargs -n1 -I{} dirname {} | sort | uniq
}

function scala_charts_head () {
    scala_charts | grep -e "/${1}\$"
}

function scala_charts_tail () {
    scala_charts | grep -v -e "/${1}\$"
}

function transform_helmignore () {
    cat "$1"
}

function transform_chart () {
    cat "$1" | grep -v -e '^#' -e '^description:' -e '^\s*$' -e '^name:' -e '^appVersion:' -e '^version:' -e '^type:'
}
export -f transform_chart

function transform_values () {
    cat "$1" | grep -v -e '^#' | yq e -o json | jq '
                                                    .image.repository = "some-repository" |
                                                    .service.port = "some-port" |
                                                    .image.tag = "some-tag" |
                                                    del(.appConfig) |
                                                    del(.fluentd) |
                                                    del(.filebeat) |
                                                    del(.appName) |
                                                    .' | yq e -o yaml -P
}
export -f transform_values

function transform_template () {
    cat "$1" |
      grep -v -e '^#' |
      perl -p -e "s#$2#$3#g;" |
      perl -p -e "s#generic-helm-charts#$3#g;" |
      perl -p -e 's#(template ")([^"]+)(" \.)#include "$2$3#g;' |
      perl -p -e "s#nindent#indent#g;"
}
export -f transform_template

function transform_helpers () {
    cat "$1" |
      grep -v -e '^#' |
      perl -p -e "s#$2#$3#g;" |
      perl -p -e "s#generic-helm-charts#$3#g;"
}
export -f transform_helpers

function transform_configmap () {
    cat "$1" |
      grep -v -e '^#' |
      perl -p -e 's#^(  ([^\.]+\.[^\.]+): \|)#ENTRY$1#;' |
      awk 'BEGIN { nl="\n"; ORS=""; } { if($1=="ENTRY") { print "\n"; nl="%%NEWLIJN%%"; } ; print $0nl; } END { print "\n"; }' |
      perl -p -e "s#$2#$3#g;" |
      perl -p -e "s#generic-helm-charts#$3#g;" |
      perl -p -e 's#(template ")([^"]+)(" \.)#include "$2$3#g;' |
      perl -p -e "s#nindent#indent#g;"
}
export -f transform_configmap

function transform_diff_offsets () {
    cat - | perl -p -e 's#^@@\s*[-+]\d+(,\d+)?\s*[-+]\d+(,\d+)?\s*@@#@@ -X +Y @@#g;'
}
export -f transform_diff_offsets

function transform_timestamps () {
    cat - | perl -p -e 's#\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{9}\s+(\+\d{4}|Z|[A-Z]+)##g;'
}
export -f transform_timestamps

function escape_newlines () {
    cat - | perl -p -e 's#\n#%%NEWLINE%%#g;'
}
export -f escape_newlines

function unescape_newlines () {
    cat - | perl -p -e 's#%%NEWLINE%%#\n#g;'
}
export -f unescape_newlines

function handle_diff () {
    target="${4}/${3}"
    [ -e "$target" ] || target="${2}/${3}"
    diff -Nrupw <($1 $target $(basename "$4") some-chart-name 2>/dev/null) <($1 ${2}/${3} $(basename "$2") some-chart-name 2>/dev/null) | transform_diff_offsets | transform_timestamps | perl -p -e "s#^(---) [^\n]*#\$1 reference/$3#g; s#^(\+\+\+) [^\n]*#\$1 current/$3#;" | escape_newlines
}

function handle_diff_diff_single () {
    target="${4}/${3}"
    [ -e "$target" ] || target="${2}/${3}"
    diff -Nrupw <($1 $target $(basename "$4" -filebeat) some-chart-name 2>/dev/null) <($1 ${2}/${3} $(basename "$2") some-chart-name 2>/dev/null) | transform_diff_offsets | transform_timestamps | perl -p -e "s#^(---) [^\n]*#\$1 reference/$3#g; s#^(\+\+\+) [^\n]*#\$1 current/$3#;"
}

function handle_diff_diff () {
    refdiff="$(basename "$5")"
    curdiff="$(basename "$4")"
    diff -Nrupw <(handle_diff_diff_single "$1" "$2" "$3" "$5" 2>/dev/null) <(handle_diff_diff_single "$1" "$2" "$3" "$4" 2>/dev/null) | transform_diff_offsets | transform_timestamps | perl -p -e "s#^(---) [^\n]*#\$1 refdiff/$3#g; s#^(\+\+\+) [^\n]*#\$1 curdiff/$3#;" | escape_newlines
}

function handle () {
    refchart="${5:-cwc-adapter-bwb}"
    echo "${3} differences:"
    handle_diff "$1" "$2" "$3" "$(scala_charts_head $refchart)" | unescape_newlines | supercatdiff
    scala_charts_tail $refchart | while read T ; do
        handle_diff_diff "$1" "$2" "$3" "$T" "$(scala_charts_head $refchart)"
        echo
    done | grep -v -e '^\s*$' | sort | uniq | sort | while read line ; do
        echo "$line" | unescape_newlines | supercatdiff ;
    done
    if [ "$4" != "last" ] ; then
        echo
        echo
    fi
}

function all_templates () {
    ( cd ${1} ; find templates -iname "*.yaml" \! -name "configmap.yaml" ; )
}

function all_configmaps () {
    ( cd ${1} ; find templates -iname "*configmap*" ; )
}

export S="generic-scala-play-helm-chart"

# handle transform_helmignore "$S" ".helmignore"
# handle transform_chart "$S" "Chart.yaml"
handle transform_helpers "$S" "templates/_helpers.tpl"
# all_configmaps "$S" | while read templatefile ; do
#     handle transform_configmap "$S" "${templatefile}"
# done
# all_templates "$S" | while read templatefile ; do
#     handle transform_template "$S" "${templatefile}"
# done
# handle transform_values "$S" "values.yaml" last
