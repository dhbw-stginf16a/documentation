# Technologies
- Websocket
- JWT-Auth

# Actions

## Setup game
- create a new game
  - PARAMS
    - host nickname
    - team size
  - RETURN
    - game id
    - auth token
    - channel id
- join
  - PARAMS
    - game id
    - nick name
  - RETURNS
    - auth token
    - channel id (one channel per game)
    - team count

## Channel
- to server
  - client status
    - ready: true/false
    - team id
- to client
  - users list
    - nickmane
    - ready state
    - team id
  - game started message

# Main screen
- cooler loading screen
- first round
  - no betting
  - randomly select team captain
- new round
  - setup
     -> team captain to client
     -> 3 categories
     -> random team leader assigned
    <-> team leader assigns importance and answerer to each category
    <-> user sets their readiness
     -> see who answers each question of the other teams
    <-> team leader sets bets against one category of other teams
        users with more than 3 points,  bet 1 or 2 points
     -> show bets against own team
  - questions
    - for each team
       -> questions to answerer and everyone of the opposing team
          only answerable by designated answerer
      <-  answer
      ->  correct answer or voting - after everyone answered
      ->  points
  - after round
     -> (special card)
    -

# Extension ideas
- action cards
- lobby
- game names
- change number of teams

# Tasks
- Erik, Jan-Robin design
