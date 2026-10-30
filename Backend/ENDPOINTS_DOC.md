# VTA API ENDPONITS
## AdminController

----------------------------------

### Caregivers 

**GET** `/api/Admin/Caregivers`

Retrevies a list of Caregivers 

**Request body**

None.  

**Response:**  `200 OK` 

List of Caregivers pagninated  

``` json
{ "items": [

{ "id":"string",
"name":"string or null",
"username":"string",
"NameVisible": true,
"FieldCount":0,
"Role":"Caregiver",
"Catagories": []
}
], 
"TotalCount": 1,
"skip": 0,
"take": 10

}
```

----------------------------------

### Children 

**GET** `/api/Admin/Children` 

Retrevies a list of Children 

**Request body**

None.

**Reponse** - `200 Ok` 

list of Children pagninated  

``` json
{ "items": [

{ "id":"string",
"name":"string or null",
"username":"string",
"NameVisible": true,
"FieldCount":0,
"Role":"Children",
"Catagories": []
}
], 
"TotalCount": 1,
"skip": 0,
"take": 10

}
```

----------------------------------


### admins GET

**GET** `/api/admin/admins`

Retrevies a list of admins 

**Request body**

None. 

**Response** - `200 OK`

List of admins pagninated  

``` json
{ "items": [

{ "id":"string",
"name":"string or null",
"username":"string",
"NameVisible": true,
"FieldCount":0,
"Role":"admins",
"Catagories": []
}
], 
"TotalCount": 1,
"skip": 0,
"take": 10

}
```

----------------------------------

### Admin POST 

**POST** `/api/Admin/admins`

...du mangler noget...

**Request body**

```json 
{
    "Username":"string",
    "Password": "string",
    "Name": "string",
    "Role":"Admin"

}
```
**Response** - `201 Created` 

``` json

{ "items": [

{ "id":"string",
"name":"string or null",
"username":"string",
"NameVisible": true,
"FieldCount":0,
"Role":"Admin",
"Catagories": []
}
], 
"TotalCount": 1,
"skip": 0,
"take": 10

}

```

**Response** - `409 Conflict`

----------------------------------

### User DELETE 

**DELETE** `/api/admin/users/{id}`

Deletes a user with an id. 

**Request body**

None.

**Reponse** - `204 No Content`

No response body. 

**Response** - `404 Not Found`

No response body. 

----------------------------------

### USER POST

**POST** `/api/admin/users/{id}/make-admin`

Changes the user's role to Admin.

**Request body**

none. 

**Response** `200 OK`

No Response body. 

**Response** `404 Not Found`

No Response body.


----------------------------------

### pairings GET

**GET** `/api/Admin/pairings`

Retrieves all active pairings.


**Request body** 

none.

**Response** - `200 OK`

```json
[
  {
    "Id": "string",
    "CaregiverId": "string",
    "ChildId": "string",
    "IsActive": true,
    "CreatedAt": "DateTime",
    "Caregiver": null,
    "Child": null
  }
]
```

----------------------------------

### pairings POST

**POST** `/api/Admin/pairings`

Creates a pairing between a caregiver and a child.

**Request body**

``` json
{
    "CaregiverId":"string",
    "ChildId":"string"
}

```
**Response** - `409 Conflict`

**Response** - `400 Bad Request` 

**Response** - `200 OK`
```Json

{
  "id": "string"
}

```


----------------------------------

### pairings DELETE

**DELETE** `/api/Admin/pairings/{id}`

Deletes a pairing

**Request body**

none.

**Response** `404 Not found`
**Response** `204 No Content`

----------------------------------

## Boardscontroller 

### Boards

**GET** `/api/Boards`

Gets all boards that the authenticated user owns

**Request body**

none. 

**Response** - `200 OK`

```json
{
  "id": "string",
  "boardId": "string",
  "name": "string",
  "userId": "string",
  "snapshotUrl": "string or null",
  "createdDate": "DateTime",
  "modifiedDate": " DateTime or null",
  "savedArtefacts": [],
  "artefacts": []
}
```

