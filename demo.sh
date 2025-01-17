#!/bin/bash -Eeu

export ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SH_DIR="${ROOT_DIR}/sh"

source "${SH_DIR}/build_tagged_images.sh"
source "${SH_DIR}/containers_down.sh"
source "${SH_DIR}/containers_up_healthy_and_clean.sh"
source "${SH_DIR}/copy_in_saver_test_data.sh"
source "${SH_DIR}/echo_versioner_env_vars.sh"
source "${SH_DIR}/ip_address.sh"
source "${SH_DIR}/remove_old_images.sh"

export $(echo_versioner_env_vars)

readonly IP_ADDRESS=$(ip_address)

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
api_demo()
{
  curl_json_body_200 alive
  curl_json_body_200 ready
  curl_json_body_200 sha
  echo
  curl_200 assets/app.css 'Content-Type: text/css'
  curl_200 assets/app.js  'Content-Type: application/javascript'
  echo
  curl_200 home   'Content-Type: text/html'
  curl_200 group  'Content-Type: text/html'
  curl_200 single 'Content-Type: text/html'

  curl_200 choose_problem        'Content-Type: text/html'
  curl_200 choose_ltf            'Content-Type: text/html'
  curl_200 choose_custom_problem 'Content-Type: text/html'

  curl_200 enter          'Content-Type: text/html'
  #curl_200 avatar?id=ID   'Content-Type: text/html'
  #curl_200 reenter?id=ID  'Content-Type: text/html'
  #curl_200 full?id=ID     'Content-Type: text/html'
  echo
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
curl_json_body_200()
{
  local -r route="${1}"  # eg ready
  curl  \
    --data '' \
    --fail \
    --header 'Content-type: application/json' \
    --header 'Accept: application/json' \
    --request GET \
    --silent \
    --verbose \
      "http://${IP_ADDRESS}:$(port)/${route}" \
      > "$(log_filename)" 2>&1

  grep --quiet 200 "$(log_filename)" # eg HTTP/1.1 200 OK
  local -r result=$(tail -n 1 "$(log_filename)")
  echo "GET ${route} => 200 ...|${result}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
curl_200()
{
  local -r route="${1}"   # eg kata_choose
  local -r pattern="${2}" # eg exercise
  curl  \
    --fail \
    --request GET \
    --silent \
    --verbose \
      "http://${IP_ADDRESS}:$(port)/${route}" \
      > "$(log_filename)" 2>&1

  grep --quiet 200 "$(log_filename)" # eg HTTP/1.1 200 OK
  local -r result=$(grep "${pattern}" "$(log_filename)" | head -n 1)
  echo "GET ${route} => 200 ...|${result}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
curl_params_302()
{
  local -r route="${1}"  # eg kata_create
  local -r params="${2}" # eg "display_name=Java Countdown, Round 1"
  curl  \
    --data-urlencode "${params}" \
    --fail \
    --request GET \
    --silent \
    --verbose \
      "http://${IP_ADDRESS}:$(port)/${route}" \
      > "$(log_filename)" 2>&1

  grep --quiet 302 "$(log_filename)" # eg HTTP/1.1 302 Moved Temporarily
  local -r result=$(grep Location "$(log_filename)" | head -n 1)
  echo "GET ${route} => 302 ...|${result}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
curl_url_params_302()
{
  local -r route="${1}"          # eg group_create
  local -r exercise_param="${2}" # eg "exercise_name":"Fizz Buzz"
  local -r language_param="${3}" # eg "languages_names":["Java, JUnit"]
  curl  \
    --data-urlencode "${exercise_param}" \
    --data-urlencode "${language_param}" \
    --fail \
    --request GET \
    --silent \
    --verbose \
      "http://${IP_ADDRESS}:$(port)/${route}" \
      > "$(log_filename)" 2>&1

  grep --quiet 302 "$(log_filename)" # eg HTTP/1.1 302 Moved Temporarily
  local -r result=$(grep Location "$(log_filename)" | head -n 1)
  echo "GET ${route} => 302 ...|${result}"
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
port() { echo -n "${CYBER_DOJO_CREATOR_PORT}"; }
log_filename() { echo -n /tmp/creator.log; }

#url_custom_param() { url_param display_name "$(custom_name)"; }
#custom_name() { echo -n 'Java Countdown, Round 1'; }

#url_exercise_param()  { url_param exercise_name "$(exercise_name)"; }
#exercise_name() { echo -n 'Fizz Buzz'; }

#url_language_param()  { url_param language_name "$(language_name)"; }
#language_name() { echo -n 'Java, JUnit'; }

#url_param() { echo -n "${1}=${2}"; }

#- - - - - - - - - - - - - - - - - - - - - - - - - - -
remove_old_images
build_tagged_images
server_up_healthy_and_clean
client_up_healthy_and_clean "$@"
copy_in_saver_test_data
api_demo
if [ "${1:-}" == '--no-browser' ]; then
  containers_down
else
  open "http://${IP_ADDRESS}:80/"
fi
