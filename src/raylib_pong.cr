require "raylib-cr"

# A game involving two paddles and one ball where the goal is to get the ball 
# past the opponents paddle. 
module RaylibPong
  VERSION = "0.1alpha"

  # A player controlled paddle.
  class Paddle
    # Describes which player owns which paddle
    enum Player
      One
      Two
    end

    # Describes what way the paddle is moving
    enum Direction
      Up   = -1
      Down =  1
    end

    # How fast the paddle can move
    SPEED  = 0.75
    # The relative width of the paddle
    WIDTH  = 0.01
    # The relative height of the paddle
    HEIGHT =  0.1
    # How relative width the paddle should be from the edge of the screen
    MARGIN =  0.1

    # The relative location of the paddle.
    property position = Raylib::Vector2.new

    # What player owns this paddle.
    getter owner : Player

    def initialize(@owner)
      @position.x = @owner == Player::One ? MARGIN : 1.0 - MARGIN
      @position.y = 0.5 - HEIGHT/2
    end

    # The relative bounding box of the paddle.
    def bounds
      Raylib::Rectangle.new(
        x: @position.x,
        y: @position.y,
        width: WIDTH,
        height: HEIGHT
      )
    end

    # The absolute bounding box of the paddle on the screen.
    def abs_bounds
      Raylib::Rectangle.new(
        x: @position.x * Raylib.get_screen_width,
        y: @position.y * Raylib.get_screen_height,
        width: WIDTH * Raylib.get_screen_width,
        height: HEIGHT * Raylib.get_screen_height
      )
    end

    # Move the paddle in a direction.
    def move(d : Direction)
      if (@position.y >= 0) || (@position.y <= 1.0 - HEIGHT)
        @position.y += SPEED * d.value * Raylib.get_frame_time
      end
    end

    # Update the paddle.
    def update
      if @owner == Player::One
        move Direction::Up if Raylib.key_down?(Raylib::KeyboardKey::W)
        move Direction::Down if Raylib.key_down?(Raylib::KeyboardKey::S)
      else
        move Direction::Up if Raylib.key_down?(Raylib::KeyboardKey::Up)
        move Direction::Down if Raylib.key_down?(Raylib::KeyboardKey::Down)
      end

      wall_hit_check
    end

    # Checks if the paddle has hit a wall and confines it within the play area.
    def wall_hit_check
      if @position.y < 0
        @position.y = 0
      elsif @position.y + HEIGHT > 1.0
        @position.y = 1.0 - HEIGHT
      end
    end

    # Draws the paddle on the screen.
    def draw
      Raylib.draw_rectangle_rec(abs_bounds, Raylib::GREEN)
    end
  end

  # Holds information at a class level for the ball.
  module Ball
    # The relative radius of the ball.
    RADIUS                     = 0.005

    # The relative speed of the ball.
    SPEED                      =   0.2

    # How much more should the speed coefficient increase when the ball his hit by a paddle.
    SPEED_COEFFICIENT_INCREASE =   0.1

    # Where the relative location of the ball.
    class_property position : Raylib::Vector2 = Raylib::Vector2.new(x: 0.5, y: 0.5)
    # The relative velocity of the ball.
    class_property velocity : Raylib::Vector2 = Raylib::Vector2.new(x: -SPEED, y: 0)
    # The current speed_coefficient, whcih is increased every time the ball is hit by a paddle.
    class_getter speed_coefficient = 1.0

    # Events

    # The `proc` is run every time player1 scores.
    class_property on_player1_score : Proc(Nil) = ->{}
    # The `proc` is run every time player2 scores.
    class_property on_player2_score : Proc(Nil) = ->{}

    # This is run when a paddle makes contact with the ball.
    def self.on_hit_paddle(paddle : Paddle)
      # THe center point of the paddle
      paddle_point = Raylib::Vector2.new(
        x: (paddle.position.x + Paddle::WIDTH/2),
        y: (paddle.position.y + Paddle::HEIGHT/2)
      )

      increase_speed

      # Calculate the direction and set the speed to it.
      @@velocity = (@@position - paddle_point).normalize * SPEED * @@speed_coefficient
    end

    # Reset the ball back to the center.
    def self.reset
      @@position = Raylib::Vector2.new(x: 0.5, y: 0.5)
      @@speed_coefficient = 1.0
    end

    # Check if the ball has hit a wall, if so reverse it.
    def self.wall_hit_check
      if @@position.y < 0
        @@position.y = 0
        @@velocity.y *= -1
      elsif @@position.y > 1.0
        @@position.y = 1.0
        @@velocity.y *= -1
      end
    end

    # Increases the speed of the ball.
    def self.increase_speed
      @@speed_coefficient += SPEED_COEFFICIENT_INCREASE
    end

    # Update the ball.
    def self.update
      @@position = @@position + (@@velocity * Raylib.get_frame_time) 
      wall_hit_check

      if Ball.position.x < 0
        on_player2_score.call
        @@velcity = Raylib::Vector2.new(x: -SPEED)
        Ball.reset
      elsif Ball.position.x > 1.0
        on_player1_score.call
        @@velcity = Raylib::Vector2.new(x: SPEED)
        Ball.reset
      end
    end

    # Draw the ball.
    def self.draw
      abs_position = @@position * Raylib::Vector2.new(x: Raylib.get_screen_width, y: Raylib.get_screen_height)
      Raylib.draw_circle(abs_position.x, abs_position.y, Ball::RADIUS * Raylib.get_screen_width, Raylib::GREEN)
    end
  end

  # Pauses the game.
  class_getter pause = false
  # Player 1 paddle.
  class_getter paddle1 = Paddle.new Paddle::Player::One
  # Player 2~ paddle.
  class_getter paddle2 = Paddle.new Paddle::Player::Two

  # Player 1's score.
  class_getter player1_score = 0
  # Player 2's score.
  class_getter player2_score = 0

  # Sets up the player score procs in ball.
  def self.setup
    Ball.on_player1_score = -> {@@player1_score += 1}
    Ball.on_player2_score = -> {@@player2_score += 1}
  end

  # Has the ball been hit by a paddle?
  def self.ball_hit_paddle?(paddle)
    ((Ball.velocity.x < 0 && paddle.owner == Paddle::Player::One) ||
      (Ball.velocity.x > 0 && paddle.owner == Paddle::Player::Two)) &&
      Raylib.check_collision_point_rec?(
        Ball.position,
        paddle.bounds
      )
  end

  # Updates the collision between paddles and ball.
  def self.update_collision
    if ball_hit_paddle?(paddle1)
      Ball.on_hit_paddle(paddle1)
    elsif ball_hit_paddle?(paddle2)
      Ball.on_hit_paddle(paddle2)
    end
  end

  # Updates the game.
  def self.update
    unless pause
      update_collision
      Ball.update
      @@paddle1.update
      @@paddle2.update
    end

    @@pause = !@@pause if Raylib.key_pressed?(Raylib::KeyboardKey::Space)
  end

  # Draws the game.
  def self.draw
    Raylib.begin_drawing
    Raylib.clear_background Raylib::WHITE

    # TODO: FIX SCORE TEXT TO RELATIVE NOT ABSOLUTE
    Raylib.draw_text(@@player1_score.to_s, 20, 20, 40, Raylib::BLACK)
    Raylib.draw_text(@@player2_score.to_s, Raylib.get_screen_width - 40, 20, 40, Raylib::BLACK)

    Ball.draw

    @@paddle1.draw
    @@paddle2.draw

    Raylib.draw_text("PAUSED", Raylib.get_screen_width/2 - 160, Raylib.get_screen_height/2 - 60, 80, Raylib::BLACK) if pause
    Raylib.end_drawing
  end

  # Runs the game.
  def self.run
    setup

    Raylib.init_window(800, 500, "Pong")
    Raylib.set_window_state(Raylib::ConfigFlags::WindowResizable)

    until Raylib.close_window?
      update
      draw
    end

    Raylib.close_window
  end
end

# Main (start of the program)
RaylibPong.run
