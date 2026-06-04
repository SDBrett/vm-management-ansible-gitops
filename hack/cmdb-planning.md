Purpose: Simulate a CMDB using a basic API

Usage:
  POST:
    API Path: /vm/create
    When a post request is made the service will generate a random 4 digit UUID and return that in the response payload
    Response payload:
    {
        "resource_UUID": "UUID"
    }
  DELETE:
    API Path: /vm/uuid
    Returns a 200 code to indicate that the resource was deleted