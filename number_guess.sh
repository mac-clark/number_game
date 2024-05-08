#!/bin/bash

# Set up the connection string to PostgreSQL
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Function to get the user's username and check against the database
get_username() {
  echo "Enter your username:"
  read username
  result=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$username'")
  
  if [[ -z $result ]]; then
    # User is new
    echo "Welcome, $username! It looks like this is your first time here."
    $($PSQL "INSERT INTO users (username) VALUES ('$username')")
  else
    # User exists, parse details
    IFS='|' read -ra user_data <<< "$result"
    games_played="${user_data[1]}"
    best_game="${user_data[2]}"
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  fi
}

# Function to play the guessing game
play_game() {
  secret_number=$(( RANDOM % 1000 + 1 ))
  guess=0
  number_of_guesses=0
  echo "Guess the secret number between 1 and 1000:"
  while [ $guess -ne $secret_number ]; do
    read guess
    if ! [[ $guess =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
    elif [ $guess -lt $secret_number ]; then
      echo "It's higher than that, guess again:"
    elif [ $guess -gt $secret_number ]; then
      echo "It's lower than that, guess again:"
    fi
    ((number_of_guesses++))
  done
  echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
  # Update database with results
  update_stats $number_of_guesses
}

# Function to update user statistics in the database
update_stats() {
  local guesses=$1
  $($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username = '$username'")
  current_best=$($PSQL "SELECT best_game FROM users WHERE username = '$username'")
  if [[ $current_best -eq 0 || $guesses -lt $current_best ]]; then
    $($PSQL "UPDATE users SET best_game = $guesses WHERE username = '$username'")
  fi
}

# Main script execution
get_username
play_game
