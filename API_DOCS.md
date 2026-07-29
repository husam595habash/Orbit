# API Documentation

Base URL: `http://localhost:8000`

All authenticated endpoints require an `Authorization: Bearer <token>` header, where `<token>` is obtained from `/user/signup` or `/user/login`.

---

# Users

## POST /user/signup

**Summary**
Registers a new user account and returns an authentication token.

**Purpose**
Entry point for new users to create an account. Called once per user, at sign-up time.

**Authentication**
Not required.

**Request**
- Path Parameters: none
- Query Parameters: none
- Request Body:
  - `firstname` (string, required)
  - `lastname` (string, required)
  - `username` (string, required, must be unique)
  - `email` (string, required, must be a valid email)
  - `password` (string, required)

**Response**
- Success: `201 Created`
- Body: `{ "user": {...}, "token": "<jwt>" }` — `user` excludes the password field
- Errors: `400 Bad Request` if the email or username is already registered

**Business Rules**
- Email and username must each be unique across all users.
- Password is hashed before storage; the plaintext password is never returned.

**Example Request**
```http
POST /user/signup
Content-Type: application/json

{
  "firstname": "Alice",
  "lastname": "Smith",
  "username": "alicesmith",
  "email": "alice@example.com",
  "password": "secret123"
}
```

**Example Response**
```json
{
  "user": {
    "id": "6a5c95faf3925e18a87a0407",
    "firstname": "Alice",
    "lastname": "Smith",
    "username": "alicesmith",
    "email": "alice@example.com",
    "bio": "",
    "imageUrl": "",
    "followers": [],
    "following": []
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

## POST /user/login

**Summary**
Authenticates a user by email and password and returns a fresh token.

**Purpose**
Used to re-authenticate an existing user (e.g. after their previous token expires).

**Authentication**
Not required.

**Request**
- Request Body:
  - `email` (string, required)
  - `password` (string, required)

**Response**
- Success: `200 OK`
- Body: `{ "user": {...}, "token": "<jwt>" }`
- Errors: `401 Unauthorized` if the email or password is incorrect

**Business Rules**
- Password is verified against the stored hash; it is never compared or returned in plaintext.

**Example Request**
```http
POST /user/login
Content-Type: application/json

