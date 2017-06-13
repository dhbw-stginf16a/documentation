# BrettProjekt Channel-Based WebSocket Documentation

## Basic Setup
The BrettProjekt Backend is running an instance of the [Phoenix Web Framework](http://phoenixframework.org). Therefore we are using Phoenix channels on top of WebSockets for request/response and pub/sub based communication.

To get started, include the Phoenix-Channels WebSocket client and read it's [documentation in source-code](https://github.com/mspanc/phoenix_socket/blob/master/dist/socket.js).

### [REQUEST `main` -> `create_game`]: Create a new game
Creates a new game with no players on the server. The response will be a game-id for joining.

- Arguments:
- Response:
  - `ok`
    - `game_id`: The game id with which other players are able to join

### [REQUEST `main` -> `join_game`]: Join a game
Join an existing game.

- Arguments:
  - `username`: String (Username has to be printable and contain 3-16 characters)
  - `game_id`: String (The game to join)
- Response:
  - `ok`
    - `auth_token` (Authentication-token, which verifies all further player-messages)
    - `game_channel` (The Phoenix-Channel to join)
    - `user_id` (The user-identifier in the game)
    - `team_size` (Number of teams in the game)
  - `error`
    - `reason: "username_missing"`
  - `error`
    - `reason: "game_id_missing"`
  - `error` (The username contains non-printable characters, is no string, is too short or too long)
    - `reason: "username_invalid"`
  - `error` (No such game exists)
    - `reason: "game_id_invalid"`
  - `error` (The game can't be joined anymore, probably already started)
    - `reason: "joining_disabled"`
  - `error` (A player with the same name already joined the game)
    - `reason: "name_conflict"`

### [JOIN `#{game_channel}`]: Join the game-channel
- Arguments:
  - `auth_token` (The authentication-token received with [`main` -> `join_game`])
- Response:
  - `ok` (Joining the channel was successful)
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `lobby_update`]
- `startable`: Boolean
- `players`: Array[Object]
  - `name`: String (Player-Name)
  - `id`: Integer (Player-Id)
  - `team`: Integer (id of the team)

### [REQUEST `#{game_channel}` -> `start_game`]: Admin starts the game
- Arguments:
  - `auth_token`: String
- Response:
  - `ok` (Game was started)
  - `error` (Only the admin can start the game)
    - `reason: missing_permission`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `round_preparation`]
- `round_started`: Boolean
- `categories`: Array[String]
- `players`: Array[Object]
  - `name`: String (Player-Name)
  - `id`: Integer (Player-Id)
  - `team`: Integer (id of the team)
  - `categories`: Array[String]

### [REQUEST `#{game_channel}` -> `ready`]: Player is ready
- Arguments:
  - `auth_token`: String
- Response:
  - `ok` (Update of `round_preparation` will be broadcast)
  - `error` (One cannot be ready without being assigned a category)
    - `reason: no_category`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [REQUEST `#{game_channel}` -> `round_preparation`]
- Arguments:
  - `auth_token`: String
  - `category`: String
- Response:
  - `ok` (Category was assigned)
  - `error` (Category has already been asigned to team mate)
    - `reason: category_already_assigned`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `round_started`]
(Round starts when everyone is ready and conditions are met)

### [RECEIVE in `#{game_channel}` type `questions`]
- `team`: Integer (id of the team that is currently answering)
- `questions`: Array[Object]
  - `id`: String (id of the question)
  - `category`: String
  - `title`: String
  - `answerer`: Integer (id user who answers this question)
  - `possibilities`: Array[Object]
    - `id`: Integer
    - `text`: String
  - `difficulty`: Integer
  - `requiredAnswers`: Integer (number of answers that have to be provided)

### [REQUEST `#{game_channel}` -> `answer`]
- Arguments:
  - `auth_token`: String
  - `question`: String (id of the question)
- Response:
  - `ok` (Question successfully answered)
  - `error`
    - `reason: "not_enough_answers"`
  - `error`
    - `reason: "question_not_found"`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `round_ended`]
- `teams`: Array[Object]
  - `id`: Integer
  - `questions`: Array[Object]
    - `id`: Integer (id of the question)
    - `correct`: Boolean (whether or not this question was answered correctly)
    - `category`: String
    - `title`: String
    - `possibilities`: Array[Object]
      - `id`: Integer
      - `text`: String
    - `difficulty`: Integer
    - `requiredAnswers`: Integer (number of answers that have to be provided)
    - `answers`: Array[Object]
      - `id`: Integer
      - `text`: String
    - `givenAnswers`: Array[Object]
      - `id`: Integer
      - `text`: String

### [RECEIVE in `#{game_channel}` type `game_ended`]
- `teams`: Array[Object]
  - `points`: Integer
  - `members`: Array[String]

## Examples:
Please take a look at the documentation-in-source mentioned at the top.

Setup: First you set up the connection.
```javascript
import {Socket} from "phoenix";

let socket = new Socket("ws://localhost:4000/socket",
                        {params: {token: window.userToken}});
socket.connect();

let channel = socket.channel("main", {});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })
```

Then you might want to create a new game.
```javascript
channel.push('create_game').receive('ok', console.log);
```

A game is useless without joining in on it.
```javascript
channel.push('join_game', {username: name, game_id: game_id})
       .receive('ok', console.log).receive('err', console.error);
```

Join game channel: To receive updates you have to join the Phoenix channel of this game.
```javascript
let channel = socket.channel("game:" + game_id, {auth_token: auth_token});
channel.join()
       .receive('ok', console.log).receive('error', console.error);
```

Listen for updates: Now you can receive updates. E.g on it's status.
```javascript
channel.on('lobby_update', payload => {
  console.log('The game is ${payload.startable ? "" : "not"} startable.');
});

```
