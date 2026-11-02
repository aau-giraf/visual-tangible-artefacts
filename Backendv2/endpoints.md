# Endpoints

> API specification aligned with the provided ER diagram.

## Conventions

- All request and response bodies use JSON unless otherwise noted.
- `204 No Content` responses have no response body.
- IDs are integers.
- Endpoints are desinged with RESTful API´s in mind

# Users

## Get the current user

`GET /users/{id}`

### Request body

None.

### Response — `200 OK`

```json
{
  "id": 0,
  "username": "string",
  "email": "user@example.com",
  "first_name": "string",
  "last_name": "string",
  "role": "teacher"
}
```
---

## Get all users

`GET /users`

### Response - `200 OK`

```json
{
  "id": 0,
  "username": "string",
  "email": "user@example.com",
  "first_name": "string",
  "last_name": "string",
  "role": "teacher"
}
```

---

## Register a user

`POST /auth/register`

### Request body

```json
{
  "username": "string",
  "password": "string",
  "email": "user@example.com",
  "first_name": "string",
  "last_name": "string",
  "role": "parent"
}
```

---

## Update the current user

`PATCH /users/{id}`

### Request body

All fields are optional.

```json
{
  "first_name": "string",
  "last_name": "string",
  "email": "user@example.com",
  "username": "string"
}
```

### Response — `200 OK`

```json
{
  "id": 0,
  "username": "string",
  "email": "user@example.com",
  "first_name": "string",
  "last_name": "string",
  "role": "teacher"
}
```

---

## Change password

`PUT /users/{id}/password`

### Request body

```json
{
  "old_password": "string",
  "new_password": "string"
}
```

### Response — `204 No Content`

No response body.

---

## Delete the current user

`DELETE /users/{id}`

### Response — `204 No Content`

No response body.

---

## Get user settings

`GET /users/{id}/settings`

### Response - `200 OK`

```json
{
    "contrast": "boolean",
    "light": "boolean",
    "dark": "boolean",
    "language": "string",
    "Sound": "boolean",
    "sentenceBar": "boolean"
}
```

---

## Update user settings

`PATCH /users/{id}/settings`

### Request body

All fields are optional.

```json
{
    "contrast": "boolean",
    "light": "boolean",
    "dark": "boolean",
    "language": "string",
    "Sound": "boolean",
    "sentenceBar": "boolean"
}
```

### Response — `204 No Content`

No response body.

---

# Board

## Get a board for a user

`GET /users/{id}/boards/{id}`

### Response - `200 OK`

```json
{
    "ImageID": "int",
    "posX": "float",
    "posY": "float",
    "gridX": "int",
    "gridY": "int"
}
```
---

## Get all boards for the user

`GET /users/{id}/boards`

### Response - `200 OK`

```json
{
    "ID": "int",
    "name": "string"
}
```

---

## New board made

`POST /users/{id}/board`

### Request body

```json
{
    "name": "string"
}
```

### Response - `204 No Content`

---

# Artefacts

## Get an artefact for a board

`GET /users/{id}/boards/{id}/images/{id}`

### Response - `200 OK`


```json
{
  "name": "string",
  "path": "string",
  "useCount": "int"
}
```

---

## Get all artefacts for a board

`GET /users/{id}/boards/{id}/images`

## Response - `200 OK`

```json
{
  "name": "string",
  "path": "string",
  "useCount": "int"
}
```

---