----------------------------------

**GET** `/api/Boards/list`

Gets a lightweight list of board IDs, names, and thumbnails for the authenticated user

**Request body**

none. 

**Response** - `200 OK`

```json
[
  {
    "id": "string",
    "boardId": "string",
    "name": "string",
    "snapshotUrl": "string or null",
    "createdDate": "DateTime",
    "modifiedDate": "DateTime or null"
  }
]
```


----------------------------------

**GET** `/api/Boards/{boardId}`

autherization husk tilføj- anisa noter 

Gets a specific board with all its saved artefacts

**Request body**

none. 


**Response** `404 Not Found`


**Response** `401 unautherization`

**Response** `200 OK`

```json
{
  "boardId": "string",
  "name": "string",
  "createdDate": "DateTime",
  "modifiedDate": "DateTime or null",
  "artefacts": [
    {
      "savedArtefactId": "string",
      "artefactId": "string",
      "posX": 0,
      "posY": 0,
      "width": 200,
      "height": 200
    }
  ]
}
```

----------------------------------

**POST** `/api/Boards`

Creates a new board for the authenticated user. Accepts either the simple
BoardPostDTO shape or the richer SaveBoardRequestDTO with artefact layouts.

**Request body** `SaveBoardRequestDTO`

```json
{
  "name": "string",
  "artefacts": [
    {
      "savedArtefactId": "string or null",
      "artefactId": "string",
      "posX": 0,
      "posY": 0,
      "width": 200,
      "height": 200,
      "nameVisible": true
    }
  ]
} 
```

**Request body** `BoardPostDTO`

```json
{
  "name": "string",
  "snapshotPath": "string or null"
} 
```

**Response**  `400 Bad Request`


**Response**  `201 Created`

```json
{
  "boardId": "string",
  "name": "string",
  "createdDate": "DateTime",
  "modifiedDate": "DateTime or null",
  "artefacts": [
    {
      "savedArtefactId": "string or null",
      "artefactId": "string",
      "posX": 0,
      "posY": 0,
      "width": 200,
      "height": 200,
      "nameVisible": true
    }
  ]
}
```

**Response**  `200 OK`
```json
{
  "id": "string",
  "name": "string",
  "snapshotPath": "string or null",
  "createdDate": "DateTime",
  "modifiedDate": "DateTime or null"
}
```
----------------------------------


**PATCH** `/api/Boards `

Updates a board's information


**Request body** 
 ```json

 {
  "boardId": "string",
  "name": "string or null",
  "snapshotPath": "string or null"
}
 
 ```


**Response** `204 No Content`

no response body.

**Response** `401 unautherize`

**Response** `404 Not Found`

----------------------------------

**PUT** `/api/Boards/{boardId}`

Update an existing board layout (name and artefacts). Uses SaveBoardRequestDTO format.

**Request body**

```json
{
  "name": "string",
  "artefacts": [
    {
      "savedArtefactId": "string or null",
      "artefactId": "string",
      "posX": 0,
      "posY": 0,
      "width": 200,
      "height": 200,
      "nameVisible": true
    }
  ]
} 

```

**Response** `200 OK`
```json
{
  "boardId": "string",
  "name": "string",
  "createdDate": "DateTime",
  "modifiedDate": "DateTime or null",
  "artefacts": [
    {
      "savedArtefactId": "string or null",
      "artefactId": "string",
      "posX": 0,
      "posY": 0,
      "width": 200,
      "height": 200,
      "nameVisible": true
    }
  ]
} 
```
**Response** `400 Bad Request`
**Response** `401 Unautherize`
**Response** `404 Not found`
**Response** `500 Internal Server Error`


----------------------------------

**PATCH** `/api/Boards/{boardId}/artefacts`

Update the position and size of a specific artefact on a board

**Request body**

