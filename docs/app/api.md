# API Documentation

## Overview

This document provides an overview of the API endpoints available for managing clients and virtual machines (VMs) in the VPS hosting infrastructure project.

## Base URL

The base URL for all API endpoints is:

```
http://<your-server-address>/api
```

## Authentication

All endpoints require authentication. Use the following method to authenticate:

- **Token-based authentication**: Include the token in the `Authorization` header as follows:
  
  ```
  Authorization: Bearer <your-token>
  ```

## Client Endpoints

### Create Client

- **POST** `/clients`
- **Description**: Creates a new client.
- **Request Body**:
  ```json
  {
    "name": "string",
    "email": "string",
    "password": "string"
  }
  ```
- **Response**:
  - **201 Created**: Returns the created client object.
  - **400 Bad Request**: If the request body is invalid.

### Update Client

- **PUT** `/clients/:id`
- **Description**: Updates an existing client.
- **Request Body**:
  ```json
  {
    "name": "string",
    "email": "string"
  }
  ```
- **Response**:
  - **200 OK**: Returns the updated client object.
  - **404 Not Found**: If the client does not exist.

### Delete Client

- **DELETE** `/clients/:id`
- **Description**: Deletes a client.
- **Response**:
  - **204 No Content**: If the client was successfully deleted.
  - **404 Not Found**: If the client does not exist.

## VM Endpoints

### Create VM

- **POST** `/vms`
- **Description**: Creates a new virtual machine.
- **Request Body**:
  ```json
  {
    "clientId": "string",
    "vmConfig": {
      "cpu": "number",
      "memory": "number",
      "disk": "number"
    }
  }
  ```
- **Response**:
  - **201 Created**: Returns the created VM object.
  - **400 Bad Request**: If the request body is invalid.

### Start VM

- **POST** `/vms/:id/start`
- **Description**: Starts a virtual machine.
- **Response**:
  - **200 OK**: Returns the VM object with updated status.
  - **404 Not Found**: If the VM does not exist.

### Stop VM

- **POST** `/vms/:id/stop`
- **Description**: Stops a virtual machine.
- **Response**:
  - **200 OK**: Returns the VM object with updated status.
  - **404 Not Found**: If the VM does not exist.

### Delete VM

- **DELETE** `/vms/:id`
- **Description**: Deletes a virtual machine.
- **Response**:
  - **204 No Content**: If the VM was successfully deleted.
  - **404 Not Found**: If the VM does not exist.

## Error Handling

All API responses include a status code and a message. Common error responses include:

- **400 Bad Request**: The request was invalid.
- **401 Unauthorized**: Authentication failed.
- **404 Not Found**: The requested resource was not found.
- **500 Internal Server Error**: An unexpected error occurred.

## Conclusion

This API provides a comprehensive interface for managing clients and virtual machines in the VPS hosting infrastructure. For further details, refer to the specific endpoint documentation or the source code.