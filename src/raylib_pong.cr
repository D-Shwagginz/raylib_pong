require "raylib-cr"
screen_width = 2048
screen_height = 1024

# Speed of the ball
ball_speed = 6_f32/4

# Speed of the left paddle
paddle1_speed = 5.4_f32/4

# Speed of the right paddle
paddle2_speed = 5.4_f32/4

Raylib.init_window(screen_width, screen_height, "Pong")

class Paddle
  property paddle
  property score : Int32
  getter paddle_speed : Float32
  getter paddle_num : Int32

  def initialize(@paddle_speed, @paddle_num)
    @score = 0
    @paddle = Raylib::Rectangle.new
    @paddle.width = 10
    @paddle.height = 140
    @paddle.x = @paddle_num == 1 ? 60 : Raylib.get_screen_width - 60
    @paddle.y = Raylib.get_screen_height/2 - @paddle.height/2
  end

  def move(direction : Int32)
    if @paddle.y >= 0 && direction == -1 || @paddle.y <= Raylib.get_screen_height - @paddle.height && direction == 1
      @paddle.y += @paddle_speed * direction
    end
  end
end

class Ball
  @@move_direction_x : Float32
  @@move_direction_x = Random.rand(1) == 0 ? -1.to_f32 : 1.to_f32
  property can_move : Bool
  property ball
  property move_speed_y : Float32
  getter ball_speed : Float32

  def initialize(@ball_speed)
    @can_move = false
    @move_speed_y = 0
    @ball = Raylib::Rectangle.new
    @ball.width, @ball.height = 20, 20
    @ball.x = Raylib.get_screen_width/2 - @ball.width/2
    @ball.y = Raylib.get_screen_height/2 - @ball.height/2
  end

  def move
    if @can_move
      @ball.x = @ball.x + @ball_speed*@@move_direction_x
      @move_speed_y *= @ball.y <= 0 || @ball.y >= Raylib.get_screen_height - @ball.height ? -1 : 1
      @ball.y = @ball.y + @ball_speed*@move_speed_y/60
    end
  end

  def reverse_x
    @@move_direction_x *= -1
  end

  def reset
    initialize(@ball_speed)
  end
end

ball = Ball.new ball_speed
ball.can_move = true
paddle1 = Paddle.new paddle1_speed, 1
paddle2 = Paddle.new paddle2_speed, 2

pause = false

until Raylib.close_window?
  Raylib.begin_drawing
  Raylib.clear_background Raylib::WHITE
  Raylib.draw_text(paddle2.score.to_s, 20, 20, 40, Raylib::BLACK)
  Raylib.draw_text(paddle1.score.to_s, Raylib.get_screen_width - 40, 20, 40, Raylib::BLACK)

  Raylib.draw_rectangle_rec(ball.ball, Raylib::GREEN)

  if ball.ball.x <= 0
    paddle1.score += 1
    ball.reset
    spawn do
      sleep 2.seconds
      ball.can_move = true
    end
  elsif ball.ball.x >= Raylib.get_screen_width
    paddle2.score += 1
    ball.reset
    spawn do
      sleep 2.seconds
      ball.can_move = true
    end
  end
  Fiber.yield

  if Raylib.check_collision_recs?(ball.ball, paddle1.paddle)
    ball.reverse_x
    ball.move_speed_y = ball.ball.y - paddle1.paddle.y - 30
  elsif Raylib.check_collision_recs?(ball.ball, paddle2.paddle)
    ball.reverse_x
    ball.move_speed_y = ball.ball.y - paddle2.paddle.y - 30
  end

  Raylib.draw_rectangle_rec(paddle1.paddle, Raylib::GREEN)
  Raylib.draw_rectangle_rec(paddle2.paddle, Raylib::GREEN)

  unless pause
    ball.move
    paddle1.move(-1) if Raylib.key_down?(Raylib::KeyboardKey::W)
    paddle1.move(1) if Raylib.key_down?(Raylib::KeyboardKey::S)
    paddle2.move(-1) if Raylib.key_down?(Raylib::KeyboardKey::Up)
    paddle2.move(1) if Raylib.key_down?(Raylib::KeyboardKey::Down)
  end

  pause = !pause if Raylib.key_pressed?(Raylib::KeyboardKey::Space)
  Raylib.draw_text("PAUSED", Raylib.get_screen_width/2 - 160, Raylib.get_screen_height/2 - 60, 80, Raylib::BLACK) if pause
  Raylib.end_drawing
end

Raylib.close_window