```json

{
  "savedArtefactId": "string or null",
  "artefactId": "string",
  "posX": 0,
  "posY": 0,
  "width": 200,
  "height": 200,
  "nameVisible": true
}

```
**Response** `200 OK`

``` json

{
    " message ": "Artefact layout updated successfully"
}

```
maybe delete this 

**Response** `400 Bad Request`
**Response** `401 Unautherize`
**Response** `404 Not found`
**Response** `500 Internal Server Error`



----------------------------------

**DELETE** `/api/Boards/{boardId}/artefacts/{savedArtefactId}`

Remove a specific artefact from a board

**Request body**

none.  

**Response**  

**Response** `204 No Content`

**Response** `401 Unautherize`

**Response** `404 Not found`

**Response** `500 Internal Server Error`


----------------------------------

**DELETE** `/api/Boards/{boardId}/artefacts`

Clear all artefacts from a board (without deleting the board itself)

**Request body**

none. 

**Response**  `200 OK`

**Response** `401 Unatherize`

**Response** `404 Not Found`

----------------------------------

**DELETE** `/api/Boards/{boardId}`

Deletes a board and all its saved artefacts

**Request body**

none 

**Response**  `200 OK`

**Response** `401 Unatherize`

**Response** `404 Not Found`


----------------------------------

## ArtefactController 

**GET** `/api/Artefacts`

Gets all artefacts that a user owns

**Request body**

none.

**Response** `200 OK`

```json
{
  "artefactId": "string",
  "ArtefactIndex": 0,
  "UserId": "string",
  "CategoryId": "string",
  "Name": "string",
  "NameShown": true,
  "imageUrl": "string",
  "soundUrl": "string"
}
```
**Response** `401 Unauthorized` 


----------------------------------


**GET** `/api/Artefacts/{artefactId}`

Gets a specific artefact.

**Request body**

none.

**Response** `200 OK`

```json
{
  "artefactId": "string",
  "ArtefactIndex": 0,
  "UserId": "string",
  "CategoryId": "string",
  "Name": "string",
  "NameShown": true,
  "imageUrl": "string",
  "soundUrl": "string"
}
```
**Response** `401 Unauthorized`
**Response** `404 Not Found`

----------------------------------


**PATCH** `/api/Artefacts`

Updates an existing artefact.

**Request body**

``` json
{
  "artefactId": "string",
  "ArtefactIndex": 0,
  "UserId": "string",
  "CategoryId": "string",
  "Name": "string",
  "NameShown": true,
    "Image": "IFormFile",
  "Sound": "IFormFile"
}

```

**Response** `204 No Content`
**Response** `401 Unauthorized`
**Response** `404 Not Found`


----------------------------------


**POST** `/api/Artefacts`

Creates a new artefact.

**Request body**

```json
{
  "artefactId": "string",
  "ArtefactIndex": 0,
  "UserId": "string",
  "CategoryId": "string",
  "Name": "string",
  "NameShown": true,
  "imageUrl": "IFormFile",
  "soundUrl": "IFormFile"
}
```

**Response** `200 OK`

```json
{
  "artefactId": "string",
  "ArtefactIndex": 0,
  "UserId": "string",
  "CategoryId": "string",
  "Name": "string",
  "NameShown": true,
  "imageUrl": "string",
  "soundUrl": "string"
}

```

**Response** `403 Forbidden`



----------------------------------


**DELETE** `/api/Artefacts/{artefactId}`

Deletes an artefact using its ID.

**Request body**

none.

**Response** `204 No Content`
**Response** `401 Unauthorized`
**Response** `403 Forbidden`
**Response** `404 Not Found`
**Response** `500 Internal Server Error`

----------------------------------


**POST** `/api/Artefacts/generate-speech-simple`

Generates speech from text using the ElevenLabs API.

**Request body**


``` json
{
 "Text":"string",
 "VoiceId": null

}
```

**Response** `200 OK`
**Response** `400 Bad Request`
**Response** `500 Internal Server Error`


