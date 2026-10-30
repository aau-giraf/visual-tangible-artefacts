# Endpoints

> API specification aligned with the provided ER diagram.

## Conventions

- All request and response bodies use JSON unless otherwise noted.
- `204 No Content` responses have no response body.
- IDs are integers.

# Users

## Get the current user

`GET /users/me`

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

`PATCH /users/me`

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

`PUT /users/me/password`

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

`DELETE /users/me`

### Response — `204 No Content`

No response body.

---

## Get user settings

`get /users/settings`

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

`post /users/settings`

### Request body

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

`get /users/board`

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


## Get all boards for the user

`get /users/boards`

### Response - `200 OK`

```json
{
    "ID": "int",
    "name": "string"
}
```

## New board made

`post /users/board`

### Request body

```json
{
    "name": "string"
}
```

### Response - `204 No Content`


# Artefacts

## blar blar blar