{
  "email": "alice@example.com",
  "password": "secret123"
}
```

**Example Response**
```json
{
  "user": { "id": "6a5c95faf3925e18a87a0407", "firstname": "Alice", "...": "..." },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

## GET /user/suggested

**Summary**
Returns a list of users the caller might want to follow.

**Purpose**
Powers a "people you may know" / suggestions feature, based on the caller's existing network (followed-by-people-you-follow).

**Authentication**
Required.

**Request**
- Path Parameters: none
- Query Parameters: none

**Response**
- Success: `200 OK`
- Body: `{ "users": [ {...}, ... ] }`
- Errors: `404 Not Found` if the caller's user record can't be found

**Business Rules**
- Suggestions are always for the authenticated caller — there is no way to request another user's suggestions.
- Never suggests the requesting user themselves.
- Never suggests users the requester already follows.
- Suggestions are drawn from the followers/following of people the requester follows.

**Example Request**
```http
GET /user/suggested
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "users": [
    { "id": "6a5f99ff10ecd0fbf6ff9b80", "firstname": "Bob", "...": "..." }
  ]
}
```

---

## GET /user/search

**Summary**
Searches users by first name, last name, or username.

**Purpose**
Powers the app's people-search feature.

**Authentication**
Not required.

**Request**
- Query Parameters:
  - `q` (string, required) — the search text

**Response**
- Success: `200 OK`
- Body: `{ "users": [...] }`
- Errors: `400 Bad Request` if `q` is missing

**Business Rules**
- Matching is case-insensitive and substring-based against `firstname`, `lastname`, and `username`.
- Password is always excluded from results.

**Example Request**
```http
GET /user/search?q=ali
```

**Example Response**
```json
{
  "users": [
    { "id": "6a5c95faf3925e18a87a0407", "firstname": "Alice", "lastname": "Smith", "username": "alicesmith", "...": "..." }
  ]
}
```

---

## GET /user/{user_id}

**Summary**
Returns a single user's public profile.

**Purpose**
Used to view any user's profile page, including your own.

**Authentication**
Not required.

**Request**
- Path Parameters:
  - `user_id` (string, required)

**Response**
- Success: `200 OK`
- Body: the user
- Errors: `404 Not Found` if the user doesn't exist

**Business Rules**
- Password is always excluded from the response.

**Example Request**
```http
GET /user/6a5c95faf3925e18a87a0407
```

**Example Response**
```json
{ "id": "6a5c95faf3925e18a87a0407", "firstname": "Alice", "...": "..." }
```

---

## PATCH /user/{user_id}

**Summary**
Updates one or more fields on the caller's own profile.

**Purpose**
Lets a user edit their name, last name, password, bio, or profile image after account creation.

**Authentication**
Required. The token's user must match `{user_id}`.

**Request**
- Path Parameters:
  - `user_id` (string, required)
- Request Body (all fields optional; only provided fields are changed):
  - `firstname` (string)
  - `lastname` (string)
  - `username` (string, must remain unique)
  - `password` (string)
  - `Bio` (string)
  - `image` (string)

**Response**
- Success: `200 OK`
- Body: the updated user
- Errors: `403 Forbidden` if the token doesn't belong to `{user_id}`; `404 Not Found` if the user doesn't exist; `400 Bad Request` on failure

**Business Rules**
- A user can only update their own profile — no admin/override path.
- Omitted fields are left unchanged (true partial update).
- A new password is re-hashed before storage.

**Example Request**
```http
PATCH /user/6a5c95faf3925e18a87a0407
Authorization: Bearer <token>
Content-Type: application/json

{ "Bio": "Software engineer" }
```

**Example Response**
```json
{ "id": "6a5c95faf3925e18a87a0407", "bio": "Software engineer", "...": "..." }
```

---

## PATCH /user/{user_id}/following/{target_id}

**Summary**
Toggles whether `{user_id}` follows `{target_id}` — follows if not already following, unfollows if already following.

**Purpose**
Powers the follow/unfollow action on a user's profile.

**Authentication**
Required. The token's user must match `{user_id}`.

**Request**
- Path Parameters:
  - `user_id` (string, required) — the follower
  - `target_id` (string, required) — the user being followed/unfollowed

**Response**
- Success: `200 OK`
- Body: `{ "user1": {...}, "user2": {...} }` — updated versions of both users
- Errors: `403 Forbidden` if the token doesn't belong to `{user_id}`; `404 Not Found` if either user doesn't exist; `400 Bad Request` on failure

**Business Rules**
- A user can only change their own following list.
- The target user is notified the first time they're followed (not on unfollow).

**Example Request**
```http
PATCH /user/6a5c95faf3925e18a87a0407/following/6a5f99ff10ecd0fbf6ff9b80
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "user1": { "id": "6a5c95faf3925e18a87a0407", "following": ["6a5f99ff10ecd0fbf6ff9b80"], "...": "..." },
  "user2": { "id": "6a5f99ff10ecd0fbf6ff9b80", "followers": ["6a5c95faf3925e18a87a0407"], "...": "..." }
}
```

---

## DELETE /user/{user_id}

**Summary**
Permanently deletes a user account.

**Purpose**
Lets a user close/delete their own account.

**Authentication**
Required. The token's user must match `{user_id}`.

**Request**
- Path Parameters:
  - `user_id` (string, required)

**Response**
- Success: `200 OK`
- Body: `{ "message": "User deleted successfully" }`
- Errors: `403 Forbidden` if the token doesn't belong to `{user_id}`; `404 Not Found` if the user doesn't exist; `400 Bad Request` on failure

**Business Rules**
- A user can only delete their own account.
- Deletion is permanent and immediate; there is currently no cleanup of the deleted user's id from other users' followers/following lists.

**Example Request**
```http
DELETE /user/6a5c95faf3925e18a87a0407
Authorization: Bearer <token>
```

**Example Response**
```json
{ "message": "User deleted successfully" }
```

---

# Posts

## POST /post

**Summary**
Creates a new post authored by the caller.

**Purpose**
Primary way for a user to publish content to their feed.

**Authentication**
Required.

**Request**
- Request Body:
  - `title` (string, required)
  - `message` (string, required)
  - `selectedFile` (string, optional) — e.g. an image URL

**Response**
- Success: `201 Created`
- Body: the created post
- Errors: `404 Not Found` if the caller's user record can't be found; `400 Bad Request` on failure

**Business Rules**
- The post's author is always the authenticated caller — it cannot be set by the client.

**Example Request**
```http
POST /post
Authorization: Bearer <token>
Content-Type: application/json

{ "title": "Hello world", "message": "My first post" }
```

**Example Response**
```json
{
  "id": "6a68af475835014bf1b7a04f",
  "title": "Hello world",
  "message": "My first post",
  "creator": "6a5c95faf3925e18a87a0407",
  "selectedFile": null,
  "likes": [],
  "createdAt": "2026-07-28T13:00:00.000Z"
}
```

---

## GET /post/{post_id}

**Summary**
Returns a single post along with its creator's username/image and the first page of its comments.

**Purpose**
Used to view a specific post's detail page.

**Authentication**
Not required.

**Request**
- Path Parameters:
  - `post_id` (string, required)

**Response**
- Success: `200 OK`
- Body: the post, plus `name` (the creator's username) and `creatorImageUrl` fields, and a `comments` array
- Errors: `404 Not Found` if the post doesn't exist

**Business Rules**
- `comments` is always just the first page (up to 10, newest first) — it is not the full comment thread.
- To browse beyond the first 10, or to paginate through a large comment thread, use `GET /comment/{post_id}` directly.
- The feed (`GET /post`) does **not** include comments on each post, to keep listing many posts lightweight — only this single-post endpoint attaches them.

**Example Request**
```http
GET /post/6a68af475835014bf1b7a04f
```

**Example Response**
```json
{
  "id": "6a68af475835014bf1b7a04f",
  "title": "Hello world",
  "message": "My first post",
  "creator": "6a5c95faf3925e18a87a0407",
  "selectedFile": null,
  "likes": [],
  "createdAt": "2026-07-28T13:00:00.000Z",
  "name": "alicesmith",
  "creatorImageUrl": "",
  "comments": [
    {
      "id": "6a68adeae76c647a7d82394b",
      "post_id": "6a68af475835014bf1b7a04f",
      "user_id": "6a5f99ff10ecd0fbf6ff9b80",
      "value": "Great post!",
      "createdAt": "2026-07-28T13:26:02.886Z",
      "user": { "name": "bobjones", "imageUrl": "" }
    }
  ]
}
```

---

## GET /post

**Summary**
Returns a paginated feed of posts from users the caller follows (plus their own posts).

**Purpose**
The main home-feed endpoint.

**Authentication**
Required.

**Request**
- Query Parameters:
  - `page` (string, optional, default `1`)

**Response**
- Success: `200 OK`
- Body: `{ "posts": [...], "currentPage": <int>, "numberOfPages": <int> }`
- Errors: `400 Bad Request` on failure

**Business Rules**
- 6 posts per page, newest first.
- Includes posts from the caller and everyone the caller follows.

**Example Request**
```http
GET /post?page=1
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "posts": [ { "id": "...", "title": "Hello world", "name": "alicesmith", "...": "..." } ],
  "currentPage": 1,
  "numberOfPages": 1
}
```

---

## PATCH /post/{post_id}

**Summary**
Updates one or more fields on an existing post.

**Purpose**
Lets a post's author edit its title, message, or attached file.

**Authentication**
Required. The token's user must be the post's creator.

**Request**
- Path Parameters:
  - `post_id` (string, required)
- Request Body (all fields optional; only provided fields are changed):
  - `title` (string)
  - `message` (string)
  - `selectedFile` (string)

**Response**
- Success: `200 OK`
- Body: the updated post
- Errors: `404 Not Found` if the post doesn't exist; `403 Forbidden` if the caller isn't the creator; `400 Bad Request` on failure

**Business Rules**
- Only the post's creator can update it.
- Omitted fields are left unchanged.

**Example Request**
```http
PATCH /post/6a68af475835014bf1b7a04f
Authorization: Bearer <token>
Content-Type: application/json

{ "title": "Updated title" }
```

**Example Response**
```json
{
  "id": "6a68af475835014bf1b7a04f",
  "title": "Updated title",
  "message": "My first post",
  "...": "..."
}
```

---

## PATCH /post/{post_id}/like

**Summary**
Toggles a like on a post from the caller — likes it if not already liked, unlikes it if already liked.

**Purpose**
Powers the like/unlike button on a post.

**Authentication**
Required.

**Request**
- Path Parameters:
  - `post_id` (string, required)

**Response**
- Success: `200 OK`
- Body: the updated post, including the current `likes` list
- Errors: `404 Not Found` if the post doesn't exist

**Business Rules**
- The post's creator is notified the first time someone else likes it (not on unlike, and never for self-likes).

**Example Request**
```http
PATCH /post/6a68af475835014bf1b7a04f/like
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "id": "6a68af475835014bf1b7a04f",
  "likes": ["6a5f99ff10ecd0fbf6ff9b80"],
  "...": "..."
}
```

---

## DELETE /post/{post_id}

**Summary**
Permanently deletes a post.

**Purpose**
Lets a post's author remove it.

**Authentication**
Required. The token's user must be the post's creator.

**Request**
- Path Parameters:
  - `post_id` (string, required)

**Response**
- Success: `200 OK`
- Body: `{ "message": "Post deleted successfully" }`
- Errors: `404 Not Found` if the post doesn't exist; `403 Forbidden` if the caller isn't the creator; `400 Bad Request` on failure

**Business Rules**
- Only the post's creator can delete it.
- Deletion is permanent; comments on the post are not automatically removed.

**Example Request**
```http
DELETE /post/6a68af475835014bf1b7a04f
Authorization: Bearer <token>
```

**Example Response**
```json
{ "message": "Post deleted successfully" }
```

---

# Comments

## POST /comment/{post_id}

**Summary**
Adds a comment to a post.

**Purpose**
Lets a user comment on any post.

**Authentication**
Required.

**Request**
- Path Parameters:
  - `post_id` (string, required)
- Request Body:
  - `value` (string, required) — the comment text

**Response**
- Success: `201 Created`
- Body: the created comment
- Errors: `400 Bad Request` if the post doesn't exist or creation fails

**Business Rules**
- The comment's author is always the authenticated caller.
- The post's creator is notified the first time someone else comments (not for self-comments).

**Example Request**
```http
POST /comment/6a68af475835014bf1b7a04f
Authorization: Bearer <token>
Content-Type: application/json

{ "value": "Great post!" }
```

**Example Response**
```json
{
  "id": "6a68adeae76c647a7d82394b",
  "post_id": "6a68af475835014bf1b7a04f",
  "user_id": "6a5f99ff10ecd0fbf6ff9b80",
  "value": "Great post!",
  "createdAt": "2026-07-28T13:26:02.886Z"
}
```

---

## GET /comment/{post_id}

**Summary**
Returns a paginated list of a post's comments, newest first, each with its author's username and image.

**Purpose**
Used to display a post's comment thread, including pages beyond what `GET /post/{post_id}` already includes.

**Authentication**
Not required.

**Request**
- Path Parameters:
  - `post_id` (string, required)
- Query Parameters:
  - `page` (string, optional, default `1`)

**Response**
- Success: `200 OK`
- Body: `{ "comments": [...], "currentPage": <int>, "numberOfPages": <int> }`
- Errors: `400 Bad Request` on failure

**Business Rules**
- 10 comments per page, newest first.
- Page 1 here returns the same comments already embedded in `GET /post/{post_id}` — call this endpoint when you need page 2 onward, or want to page through comments independently of the post itself.

**Example Request**
```http
GET /comment/6a68af475835014bf1b7a04f?page=1
```

**Example Response**
```json
{
  "comments": [
    {
      "id": "6a68adeae76c647a7d82394b",
      "post_id": "6a68af475835014bf1b7a04f",
      "user_id": "6a5f99ff10ecd0fbf6ff9b80",
      "value": "Great post!",
      "createdAt": "2026-07-28T13:26:02.886Z",
      "user": { "name": "bobjones", "imageUrl": "" }
    }
  ],
  "currentPage": 1,
  "numberOfPages": 1
}
```

---

## DELETE /comment/{comment_id}

**Summary**
Permanently deletes a comment.

**Purpose**
Lets a comment's author remove it.

**Authentication**
Required. The token's user must be the comment's author.

**Request**
- Path Parameters:
  - `comment_id` (string, required)

**Response**
- Success: `200 OK`
- Body: `{ "message": "Comment deleted successfully" }`
- Errors: `404 Not Found` if the comment doesn't exist; `403 Forbidden` if the caller isn't the author; `400 Bad Request` on failure

**Business Rules**
- Only the comment's own author can delete it — the post's owner has no special deletion rights over others' comments.

**Example Request**
```http
DELETE /comment/6a68adeae76c647a7d82394b
Authorization: Bearer <token>
```

**Example Response**
```json
{ "message": "Comment deleted successfully" }
```

---

# Chat

## POST /chat/messages

**Summary**
Sends a direct message to another user.

**Purpose**
Core action for one-to-one messaging between users.

**Authentication**
Required.

**Request**
- Request Body:
  - `content` (string, required) — the message text
  - `receiver` (string, required) — the recipient's user id

**Response**
- Success: `201 Created`
- Body: the created message
- Errors: `400 Bad Request` on failure

**Business Rules**
- The sender is always the authenticated caller.
- Sending a message increments the receiver's unread count for this conversation.

**Example Request**
```http
POST /chat/messages
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Hey!", "receiver": "6a5f99ff10ecd0fbf6ff9b80" }
```

**Example Response**
```json
{
  "id": "6a64b1023ab975669011da58",
  "content": "Hey!",
  "sender": "6a5c95faf3925e18a87a0407",
  "receiver": "6a5f99ff10ecd0fbf6ff9b80"
}
```

---

## GET /chat/messages

**Summary**
Returns paginated message history between two specific users.

**Purpose**
Used to display a conversation thread.

**Authentication**
Required. The caller must be one of the two participants.

**Request**
- Query Parameters:
  - `user_a_id` (string, required)
  - `user_b_id` (string, required)
  - `page` (string, optional, default `"0"`)

**Response**
- Success: `200 OK`
- Body: `{ "messages": [...], "currentPage": <int>, "numberOfPages": <int> }` — 8 per page, oldest-to-newest within the page
- Errors: `403 Forbidden` if the caller isn't one of the two participants; `400 Bad Request` on failure

**Business Rules**
- Only a conversation's participants can view it — no third party access, regardless of authentication.
- Unlike posts/comments, `page` here is 0-indexed.

**Example Request**
```http
GET /chat/messages?user_a_id=6a5c95faf3925e18a87a0407&user_b_id=6a5f99ff10ecd0fbf6ff9b80&page=0
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "messages": [
    { "id": "...", "sender": "6a5c95faf3925e18a87a0407", "receiver": "6a5f99ff10ecd0fbf6ff9b80", "content": "Hey!" }
  ],
  "currentPage": 0,
  "numberOfPages": 1
}
```

---

## GET /chat/messages/unread

**Summary**
Returns a summary of the caller's unread messages, grouped by sender.

**Purpose**
Powers unread-message badges/notifications in a messaging UI.

**Authentication**
Required.

**Request**
- Path Parameters: none
- Query Parameters: none

**Response**
- Success: `200 OK`
- Body: `{ "messages": [...], "total": <int> }` — one entry per conversation with unread messages
- Errors: `400 Bad Request` on failure

**Business Rules**
- Only ever returns the caller's own unread state — there is no way to query another user's unread messages.

**Example Request**
```http
GET /chat/messages/unread
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "messages": [
    { "id": "...", "recipient_id": "6a5c95faf3925e18a87a0407", "sender_id": "6a5f99ff10ecd0fbf6ff9b80", "numOfUnreadMessages": 3, "isRead": false }
  ],
  "total": 3
}
```

---

## PATCH /chat/messages/read

**Summary**
Marks all of the caller's unread messages from a specific sender as read.

**Purpose**
Called when a user opens a conversation, to clear its unread badge.

**Authentication**
Required.

**Request**
- Query Parameters:
  - `sender_id` (string, required) — whose messages to mark as read

**Response**
- Success: `200 OK`
- Body: `{ "isMarked": true }` or `{ "isMarked": false }` (nothing was unread)
- Errors: `400 Bad Request` on failure

**Business Rules**
- Marks the entire conversation as read at once — there is no per-message granularity.
- A caller can only mark their own inbox as read, never another user's.

**Example Request**
```http
PATCH /chat/messages/read?sender_id=6a5f99ff10ecd0fbf6ff9b80
Authorization: Bearer <token>
```

**Example Response**
```json
{ "isMarked": true }
```

---

# Notifications

## GET /notification

**Summary**
Returns the caller's notifications (e.g. new followers, likes, comments), newest first.

**Purpose**
Powers a notifications inbox/panel.

**Authentication**
Required.

**Request**
- Path Parameters: none
- Query Parameters:
  - `page` (string, optional, default `1`)

**Response**
- Success: `200 OK`
- Body: `{ "notifications": [...], "currentPage": <int>, "numberOfPages": <int> }`
- Errors: `400 Bad Request` on failure

**Business Rules**
- Only ever returns the caller's own notifications.
- 10 notifications per page, newest first.

**Example Request**
```http
GET /notification?page=1
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "notifications": [
    {
      "id": "6a6891393d8d3cfeaaf4cab0",
      "details": "user alicesmith started following you",
      "recipient_id": "6a5f99ff10ecd0fbf6ff9b80",
      "actor_id": "6a5c95faf3925e18a87a0407",
      "isRead": false,
      "createdAt": "2026-07-28T11:23:37.237Z",
      "actor": { "name": "alicesmith", "imageUrl": "" }
    }
  ],
  "currentPage": 1,
  "numberOfPages": 1
}
```

---

## PATCH /notification/read

**Summary**
Marks all of the caller's notifications as read.

**Purpose**
Called when a user opens their notifications panel, to clear the unread badge.

**Authentication**
Required.

**Request**
- Path Parameters: none
- Query Parameters:
  - `page` (string, optional, default `1`) — which page of the (now all-read) notifications to return

**Response**
- Success: `200 OK`
- Body: `{ "notifications": [...], "currentPage": <int>, "numberOfPages": <int> }`, all with `isRead: true`
- Errors: `400 Bad Request` on failure

**Business Rules**
- Marks every notification as read in one call — there is no per-notification granularity.
- A caller can only mark their own notifications as read.

**Example Request**
```http
PATCH /notification/read
Authorization: Bearer <token>
```

**Example Response**
```json
{
  "notifications": [
    { "id": "6a6891393d8d3cfeaaf4cab0", "isRead": true, "...": "..." }
  ],
  "currentPage": 1,
  "numberOfPages": 1
}
```
