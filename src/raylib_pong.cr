require "raylib-cr"

module RaylibPong
  VERSION = "0.1alpha"

  class Paddle
    enum Player
      One
      Two
    end

    enum Direction
      Up   = -1
      Down =  1
    end

    SPEED  =  0.75
    WIDTH  = 0.01
    HEIGHT =  0.1
    MARGIN =  0.1

    property position = Raylib::Vector2.new

    getter owner : Player

    def initialize(@owner)
      @position.x = @owner == Player::One ? MARGIN : 1.0 - MARGIN
      @position.y = 0.5 - HEIGHT/2
    end

    def bounds
      Raylib::Rectangle.new(
        x: @position.x,
        y: @position.y,
        width: WIDTH,
        height: HEIGHT
      )
    end

    def texture
      Raylib::Rectangle.new(
        x: @position.x * Raylib.get_screen_width,
        y: @position.y * Raylib.get_screen_height,
        width: WIDTH * Raylib.get_screen_width,
        height: HEIGHT * Raylib.get_screen_height
      )
    end

    def move(d : Direction)
      if (@position.y >= 0) || (@position.y <= 1.0 - HEIGHT)
        @position.y += SPEED * d.value * Raylib.get_frame_time
      end
    end

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

    def wall_hit_check
      if @position.y < 0
        @position.y = 0
      elsif @position.y + HEIGHT > 1.0
        @position.y = 1.0 - HEIGHT
      end
    end

    def draw
      Raylib.draw_rectangle_rec(texture, Raylib::GREEN)
    end
  end

  module Ball
    RADIUS = 0.005
    SPEED  =  0.2
    SPEED_INCREASE = 0.1

    class_property position : Raylib::Vector2 = Raylib::Vector2.new(x: 0.5, y: 0.5)
    class_property velocity : Raylib::Vector2 = Raylib::Vector2.new(x: -SPEED, y: 0)
    class_getter speed_increase = 1.0

    def self.reset
      @@position = Raylib::Vector2.new(x: 0.5, y: 0.5)
      @@speed_increase = 1.0
    end

    def self.update
      @@position = @@position + (@@velocity * Raylib.get_frame_time) * @@speed_increase
      wall_hit_check
    end

    def self.wall_hit_check
      if @@position.y < 0
        @@position.y = 0
        @@velocity.y *= -1
      elsif @@position.y > 1.0
        @@position.y = 1.0
        @@velocity.y *= -1
      end
    end

    def self.increase_speed
      @@speed_increase += SPEED_INCREASE
    end

    def self.draw
      abs_position = @@position * Raylib::Vector2.new(x: Raylib.get_screen_width, y: Raylib.get_screen_height)
      Raylib.draw_circle(abs_position.x, abs_position.y, Ball::RADIUS * Raylib.get_screen_width, Raylib::GREEN)
    end
  end

  class_getter pause = false
  class_getter paddle1 = Paddle.new Paddle::Player::One
  class_getter paddle2 = Paddle.new Paddle::Player::Two

  class_getter player1_score = 0
  class_getter player2_score = 0

  def self.ball_hit_paddle?(paddle)
    ((Ball.velocity.x < 0 && paddle.owner == Paddle::Player::One) ||
    (Ball.velocity.x > 0 && paddle.owner == Paddle::Player::Two)) &&
    Raylib.check_collision_point_rec?(
      Ball.position,
      paddle.bounds
    )
  end

  def self.update_collision
    if ball_hit_paddle?(paddle1)
      paddle_point = Raylib::Vector2.new(
        x: (paddle1.position.x + Paddle::WIDTH/2),
        y: (paddle1.position.y + Paddle::HEIGHT/2)
      )
      Ball.increase_speed

      Ball.velocity = (Ball.position - paddle_point).normalize * Ball::SPEED
    elsif ball_hit_paddle?(paddle2)
      paddle_point = Raylib::Vector2.new(
        x: (paddle2.position.x + Paddle::WIDTH/2),
        y: (paddle2.position.y + Paddle::HEIGHT/2)
      )
      Ball.increase_speed

      Ball.velocity = (Ball.position - paddle_point).normalize * Ball::SPEED
    end

    if Ball.position.x < 0
      @@player2_score += 1
      Ball.reset
    elsif Ball.position.x > 1.0
      @@player1_score += 1
      Ball.reset
    end
  end

  def self.update
    unless pause
      update_collision
      Ball.update
      @@paddle1.update
      @@paddle2.update
    end

    @@pause = !@@pause if Raylib.key_pressed?(Raylib::KeyboardKey::Space)
  end

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

  def self.run
    player1_score = 0
    player2_score = 0

    Raylib.init_window(800, 500, "Pong")

    until Raylib.close_window?
      update
      draw
    end

    Raylib.close_window
  end
end

RaylibPong.run
