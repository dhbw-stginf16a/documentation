# BrettProjekt Channel-Based WebSocket Documentation

## Basic Setup
The BrettProjekt Backend is running an instance of the [Phoenix Web Framework](http://phoenixframework.org). Therefore we are using Phoenix channels on top of WebSockets for request/response and pub/sub based communication.

To get started, include the Phoenix-Channels WebSocket client and read it's [documentation in source-code](https://github.com/mspanc/phoenix_socket/blob/master/dist/socket.js).

## Actions

Status of completion

- [x] [[REQUEST `main` -> `create_game`]: Create a new game](#request-main---create_game-create-a-new-game)
- [x] [[REQUEST `main` -> `join_game`]: Join a game](#request-main---join_game-join-a-game)
- [x] [[JOIN `#{game_channel}`]: Join the game-channel](#join-game_channel-join-the-game-channel)
- [x] [[RECEIVE in `#{game_channel}` type `lobby_update`]](#receive-in-game_channel-type-lobby_update)
- [x] [[REQUEST `#{game_channel}` -> `set_team`]: sets the user-team](#request-game_channel---set_team-sets-the-user-team)
- [x] [[REQUEST `#{game_channel}` -> `ready`]: Player is ready](#request-game_channel---ready-player-is-ready)
- [ ] [[REQUEST `#{game_channel}` -> `start_game`]: Admin starts the game](#request-game_channel---start_game-admin-starts-the-game)
- [ ] [[RECEIVE in `#{game_channel}` type `round_preparation`]](#receive-in-game_channel-type-round_preparation)
- [ ] [[REQUEST `#{game_channel}` -> `set_categories`]: set the player categories](#request-game_channel---set_categories-set-the-player-categories)
- [ ] [[RECEIVE in `#{game_channel}` type `round_started`]](#receive-in-game_channel-type-round_started)
- [ ] [[RECEIVE in `#{game_channel}` type `questions`]](#receive-in-game_channel-type-questions)
- [ ] [[REQUEST `#{game_channel}` -> `answer`]](#request-game_channel---answer)
- [ ] [[RECEIVE in `#{game_channel}` type `round_ended`]](#receive-in-game_channel-type-round_ended)
- [ ] [[RECEIVE in `#{game_channel}` type `game_ended`]](#receive-in-game_channel-type-game_ended)

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
  - `id`: Integer (Player-Id)
  - `name`: String (Player-Name)
  - `team`: Integer (id of the team)
  - `ready`: Boolean

### [REQUEST `#{game_channel}` -> `set_team`]: Sets the user-team
- Arguments:
  - `auth_token`: String
  - `team`: Integer (id of the team)
- Response:
  - `ok` (A `lobby_update` message will be broadcast reflecting the team-change)
  - `error`
    - `reason: invalid_team_id`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [REQUEST `#{game_channel}` -> `ready`]: Player is ready
- Arguments:
  - `auth_token`: String
  - `ready`: boolean
- Response:
  - `ok` (Update of `lobby_update` will be broadcast)
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`


### [REQUEST `#{game_channel}` -> `start_game`]: Admin starts the game
- Arguments:
  - `auth_token`: String
- Response:
  - `ok` (Game was started)
  - `error`
    - `reason: game_not_startable`
  - `error` (Only the admin can start the game)
    - `reason: missing_permission`
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `round_preparation`]
- `categories`: Array[String]  # TODO
- `teams`: Object[`team_id`: Object]
  - `name`: String (Player name)
  - `categories`: Object[`category_id`: String]  # TODO maybe add difficulty
  - `points`: Integer (Points carried over from previous round)

### [REQUEST `#{game_channel}` -> `set_categories`]: Set the player categories
- Arguments:
  - `auth_token`: String
  - `categories`: Object[category_id: difficulty]
- Response:
  - `ok`
    (Update of `round_preparation` will be broadcast)
    (First `questions` broadcast will be issued when every category has been assigned)
  - `error`
    - `reason: categories_unavailable` (tried setting a category that is not available in the game)
  - `error`
    - `reason: categories_empty`
  - `error` (Another player already chose one of the categories)
    - `reason: category_taken`  # TODO send which category caused the problem
  - `error`
    - `reason: "auth_token_missing"`
  - `error` (The authentication-token is invalid or issued for another wrong game)
    - `reason: "auth_token_invalid"`

### [RECEIVE in `#{game_channel}` type `questions`]
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
  - `question`: (id of the question)
  - `answer`
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
- `teams`: Object[`team_id`: Object] (id of the team that is currently answering)
  - `players`: Object[`player_id`: Object]
    - `name`: String
    - `questions`: Array[Object]
      - `id`: Integer (id of the question)
      - `correct`: Boolean (whether or not this question was answered correctly)
      - `category`: String
      - `title`: String
      - `possibilities`: Array[Object]
        - `id`: Integer
        - `answer`
      - `difficulty`: Integer
      - `requiredAnswers`: Integer (number of answers that have to be provided)
      - `answers`: Array[Object]
        - `id`: Integer
        - `answer`
      - `givenAnswers`: Array[Object]
        - `id`: Integer
        - `answer`

### [RECEIVE in `#{game_channel}` type `game_ended`]
- `teams`: Array[Object]
  - `points`: Integer
  - `members`: Object[player_id: String]
    - `player_name`

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