----------------------------------

**POST** `/api/Artefacts/generate-speech-and-save`

Generates speech from text and saves it to an existing artefact.

**Request body**
``` json
{
  "ArtefactId": "string",
  "Text": "string",
  "VoiceId": null
}
```

**Response** `200 OK`

```json
{
  "soundUrl": "string",

}
```
**Response** `400 Bad Request`
**Response** `401 Unauthorized`
**Response** `404 Not Found`
**Response** `500 Internal Server Error`


----------------------------------

**POST** `/api/Artefacts/generate-and-save-speech`

Generates speech from text and saves it with a unique ID.

**Request body**

```json
{
  "Text": "string",
  "VoiceId": null
}
```

**Response** `200 OK`


```json
{
  "soundId": "string",
  "soundUrl": "string",

}
```

**Response** `400 Bad Request`
**Response** `401 Unauthorized`
**Response** `500 Internal Server Error`


----------------------------------

**GET** `/api/Artefacts/{artefactId}/play-audio`

Gets the audio file attached to a specific artefact.

**Request body**

none.

**Response** `200 OK`

**Response** `401 Unauthorized`

**Response** `404 Not Found`

----------------------------------


**POST** `/api/Artefacts/generate-speech`

Generates speech from text and saves it to an existing artefact.

**Request body**

```json
{
  "ArtefactId": "string",
  "Text": "string",
  "VoiceId": null,
  "ModelId": null,
  "Stability": 0.0,
  "SimilarityBoost": 0.0,
  "UseSpeakerBoost": true
}
```

**Response** `200 OK`
**Response** `400 Bad Request`
**Response** `403 Forbidden`
**Response** `404 Not Found`
**Response** `500 Internal Server Error`


----------------------------------


**PATCH** `/api/Artefacts/bulk-update-name-shown`

Updates NameShown for all artefacts owned by the current user.

**Request body**

```json
{
  "NameShown": true
}
```

**Response** `200 OK`

```json
{
  "updatedCount": 0,
  "nameShown": true
}
```
**Response** `401 Unauthorized`

----------------------------------

## AssetsController


**GET** `/api/Assets/Artefacts/{userId}/{filename}`



**Request body**

none

**Response** `200 OK`

**Response** `404 Not Found`

----------------------------------


**GET** `/api/Assets/Categories/{userId}/{filename}`



**Request body**

none

**Response** `200 OK`

**Response** `404 Not Found`

----------------------------------


**GET** ` /api/Assets/Sounds/{userId}/{filename}`


**Request body**

none

**Response** `200 OK`

**Response** `404 Not Found`

----------------------------------

## ContactsController

**GET** ` /api/Contacts`


**Request body**

none

**Response** `200 OK`

```json 
[
  {
    "Id": "string",
    "Name": "string",
    "Username": "string",
    "NameVisible": true,
    "FieldCount": 0,
    "Role": "Admin",
    "Categories": []
  }
]
```

**Response** `401 unautherized`

----------------------------------


## Migration Controller 

**POST** `/api/Migration/migrate-to-user-based-storage`

Migrates files from flat structure to user-based structure

**Request body**

none

**Response** `200 OK`

```json
[
  {
    "Id": "string",
    "Name": "string",
    "Username": "string",
    "NameVisible": true,
    "FieldCount": 0,
    "Role": "Child",
    "Categories": []
  }
]
```

**Response** `404 Not Found`

----------------------------------

## Relation Controller

**GET** `/api/Relation`



**Request body**

none

**Response** `200 OK`

```json



```

**Response** `403  Forbidden`

**Response** `401 Unauthorized`

----------------------------------


**GET** ``

**Request body**

**Response** 



----------------------------------

**POST** ``


**Request body**

**Response** 


----------------------------------

**DELETE** ``


**Request body**



**Response**

----------------------------------

**DELETE** ``


**Request body**


**Response** 


----------------------------------
