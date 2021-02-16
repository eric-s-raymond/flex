#!/bin/sh
#
# testmaker.sh - asssemble tests from backend-independent rulesets and
# backend-dependent boilerplate.  Generates both a Flex source file
# and an input text for it.
#
# The single argument is a testfile name to be generated.
# With the -d option, dump to stdourather than crating the file.
#
# To add a new back end named "foo", append "|foo" to the
# string literal below.

if [ "$1" = -d ] ; then
    shift
    outdev=/dev/stdout
    # shellcheck disable=2209
    filter=cat
else
    outdev="$1"
    # shellcheck disable=2209
    filter=m4
fi

testfile=$1

trap 'rm -f /tmp/testmaker$$' EXIT INT QUIT

# we do want word splitting, so we won't put double quotes around it
# shellcheck disable=2046
set $(echo "${testfile}" | tr '.' ' ')
for last; do :; done
if [ "$(echo "${last}" | cut -c1-2)" = "1" ]
then
    echo "$0: Don't know how to make anything but a .l file: ${last}" >&2
    exit 1
fi

# ditto
# shellcheck disable=2046
set -- $(echo "${1}" | tr '_' ' ')
stem=$1
options=""
backend=nr
for part in "$@"; do
    case ${part} in
        nr) backend=nr; ;;
        r) backend=r; options="${options} reentrant";;
        c99|go|rust) backend=${part}; options="${options} emit=\"${part}\"" ;;	# Add new back ends on this line
        ser) serialization=yes ;;
        ver) serialization=yes; verification=yes; options="${options} tables-verify" ;;
	Ca) options="${options} align" ;;
	Ce) options="${options} ecs" ;;
	Cf) options="${options} full" ;;
	CxF|Cxf) options="${options} fast" ;;
	Cm) options="${options} meta-ecs";;
	Cem) options="${options} ecs meta-ecs" ;;
	Cae) options="${options} align ecs" ;;
	Caef) options="${options} align ecs full" ;;
	CaexF|Caexf) options="${options} algin ecs fast" ;;
	Cam) options="${options} align meta-ecs" ;;
	Caem) options="${options} align ecs meta-ecs" ;;
    esac
done
# Special case: C99 back end uses same boilerplate as reentrant C.
case ${backend} in c99) backend=r ;; esac

m4def() {
    define="${1}"
    value="${2}"
    # we'll be careful, I promise
    printf "define(\`%s', \`${value}')dnl\n" "${define}"
}

(
    m4def M4_TEST_BACKEND "${backend}"
    if [ -n "${verification}" ] ; then
        m4def M4_TEST_TABLE_VERIFICATION
    fi
    if [ -n "${serialization}" ] ; then
        options="${options} tables-file=\"${testfile%.l}.tables\""
        m4def M4_TEST_TABLE_SERIALIZATION
    fi
    if [ -z "${options}" ] ; then
        m4def M4_TEST_OPTIONS
    else
        m4def M4_TEST_OPTIONS "%%option${options}\n"
    fi
    cat testmaker.m4
    echo "M4_TEST_PREAMBLE\`'dnl"
    echo "M4_TEST_OPTIONS\`'dnl"
    sed <"${stem}.rules" -e "/###/Q0"
    echo "%%"
    echo "M4_TEST_POSTAMBLE\`'dnl"
) | "${filter}" >"${outdev}"

if [ "${outdev}" != /dev/stdout ] && [ ! -f "${stem}.txt" ]
then
    sed <"${stem}.rules" -e "1,/###/d" >"${stem}.txt"
fi

# end
