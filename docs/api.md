# API
- - - -
## POST create_group(manifest)
 Creates a new group from a start-point manifest and returns its id.
- parameters [(JSON-in)](#json-in)
  * **manifest:Hash** of a start-point.
- returns [(JSON-out)](#json-out)
  * the new group's id.
- example
  ```bash
  $ curl \
    --data '{"manifest":{"image_name":"..."}}' \
    --header 'Content-type: application/json' \
    --silent \
    -X POST \
      http://${IP_ADDRESS}:${PORT}/create_group
  {"create_group":"P0R0cU"}
  ```

- - - -
## POST create_kata(manifest)
Creates a new kata from a start-point manifest and returns its id.
- parameters [(JSON-in)](#json-in)
  * **manifest:Hash** of a start-point.
- returns [(JSON-out)](#json-out)
  * the new kata's id.
- example
  ```bash
  $ curl \
    --data '{"manifest":{"image_name":"..."}}' \
    --header 'Content-type: application/json' \
    --silent \
    -X POST \
      http://${IP_ADDRESS}:${PORT}/create_kata
  {"create_kata":"8Ey4xK"}
  ```

- - - -
## GET ready?
Tests if the service is ready to handle requests.
- parameters
  * none
- returns [(JSON-out)](#json-out)
  * **true** if the service is ready
  * **false** if the service is not ready
- notes
  * Used as a [Kubernetes](https://kubernetes.io/) readiness probe.
- example
  ```bash     
  $ curl --silent -X GET http://${IP_ADDRESS}:${PORT}/ready?
  {"ready?":false}
  ```

- - - -
## GET alive?
Tests if the service is alive.  
- parameters
  * none
- returns [(JSON-out)](#json-out)
  * **true**
- notes
  * Used as a [Kubernetes](https://kubernetes.io/) liveness probe.  
- example
  ```bash     
  $ curl --silent -X GET http://${IP_ADDRESS}:${PORT}/alive?
  {"alive?":true}
  ```

- - - -
## GET sha
The git commit sha used to create the Docker image.
- parameters
  * none
- returns [(JSON-out)](#json-out)
  * the 40 character commit sha string.
- example
  ```bash     
  $ curl --silent -X GET http://${IP_ADDRESS}:${PORT}/sha
  {"sha":"41d7e6068ab75716e4c7b9262a3a44323b4d1448"}
  ```

- - - -
## JSON in
- All methods pass any arguments as a json hash in the http request body.
  * If there are no arguments you can use ```''``` (which is the default
    for ```curl --data```) instead of ```'{}'```.

- - - -
## JSON out      
- All methods return a json hash in the http response body.
  * If the method completes, a string key equals the method's name. eg
    ```bash
    $ curl --silent -X GET http://${IP_ADDRESS}:${PORT}/ready?
    {"ready?":true}
    ```
  * If the method raises an exception, a string key equals ```"exception"```, with
    a json-hash as its value. eg
    ```bash
    $ curl --silent -X POST http://${IP_ADDRESS}:${PORT}/create_group | jq      
    {
      "exception": {
        "path": "/create_group",
        "body": "",
        "class": "CreatorService",
        "message": "manifest is missing",
        "backtrace": [
          ...
          "/usr/bin/rackup:23:in `<main>'"
        ]
      }
    }
    ```