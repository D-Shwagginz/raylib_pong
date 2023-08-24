require "raylib-cr"

# TODO: Pause menu resume reset exit
# TODO: Create virtual camera

# A game involving two paddles and one ball where the goal is to get the ball
# past the opponents paddle.
module RaylibPong
  VERSION = "0.2alpha"
  # Screen Resolution
  RESX = 800
  RESY = 450
  # Virtual Screen Resolution
  VRESX = 160
  VRESY =  90

  # Initializes the cameras
  def self.camera_init
    virtual_width_ratio = RESX.to_f/VRESX.to_f
    virtual_height_ratio = RESY.to_f/VRESY.to_f

    world_space_camera = Raylib::Camera2D.new
    world_space_camera.zoom = 1.0_f32

    screen_space_camera = Raylib::Camera2D.new
    screen_space_camera.zoom = 1.0_f32

    target = Raylib.load_render_texture(VRESX, VRESY)

    source_rec = Raylib::Rectangle.new x: 0.0_f32, y: 0.0_f32, width: target.texture.width.to_f*virtual_width_ratio/5, height: -target.texture.height.to_f*virtual_height_ratio/5
    dest_rec = Raylib::Rectangle.new x: 0, y: 0, width: Raylib.get_screen_width, height: Raylib.get_screen_height

    origin = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
    rotation = 0.0_f32
    camera_x = 0.0_f32
    camera_y = 0.0_f32
  end

  # Starts the world space camera
  def self.camera_world_start
    Raylib.begin_texture_mode(target)
    Raylib.clear_background(Raylib::RAYWHITE)
    Raylib.begin_mode_2d(world_space_camera)
  end

  # Ends the world space camera
  def self.camera_world_end
    Raylib.end_mode_2d
    Raylib.end_texture_mode
  end

  # Runs the screen space camera
  def self.camera_screen
    Raylib.begin_drawing
    Raylib.clear_background(Raylib::RED)
    Raylib.begin_mode_2d(screen_space_camera)
    Raylib.draw_texture_pro(target.texture, source_rec, dest_rec, origin, 0.0_f32, Raylib::WHITE)
    Raylib.end_mode_2d
    Raylib.end_drawing
  end

  # A ui button that can be clicked with the mouse
  class Button
    # Describes the current state of the button
    enum State
      Pressed
      Hovered
      Released
      None
    end
    # Describes how the button is centered horizontally
    enum CenteringX
      Left
      Center
      Right
    end
    # Describes how the button is centered vertically
    enum CenteringY
      Top
      Middle
      Bottom
    end

    # The relative width of the button
    WIDTH = 0.2
    # The relative height of the button
    HEIGHT = 0.1

    # Color of the button when pressed
    PRESSED_COLOR = Raylib::Color.new r: 200, g: 200, b: 200, a: 200
    # Color of the button when hovered
    HOVERED_COLOR = Raylib::Color.new r: 190, g: 190, b: 190, a: 200
    # Color of the button when released
    RELEASED_COLOR = Raylib::Color.new r: 210, g: 210, b: 210, a: 200

    # The relative location of the button
    property position = Raylib::Vector2.new
    # The current state of the button
    property state : State = State::None

    # The absolute x of the button
    getter abs_x : Float64
    # The absolute y of the button
    getter abs_y : Float64
    # The relative x of the button
    getter rel_x : Float64
    # The relative y of the button
    getter rel_y : Float64
    # The margin from the button to the edge of the screen
    getter margin : Float64
    # How the button is centered horizontally relative to the position
    getter centering_x : CenteringX
    # How the button is centered vertically relative to the position
    getter centering_y : CenteringY
    # The text the button displays
    getter text : String

    # Events for button down, hover, and up
    property on_button_down : Proc(Nil) = ->{}
    property on_button_hover : Proc(Nil) = ->{}
    property on_button_up : Proc(Nil) = ->{}

    def initialize(@abs_x = 0, @abs_y = 0, @rel_x = 0, @rel_y = 0, @margin = 0.1, @centering_x = CenteringX::Left, @centering_y = CenteringY::Top, @text = "Text", @on_button_down = ->{}, @on_button_hover = ->{}, @on_button_up = ->{})
      # Sets abs_x and rel_x based off of the centeringX
      case @centering_x
      when CenteringX::Center
        @abs_x -= WIDTH*RESX/2
        @rel_x -= WIDTH/2
      when CenteringX::Right
        @abs_x -= WIDTH*RESX
        @rel_x -= WIDTH
      end

      # Sets abs_y and rel_y based off of the centeringY
      case @centering_y
      when CenteringY::Top
        @abs_y += HEIGHT*RESY
        @rel_y += HEIGHT
      when CenteringY::Middle
        @abs_y += HEIGHT*RESY/2
        @rel_y += HEIGHT/2
      end

      @position.x = @abs_x/RESX + rel_x + @margin
      @position.y = @abs_y/RESY + rel_y + @margin
    end

    # Checks if the button is pressed
    def down_check
      if Raylib.mouse_button_down?(Raylib::MouseButton::Left) &&
         (Raylib.get_mouse_x >= @position.x*Raylib.get_screen_width) &&
         (Raylib.get_mouse_x <= (@position.x + WIDTH)*Raylib.get_screen_width) &&
         (Raylib.get_mouse_y >= @position.y*Raylib.get_screen_height) &&
         (Raylib.get_mouse_y <= (@position.y + HEIGHT)*Raylib.get_screen_height) &&
         (@state != State::Pressed)
        @state = State::Pressed
        on_button_down.call
      end
    end

    # Checks if the button is released
    def up_check
      if Raylib.mouse_button_up?(Raylib::MouseButton::Left) &&
         @state == State::Pressed
        @state = State::Released
        on_button_up.call
      end
    end

    # Checks if the button is hovered
    def hover_check
      if Raylib.get_mouse_x >= @position.x*Raylib.get_screen_width &&
         (Raylib.get_mouse_x <= (@position.x + WIDTH)*Raylib.get_screen_width) &&
         (Raylib.get_mouse_y >= @position.y*Raylib.get_screen_height) &&
         (Raylib.get_mouse_y <= (@position.y + HEIGHT)*Raylib.get_screen_height)
        if @state != State::Hovered && @state != State::Pressed
          @state = State::Hovered
          on_button_hover.call
        end
      elsif @state != State::Pressed && @state != State::None
        @state = State::None
      end
    end

    # The relative bounding box of the button
    def bounds
      Raylib::Rectangle.new(
        x: @position.x,
        y: @position.y,
        width: WIDTH,
        height: HEIGHT
      )
    end

    # The absolute bounding box of the button on the screen
    def abs_bounds
      Raylib::Rectangle.new(
        x: @position.x * Raylib.get_screen_width,
        y: @position.y * Raylib.get_screen_height,
        width: WIDTH * Raylib.get_screen_width,
        height: HEIGHT * Raylib.get_screen_height
      )
    end

    # The text to display on the button
    def text_image
      textimg = Raylib.image_text(@text, 40, Raylib::RED)
      texttex = Raylib.load_texture_from_image(textimg)
      texttex.width = WIDTH * Raylib.get_screen_width - 20
      texttex.height = HEIGHT * Raylib.get_screen_height - 20
      texttex
    end

    # Update the button
    def update
      down_check
      up_check
      hover_check
    end

    # Draws the button on the screen
    def draw
      rec_color = case state
                  when State::Pressed
                    PRESSED_COLOR
                  when State::Hovered
                    HOVERED_COLOR
                  else
                    RELEASED_COLOR
                  end
      Raylib.draw_rectangle_rec(abs_bounds, rec_color)
      Raylib.draw_texture(text_image, @position.x*Raylib.get_screen_width + 10, @position.y*Raylib.get_screen_height + 10, Raylib::RED)
    end
  end

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
    SPEED = 0.75
    # The relative width of the paddle
    WIDTH = 0.01
    # The relative height of the paddle
    HEIGHT = 0.1
    # How relative width the paddle should be from the edge of the screen
    MARGIN = 0.1

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
    RADIUS = 0.005

    # The relative speed of the ball.
    SPEED = 0.4 * (Random.rand(2) == 0 ? -1 : 1)

    # How much more should the speed coefficient increase when the ball his hit by a paddle.
    SPEED_COEFFICIENT_INCREASE = 0.1

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
    def self.reset(rand_x = 0)
      @@position = Raylib::Vector2.new(x: 0.5, y: 0.5)
      @@speed_coefficient = 1.0
      @@velocity.y = 0
      if rand_x == 1
        @@velocity.x *= (Random.rand(2) == 0 ? -1 : 1)
      end
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
      #Raylib.draw_circle(abs_position.x, abs_position.y, Ball::RADIUS * Raylib.get_screen_width, Raylib::GREEN)

      # The height of the ball rec
      height = Ball::RADIUS * Raylib.get_screen_height
      # The width of the ball rec
      width = Ball::RADIUS * Raylib.get_screen_width

      Raylib.draw_rectangle(abs_position.x - width, abs_position.y - height, width*2, height*3, Raylib::BLACK)
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

  # Pause menu buttons
  # Unpause button
  class_getter button_unpause = Button.new(rel_x: 0.5, abs_y: 80, margin: 0.0, centering_x: Button::CenteringX::Center, text: "Unpause", on_button_up: ->{ @@pause = !@@pause })
  # Reset button
  class_getter button_reset = Button.new(rel_x: 0.5, abs_y: 140, margin: 0.0, centering_x: Button::CenteringX::Center, text: "Reset", on_button_up: ->{ restart })
  # Exit button
  class_getter button_exit = Button.new(rel_x: 0.5, abs_y: 200, margin: 0.0, centering_x: Button::CenteringX::Center, text: "Exit", on_button_up: ->{ Raylib.close_window })

  def self.restart
    @@pause = false
    Ball.reset(rand_x: 1)
    paddle1.initialize
    paddle2.initialize
  end

  # Sets up the player score procs in ball.
  def self.setup
    Ball.on_player1_score = ->{ @@player1_score += 1 }
    Ball.on_player2_score = ->{ @@player2_score += 1 }
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
    @@button_unpause.update if @@pause == true
    @@button_reset.update if @@pause == true
    @@button_exit.update if @@pause == true

    @@pause = !@@pause if Raylib.key_pressed?(Raylib::KeyboardKey::Space)
  end

  # Draws the game.
  def self.draw
    Raylib.begin_drawing
    Raylib.clear_background(Raylib::WHITE)

    Raylib.draw_text(@@player1_score.to_s, 0.02*Raylib.get_screen_width, 0.02*Raylib.get_screen_height, Raylib.get_screen_height/10, Raylib::BLACK)
    Raylib.draw_text(@@player2_score.to_s, 0.98*Raylib.get_screen_width - Raylib.get_screen_height/20, 0.02*Raylib.get_screen_height, Raylib.get_screen_height/10, Raylib::BLACK)

    Ball.draw

    @@paddle1.draw
    @@paddle2.draw

    Raylib.draw_text("PAUSED", Raylib.get_screen_width/2 - 160, 40, 80, Raylib::BLACK) if pause

    @@button_unpause.draw if @@pause == true
    @@button_reset.draw if @@pause == true
    @@button_exit.draw if @@pause == true

    Raylib.end_drawing
  end

  # Runs the game.
  def self.run
    setup

    Raylib.init_window(RESX, RESY, "Pong")
    Raylib.set_window_state(Raylib::ConfigFlags::WindowResizable)
    # target : Raylib::RenderTexture2D
    # camera_init

    until Raylib.close_window?
      # camera_init if Raylib.window_resized?
      update
      # camera_world_start
      draw
      # camera_world_end
      # camera_screen
    end
    # Raylib.unload_render_texture(target)
    Raylib.close_window
  end
end

# Main (start of the program)
RaylibPong.run
